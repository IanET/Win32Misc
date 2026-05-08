@info "UIFrameworkTest"
using LibBaseTsd

# @info "Win32"
include("../common/Win32.jl")
using .W32
import .W32: TRUE, FALSE

# @info "LibSkia"
include("../common/LibSkia.jl")
using .LibSkia

# @info "Layout"
include("Layout.jl")
include("Elements.jl")

# @info "Base"
import Base.cconvert, .GC.@preserve

const GAP = -1
const IDC_IMAGE = 1
const IDC_OK = 2
const IDC_CANCEL = 3
const MIN_WIDTH = 200
const MIN_HEIGHT = 200

const BLUE_GRAY_BRUSH = CreateSolidBrush(RGB(0xD0, 0xD0, 0xE0))
const HINST::HINSTANCE = GetModuleHandleW(C_NULL)

# Helpers
cwstring(s) = cconvert(Cwstring, s)
tostring(v::AbstractArray{Cwchar_t}) = transcode(String, @view v[begin:findfirst(iszero, v)-1])
tolparam(s::String) = s |> cwstring |> pointer |> LPARAM
Base.Tuple(v::AbstractVector{UInt16}, len) = copyto!(zeros(UInt16, len), v) |> Tuple
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

@kwdef mutable struct ElementHostState
    onPaint::Function = (w, h) -> Ptr{Cvoid}(0)
    onClick::Function = () -> nothing
    onResize::Function = (w, h) -> nothing
end

const _hosts = Dict{HWND, ElementHostState}()

function onElementHostCreate(hwnd)::LRESULT
    _hosts[hwnd] = ElementHostState()
    return 0
end

function onElementHostDestroy(hwnd)::LRESULT
    delete!(_hosts, hwnd)
    return 0
end

sk_color_set_argb(a, r, g, b) = ((UInt32(a) << 24) | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b))

function skiaDraw(e::ImageCacheElement, w, h)
    pbits = Ptr{Cvoid}(pointer(e.imageCache))
    info = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), pbits, w * 4, C_NULL, C_NULL, C_NULL)
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

function onElementHostPaint(hwnd)::LRESULT
    state = _hosts[hwnd]
    ps = PAINTSTRUCT() |> Ref
    hdc = BeginPaint(hwnd, ps)
    rcclient = RECT() |> Ref
    GetClientRect(hwnd, rcclient)
    w = rcclient[].right - rcclient[].left
    h = rcclient[].bottom - rcclient[].top
    if w > 0 && h > 0
        pbits = state.onPaint(w, h)
        bmih = BITMAPINFOHEADER(sizeof(BITMAPINFOHEADER), w, -h, 1, 32, BI_RGB, 0, 0, 0, 0, 0) |> Ref
        bmpinfo = BITMAPINFO(bmih[], (RGBQUAD(),)) |> Ref
        SetDIBitsToDevice(hdc, 0, 0, w, h, 0, 0, 0, h, pbits, bmpinfo, DIB_RGB_COLORS)
    end
    EndPaint(hwnd, ps)
    return 0
end

function onElementHostResize(hwnd, w, h)::LRESULT
    _hosts[hwnd].onResize(w, h)
    return 0
end

function onElementHostClick(hwnd)::LRESULT
    _hosts[hwnd].onClick()
    return 0
end

function elementHostWndProc(hwnd::HWND, umsg::UINT, wparam::WPARAM, lparam::LPARAM)::LRESULT
    try
        if umsg == WM_CREATE
            return onElementHostCreate(hwnd)
        elseif umsg == WM_DESTROY
            return onElementHostDestroy(hwnd)
        elseif umsg == WM_PAINT
            return onElementHostPaint(hwnd)
        elseif umsg == WM_SIZE
            return onElementHostResize(hwnd, LOWORD(lparam), HIWORD(lparam))
        elseif umsg == WM_LBUTTONUP
            return onElementHostClick(hwnd)
        end
        return DefWindowProcW(hwnd, umsg, wparam, lparam)
    catch exc
        @error exc
        @info "Exception" catch_backtrace() |> stacktrace
    end

    return 0
end

function createElementHost(parent, id, x, y, w, h)
    classname = L"ElementHostClass"
    wc = WNDCLASSW(
        CS_HREDRAW | CS_VREDRAW, 
        @cfunction(elementHostWndProc, LRESULT, (HWND, UINT, WPARAM, LPARAM)), 
        0, 0, 
        HINST, 
        LoadIconW(HINSTANCE(0), IDI_INFORMATION), 
        LoadCursorW(HINSTANCE(0), IDC_ARROW), 
        HBRUSH(COLOR_WINDOW+1), 
        C_NULL, 
        pointer(classname))
    @preserve classname RegisterClassW(Ref(wc))
    hwnd = CreateWindowExW(DWORD(0), classname, L"ElementHost", WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS, x, y, w, h, parent, HMENU(id), HINST, LPVOID(0))
    return hwnd
end

function onCreate(hwnd)
    image_element = ImageCacheElement()
    image_element.onPaint = skiaDraw
    hwndImage = createElementHost(hwnd, IDC_IMAGE, 0, 0, 100, 100)
    _hosts[hwndImage].onPaint = (w, h) -> paint(image_element, w, h)
    _hosts[hwndImage].onResize = (w, h) -> resize(image_element, w, h)

    ok_button = Button("OK")
    ok_button.onClick = () -> @info "OK Clicked"
    hwndOK = createElementHost(hwnd, IDC_OK, 0, 0, 100, 100)
    _hosts[hwndOK].onPaint = (w, h) -> paint(ok_button, w, h)
    _hosts[hwndOK].onClick = () -> click(ok_button)
    _hosts[hwndOK].onResize = (w, h) -> resize(ok_button, w, h)

    cancel_button = Button("Cancel")
    cancel_button.onClick = () -> @info "Cancel Clicked"
    hwndCancel = createElementHost(hwnd, IDC_CANCEL, 0, 0, 100, 100)
    _hosts[hwndCancel].onPaint = (w, h) -> paint(cancel_button, w, h)
    _hosts[hwndCancel].onClick = () -> click(cancel_button)
    _hosts[hwndCancel].onResize = (w, h) -> resize(cancel_button, w, h)

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
        LoadIconW(HINSTANCE(0), IDI_INFORMATION), 
        LoadCursorW(HINSTANCE(0), IDC_ARROW), 
        HBRUSH(COLOR_WINDOW+1), 
        C_NULL, 
        pointer(classname))
    @preserve classname RegisterClassW(Ref(wc))
    hwnd = CreateWindowExW(DWORD(0), classname, L"UIFramework Test", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 512, 512, HWND(0), HMENU(0), HINST, LPVOID(0))
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
