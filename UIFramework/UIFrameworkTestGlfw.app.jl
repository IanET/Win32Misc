@info "UIFrameworkTest (GLFW)"

include("../common/LibSkia.jl")
using .LibSkia

include("Layout.jl")
include("Elements.jl")
include("GLFWElementHost.jl")

import .GC.@preserve

sk_color_set_argb(a, r, g, b) = ((UInt32(a) << 24) | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b))

const GAP = -1
const IDC_IMAGE  = 1
const IDC_OK     = 2
const IDC_CANCEL = 3
const IDC_TEXT   = 4

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

@kwdef mutable struct MyCustomPixmapElement <: AbstractPixmapElement
    element::PixmapElement = PixmapElement()
    text::String = "Hello World!"
end
element(e::MyCustomPixmapElement) = e.element

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

function onCreate(host::GLFWHost)
    image_element = MyCustomPixmapElement()
    createGLFWElementHost(host, image_element, IDC_IMAGE, 0, 0, 100, 100)

    text_element = Element(onPaint = element_onPaint, userData = "Simple Text Element")
    createGLFWElementHost(host, text_element, IDC_TEXT, 0, 0, 100, 100)

    ok_button = Button("OK")
    ok_button.onClicked = () -> @info "OK Clicked"
    createGLFWElementHost(host, ok_button, IDC_OK, 0, 0, 100, 100)

    cancel_button = Button("Cancel")
    cancel_button.onClicked = () -> @info "Cancel Clicked"
    createGLFWElementHost(host, cancel_button, IDC_CANCEL, 0, 0, 100, 100)
end

function onResize(host::GLFWHost, w::Int32, h::Int32)
    w > 0 && h > 0 && layout(host, _layout)
end

function main()
    @info "UI Begin"

    host = createGLFWHost("UIFramework Test", 512, 512)
    onCreate(host)
    layout(host, _layout)
    renderAll(host)

    glfwEventLoop(host, onResize)

    destroyGLFWHost(host)
    @info "UI End"
end

main()
