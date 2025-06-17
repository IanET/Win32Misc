using LibBaseTsd

include("../common/Win32.jl")
using .W32

include("../common/LibSkia.jl")
using .LibSkia

include("Layout.jl")

import Base.cconvert, .GC.@preserve

const GAP = -1
const IDC_IMAGE = 1
const IDC_OK = 2
const IDC_CANCEL = 3
const MIN_WIDTH = 200
const MIN_HEIGHT = 200

const BLUE_GRAY_BRUSH = CreateSolidBrush(RGB(0xD0, 0xD0, 0xE0))
const HINST::HINSTANCE = GetModuleHandleW(C_NULL)

cwstring(s) = cconvert(Cwstring, s)
tostring(v::AbstractArray{Cwchar_t}) = transcode(String, @view v[begin:findfirst(iszero, v)-1])
tolparam(s::String) = s |> cwstring |> pointer |> LPARAM
Base.Tuple(v::MemoryRef{UInt16}, len) = copyto!(zeros(eltype(v), len), v.mem) |> Tuple

_layout = GridLayout( 
    [   
        GAP     GAP         GAP         GAP         GAP    
        GAP     IDC_IMAGE   IDC_IMAGE   IDC_IMAGE   GAP
        GAP     GAP         GAP         GAP         GAP    
        GAP     GAP         IDC_OK      IDC_CANCEL  GAP 
        GAP     GAP         GAP         GAP         GAP    
    ], 
    [5, ★"1", 5, 30, 5],   # row heights
    [5, ★"1", 75, 75, 5])  # col widths

_dib::HBITMAP = C_NULL
_pbits::Ptr{Cvoid} = C_NULL

function onImageCreate(hwnd)::LRESULT
    # @info "onImageCreate" hwnd
    return 0
end

function onImageDestroy(hwnd)::LRESULT
    # @info "onImageDestroy" hwnd
    return 0
end

sk_color_set_argb(a, r, g, b) = ((UInt32(a) << 24) | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b))

function skiaDraw(w, h)
    info = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), _pbits, w * 4, C_NULL, C_NULL, C_NULL)
    canvas = sk_surface_get_canvas(surface)

    fill = sk_paint_new()
    sk_paint_set_color(fill, sk_color_set_argb(0xFF, 0xA0, 0xB0, 0xE0))
    sk_canvas_draw_paint(canvas, fill)

    sk_paint_set_color(fill, sk_color_set_argb(0xFF, 0xD0, 0x80, 0x80))
    rect = sk_rect_t(50, 50, w - 50, h - 50)
    sk_canvas_draw_rect(canvas, Ref(rect), fill)

    textpaint = sk_paint_new()
    sk_paint_set_color(textpaint, sk_color_set_argb(0xFF, 0x00, 0x00, 0x00))
    # sk_paint_set_antialias(textpaint, true)
    text = "Hello, World!"
    fontstyle = sk_fontstyle_new(SK_FONT_STYLE_NORMAL_WEIGHT, SK_FONT_STYLE_NORMAL_WIDTH, UPRIGHT_SK_FONT_STYLE_SLANT)
    typeface = sk_typeface_create_from_name("Arial", fontstyle)
    font = sk_font_new()
    sk_font_set_typeface(font, typeface)
    sk_font_set_size(font, 24.0)
    sk_canvas_draw_simple_text(canvas, pointer(text), sizeof(text), UTF8_SK_TEXT_ENCODING, 10.0, 35.0, font, textpaint)

    sk_paint_delete(fill)
    sk_surface_unref(surface)
end

function onImagePaint(hwnd)::LRESULT
    @info "onImagePaint" hwnd
    ps = PAINTSTRUCT() |> Ref
    hdc = BeginPaint(hwnd, ps)
    rcclient = RECT() |> Ref
    GetClientRect(hwnd, rcclient)
    skiaDraw(rcclient[].right - rcclient[].left, rcclient[].bottom - rcclient[].top) # draw the whole thing
    hdcmem = CreateCompatibleDC(hdc)
    hbmpold = SelectObject(hdcmem, _dib)
    BitBlt(hdc, ps[].rcPaint.left, ps[].rcPaint.top, ps[].rcPaint.right - ps[].rcPaint.left, ps[].rcPaint.bottom - ps[].rcPaint.top, hdcmem, ps[].rcPaint.left, ps[].rcPaint.top, SRCCOPY)
    SelectObject(hdcmem, hbmpold)
    DeleteDC(hdcmem)
    EndPaint(hwnd, ps)
    return 0
end

function onImageSize(hwnd, width, height)::LRESULT
    global _dib, _pbits
    @info "onImageSize" hwnd width height
    if width <= 0 || height <= 0; return 0 end
    bmih = BITMAPINFOHEADER(sizeof(BITMAPINFOHEADER), width, -1*height, 1, 32, BI_RGB, 0, 0, 0, 0, 0) |> Ref
    bmpinfo = BITMAPINFO(bmih[], (RGBQUAD(),)) |> Ref
    hdc = GetDC(hwnd)
    if _dib != C_NULL; DeleteObject(_dib) end
    pbits = Ptr{Cvoid}(0) |> Ref
    _dib = CreateDIBSection(hdc, bmpinfo, DIB_RGB_COLORS, pbits, C_NULL, 0)
    @assert _dib != C_NULL
    @assert pbits[] != C_NULL
    _pbits = pbits[]
    ReleaseDC(hwnd, hdc)
    return 0
end

function imageWndProc(hwnd::HWND, umsg::UINT, wparam::WPARAM, lparam::LPARAM)::LRESULT
    try
        if umsg == WM_CREATE
            return onImageCreate(hwnd)
        elseif umsg == WM_DESTROY
            return onImageDestroy(hwnd)
        elseif umsg == WM_PAINT
            return onImagePaint(hwnd)
        elseif umsg == WM_SIZE
            return onImageSize(hwnd, LOWORD(lparam), HIWORD(lparam))
        end
        return DefWindowProcW(hwnd, umsg, wparam, lparam)
    catch exc
        @error exc
        @info "Exception" catch_backtrace() |> stacktrace
    end

    return 0
end

function createImageWindow(parent, id, x, y, w, h)
    classname = L"ImageClass"
    wc = WNDCLASSW(
        CS_HREDRAW | CS_VREDRAW, 
        @cfunction(imageWndProc, LRESULT, (HWND, UINT, WPARAM, LPARAM)), 
        0, 0, 
        HINST, 
        LoadIconW(HINSTANCE(0), IDI_INFORMATION), 
        LoadCursorW(HINSTANCE(0), IDC_ARROW), 
        HBRUSH(COLOR_WINDOW+1), 
        C_NULL, 
        pointer(classname))
    @preserve classname RegisterClassW(Ref(wc))
    hwnd = CreateWindowExW(DWORD(0), classname, L"Image", WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS, x, y, w, h, parent, HMENU(id), HINST, LPVOID(0))
    return hwnd
end

function onCreate(hwnd)
    hwndImage = createImageWindow(hwnd, IDC_IMAGE, 0, 0, 100, 100)
    lf = W32.LOGFONTW(-16, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 0, 0, Tuple(L"Segoe UI", 32))
    hfont = W32.CreateFontIndirectW(Ref(lf))
    ok = CreateWindowExW(0, L"BUTTON", L"OK", WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | WS_TABSTOP, 10, 10, 100, 100, hwnd, HMENU(IDC_OK), HINST, C_NULL)
    SendMessageW(ok, WM_SETFONT, WPARAM(hfont), LPARAM(TRUE))
    cancel = CreateWindowExW(0, L"BUTTON", L"Cancel", WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | WS_TABSTOP, 20, 20, 100, 100, hwnd, HMENU(IDC_CANCEL), HINST, C_NULL)
    SendMessageW(cancel, WM_SETFONT, WPARAM(hfont), LPARAM(TRUE))
    return 0
end

function onSize(hwnd, wparam, width, height)
    @info "onSize" hwnd wparam width height
    if wparam == SIZE_MINIMIZED; return 0 end
    if width <= 0 || height <= 0; return 0 end
    layout(hwnd, _layout)
    return 0
end

function onDestroy(hwnd)
    PostQuitMessage(0)
    return 0
end

function onClose(hwnd)
    DestroyWindow(hwnd)
    return 0
end

function onCommand(hwnd, id, code)
    if id == IDC_OK
        @info "OK"
    elseif id == IDC_CANCEL
        @info "Cancel"
    end
    return 0
end

# Modify a c-struct in place
Base.fieldoffset(T::Type, field::Symbol) = fieldoffset(T, Base.fieldindex(T, field))
unsafe_modify_cstruct(p::Ptr{T}, field::Symbol, v::V) where {T, V} = unsafe_store!(Ptr{V}(p + fieldoffset(T, field)), v)

function onGetMinMaxInfo(hwnd, pmmi::Ptr{MINMAXINFO})
    unsafe_modify_cstruct(pmmi, :ptMinTrackSize, POINT(MIN_WIDTH, MIN_HEIGHT))
    # @info unsafe_load(pmmi)
    return 0
end

function appWndProc(hwnd::HWND, umsg::UINT, wparam::WPARAM, lparam::LPARAM)::LRESULT
    try
        if umsg == WM_CREATE
            return onCreate(hwnd)
        elseif umsg == WM_CLOSE
            return onClose(hwnd)
        elseif umsg == WM_DESTROY
            return onDestroy(hwnd)
        elseif umsg == WM_SIZE
            return onSize(hwnd, wparam, LOWORD(lparam), HIWORD(lparam))
        elseif umsg == WM_COMMAND
            return onCommand(hwnd, LOWORD(wparam), HIWORD(wparam))
        elseif umsg == WM_GETMINMAXINFO
            return onGetMinMaxInfo(hwnd, Ptr{MINMAXINFO}(lparam))
        end
        return DefWindowProcW(hwnd, umsg, wparam, lparam)
    catch exc
        @error exc
        @info "Exception" catch_backtrace() |> stacktrace
    end

    return 0
end

function createMainWindow()
    classname = L"LayoutTestClass"
    wc = WNDCLASSW(
        CS_HREDRAW | CS_VREDRAW, 
        @cfunction(appWndProc, LRESULT, (HWND, UINT, WPARAM, LPARAM)), 
        0, 0, 
        HINST, 
        LoadIconW(HINSTANCE(0), IDI_INFORMATION), 
        LoadCursorW(HINSTANCE(0), IDC_ARROW), 
        HBRUSH(COLOR_WINDOW+1), 
        C_NULL, 
        pointer(classname))
    @preserve classname RegisterClassW(Ref(wc))
    hwnd = CreateWindowExW(DWORD(0), classname, L"Skia Test", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 512, 512, HWND(0), HMENU(0), HINST, LPVOID(0))
    return hwnd
end

function main()
    @info "UI Begin"

    hwnd = createMainWindow()
    ShowWindow(hwnd, SW_SHOWNORMAL)
    size_t(i::Int64) = reinterpret(UInt64, i) |> SIZE_T
    SetProcessWorkingSetSize(GetCurrentProcess(), size_t(-1), size_t(-1))

    MsgLoop() do msg
        TranslateMessage(msg)
        DispatchMessageW(msg)
    end

    @info "UI End"
end

main()
