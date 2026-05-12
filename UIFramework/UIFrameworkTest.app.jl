@info "UIFrameworkTest"
using LibBaseTsd

# @info "Win32"
include("../common/Win32.jl")
using .W32
import .W32: TRUE, FALSE

# @info "LibSkia"
include("../common/LibSkia.jl")
using .LibSkia

include("Layout.jl")
include("Elements.jl")
include("Win32ElementHost.jl")

# @info "Base"
import Base.cconvert, .GC.@preserve

const GAP = -1
const IDC_IMAGE = 1
const IDC_OK = 2
const IDC_CANCEL = 3
const IDC_TEXT = 4
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
        GAP     IDC_TEXT    IDC_OK      IDC_CANCEL  GAP
        GAP     GAP         GAP         GAP         GAP    
    ], 
    [5, ★"1", 5, 30, 5],   # row heights
    [5, ★"1", 75, 75, 5])  # col widths

sk_color_set_argb(a, r, g, b) = ((UInt32(a) << 24) | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b))

# Example of custom element with custom painting using composition
@kwdef mutable struct MyCustomPixmapElement <: AbstractPixmapElement
    element::PixmapElement = PixmapElement()
    text::String = "Hello World!"
    # More private state can go here
end
element(e::MyCustomPixmapElement) = e.element # compose

function onPaint(outer::MyCustomPixmapElement, w, h)
    buf = element(outer).pixmap
    text = outer.text
    info = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), buf, w * 4, C_NULL, C_NULL, C_NULL)
    canvas = sk_surface_get_canvas(surface)

    fill = sk_paint_new()
    sk_paint_set_color(fill, sk_color_set_argb(0xFF, 0xA0, 0xB0, 0xE0))
    sk_canvas_draw_paint(canvas, fill)

    sk_paint_set_color(fill, sk_color_set_argb(0xFF, 0xD0, 0x80, 0x80))
    rect = sk_rect_t(50, 50, w - 50, h - 50)
    sk_canvas_draw_rect(canvas, Ref(rect), fill)

    textpaint = sk_paint_new()
    sk_paint_set_color(textpaint, sk_color_set_argb(0xFF, 0x00, 0x00, 0x00))
    fontstyle = sk_fontstyle_new(SK_FONT_STYLE_NORMAL_WEIGHT, SK_FONT_STYLE_NORMAL_WIDTH, UPRIGHT_SK_FONT_STYLE_SLANT)
    typeface = sk_typeface_create_from_name("Arial", fontstyle)
    font = sk_font_new()
    sk_font_set_typeface(font, typeface)
    sk_font_set_size(font, 24.0)
    @preserve text sk_canvas_draw_simple_text(canvas, pointer(text), sizeof(text), UTF8_SK_TEXT_ENCODING, 10.0, 35.0, font, textpaint)

    sk_font_delete(font)
    sk_typeface_unref(typeface)
    sk_fontstyle_delete(fontstyle)
    sk_paint_delete(textpaint)
    sk_paint_delete(fill)
    sk_surface_unref(surface)
end

# An example of a simple custom paint for an Element instance
function element_onPaint(e, w, h)
    pixmap = Matrix{UInt32}(undef, w, h)
    text = e.userData
    info = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), pixmap, w * 4, C_NULL, C_NULL, C_NULL)
    canvas = sk_surface_get_canvas(surface)
    paint = sk_paint_new()
    sk_paint_set_color(paint, sk_color_set_argb(0xFF, 0xFF, 0xFF, 0xFF))
    sk_canvas_draw_paint(canvas, paint)
    fontstyle = sk_fontstyle_new(SK_FONT_STYLE_NORMAL_WEIGHT, SK_FONT_STYLE_NORMAL_WIDTH, UPRIGHT_SK_FONT_STYLE_SLANT)
    typeface = sk_typeface_create_from_name("Segoe UI", fontstyle)
    font = sk_font_new()
    sk_font_set_typeface(font, typeface)
    sk_font_set_size(font, 13f0)
    sk_font_set_edging(font, SUBPIXEL_ANTIALIAS_SK_FONT_EDGING)
    sk_font_set_subpixel(font, true)
    metrics = Ref{sk_fontmetrics_t}()
    sk_font_get_metrics(font, metrics)
    y = (h + metrics[].fCapHeight) / 2f0
    sk_paint_set_color(paint, sk_color_set_argb(0xFF, 0x1A, 0x1A, 0x1A))
    @preserve text sk_canvas_draw_simple_text(canvas, pointer(text), sizeof(text), UTF8_SK_TEXT_ENCODING, 5f0, y, font, paint)
    sk_font_delete(font)
    sk_typeface_unref(typeface)
    sk_fontstyle_delete(fontstyle)
    sk_paint_delete(paint)
    sk_surface_unref(surface)
    return pixmap
end

function onCreate(hwnd)
    image_element = MyCustomPixmapElement()
    createElementHost(hwnd, image_element, IDC_IMAGE, 0, 0, 100, 100)

    text_element = Element(onPaint = element_onPaint, userData = "Simple Text Element")
    createElementHost(hwnd, text_element, IDC_TEXT, 0, 0, 100, 100)

    ok_button = Button("OK"; bgColor = 0xFFFFFFFF)   # default
    ok_button.onClicked = () -> @info "OK Clicked"
    createElementHost(hwnd, ok_button, IDC_OK, 0, 0, 100, 100)

    cancel_button = Button("Cancel"; bgColor = 0xFFFF0000, faceColor = 0xFF00FF00, borderColor = 0xFF0000FF)   # white
    cancel_button.onClicked = () -> @info "Cancel Clicked"
    createElementHost(hwnd, cancel_button, IDC_CANCEL, 0, 0, 100, 100)

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
        throw(exc)
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
