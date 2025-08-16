using LibBaseTsd, Cairo

include("../common/Win32.jl")
using .W32

include("Layout.jl")

import Base.cconvert, .GC.@preserve, ColorTypes.ARGB32

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
size_t(i::Int64) = reinterpret(UInt64, i) |> SIZE_T
flush_ws() = SetProcessWorkingSetSize(GetCurrentProcess(), size_t(-1), size_t(-1))

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
_mbits::Matrix{ARGB32} = [;;]

function onImageCreate(hwnd)::LRESULT
    # @info "onImageCreate" hwnd
    return 0
end

function onImageDestroy(hwnd)::LRESULT
    # @info "onImageDestroy" hwnd
    return 0
end

function cairoDraw(w, h)
    global _mbits
    surface = CairoImageSurface(_mbits)
    ctx = CairoContext(surface) 

    set_source_rgb(ctx, 1.0, 1.0, 1.0)
    rectangle(ctx, 0, 0, w, h)
    fill(ctx)

    set_source_rgb(ctx, 1.0, 0, 0)
    arc(ctx, w/2, h/2, 100, 0, 2*pi)
    fill(ctx)

    set_source_rgb(ctx, 0.0, 0.0, 0.0)
    select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    set_font_size(ctx, 24)
    move_to(ctx, 0, 20)
    show_text(ctx, "Testing Cairo")
end

function onImagePaint(hwnd)::LRESULT
    @info "onImagePaint" hwnd
    ps = PAINTSTRUCT() |> Ref
    hdc = BeginPaint(hwnd, ps)
    rcclient = RECT() |> Ref
    GetClientRect(hwnd, rcclient)
    cairoDraw(rcclient[].right - rcclient[].left, rcclient[].bottom - rcclient[].top) # draw the whole thing
    hdcmem = CreateCompatibleDC(hdc)
    hbmpold = SelectObject(hdcmem, _dib)
    BitBlt(hdc, ps[].rcPaint.left, ps[].rcPaint.top, ps[].rcPaint.right - ps[].rcPaint.left, ps[].rcPaint.bottom - ps[].rcPaint.top, hdcmem, ps[].rcPaint.left, ps[].rcPaint.top, SRCCOPY)
    SelectObject(hdcmem, hbmpold)
    DeleteDC(hdcmem)
    EndPaint(hwnd, ps)
    return 0
end

function onImageSize(hwnd, width, height)::LRESULT
    global _dib, _mbits
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
    _mbits = unsafe_wrap(Array, Ptr{ARGB32}(pbits[]), (width, height))
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
    if wparam == SIZE_MINIMIZED
        flush_ws()
        return 0 
    end
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

function onGetMinMaxInfo(hwnd, pmmi::Ptr{MINMAXINFO})
    unsafe_modify_cstruct(pmmi, :ptMinTrackSize, POINT(MIN_WIDTH, MIN_HEIGHT))
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
        LoadIconW(C_NULL, IDI_INFORMATION), 
        LoadCursorW(C_NULL, IDC_ARROW), 
        HBRUSH(COLOR_WINDOW+1), 
        C_NULL, 
        pointer(classname))
    @preserve classname RegisterClassW(Ref(wc))
    hwnd = CreateWindowExW(DWORD(0), classname, L"Cairo Test", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 512, 512, C_NULL, C_NULL, HINST, C_NULL)
    return hwnd
end

function main()
    @info "UI Begin"

    hwnd = createMainWindow()
    ShowWindow(hwnd, SW_SHOWNORMAL)
    flush_ws()

    MsgLoop() do msg
        TranslateMessage(msg)
        DispatchMessageW(msg)
    end

    @info "UI End"
end

main()
