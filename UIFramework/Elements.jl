
import .GC.@preserve

abstract type AbstractElement end
element(e::AbstractElement) = e
paint(e::AbstractElement, w::Integer, h::Integer) = element(e).onPaint(e, w, h)
click(e::AbstractElement) = element(e).onClick()
press(e::AbstractElement) = element(e).onPressed()
resize(e::AbstractElement, w::Integer, h::Integer) = element(e).onResize(w, h)
repaint(e::AbstractElement) = element(e).repaint()

abstract type AbstractPixmapElement <: AbstractElement end
pixmapElement(e::AbstractPixmapElement) = e
press(e::AbstractPixmapElement) = onPressed(e)
onPaint(::AbstractPixmapElement, w, h) = nothing
onPressed(::AbstractPixmapElement) = nothing
onResize(::AbstractPixmapElement, w, h) = nothing

function checkcache(e::AbstractPixmapElement, w::Integer, h::Integer)
    if size(e.pixmap) != (w, h)
        e.pixmap = Matrix{UInt32}(undef, w, h)
    end
end

function resize(e::AbstractPixmapElement, w::Integer, h::Integer)
    el = element(e)
    checkcache(el, w, h)
    onResize(e, w, h)
end

function paint(e::AbstractPixmapElement, w::Integer, h::Integer)
    el = element(e)
    checkcache(el, w, h)
    pbits = Ptr{Cvoid}(pointer(el.pixmap))
    onPaint(e, w, h)
    return pbits
end

@kwdef mutable struct PixmapElement <: AbstractPixmapElement
    pixmap::Matrix{UInt32} = Matrix{UInt32}(undef, 0, 0)
    onClick::Function = () -> nothing
    repaint::Function = () -> nothing
    userData::Any = nothing
end

abstract type AbstractButton <: AbstractPixmapElement end
button(b::AbstractButton) = b
onPressed(::AbstractButton) = nothing
onResize(::AbstractButton, w, h) = nothing

function press(b::AbstractButton)
    btn = button(b)
    btn.isPressed = true
    onPressed(b)
    repaint(b)
end

function click(b::AbstractButton)
    btn = button(b)
    btn.isPressed = false
    btn.onClick()
    repaint(b)
end

@kwdef mutable struct Button <: AbstractButton
    label::String
    pixmap::Matrix{UInt32} = Matrix{UInt32}(undef, 0, 0)
    onClick::Function = () -> nothing
    repaint::Function = () -> nothing
    isPressed::Bool = false
    userData::Any = nothing
end

function paint(b::AbstractButton, w::Integer, h::Integer)
    btn = button(b)
    checkcache(btn, w, h)
    pbits = Ptr{Cvoid}(pointer(btn.pixmap))
    onPaint(b, w, h)
    return pbits
end

function resize(b::AbstractButton, w::Integer, h::Integer)
    btn = button(b)
    checkcache(btn, w, h)
    onResize(b, w, h)
end

Button(label::String) = Button(label=label)

function onPaint(b::AbstractButton, w, h)
    btn = button(b)
    cache = btn.pixmap
    label = btn.label
    info = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), cache, w * 4, C_NULL, C_NULL, C_NULL)
    canvas = sk_surface_get_canvas(surface)

    pressed = btn.isPressed

    paint = sk_paint_new()
    sk_paint_set_antialias(paint, true)

    bounds = sk_rect_t(0f0, 0f0, Float32(w), Float32(h))

    # Fill
    fill_color = pressed ? sk_color_set_argb(0xFF, 0xC8, 0xC8, 0xC8) : sk_color_set_argb(0xFF, 0xE1, 0xE1, 0xE1)
    sk_paint_set_style(paint, FILL_SK_PAINT_STYLE)
    sk_paint_set_color(paint, fill_color)
    sk_canvas_draw_round_rect(canvas, Ref(bounds), 3f0, 3f0, paint)

    # Border
    sk_paint_set_style(paint, STROKE_SK_PAINT_STYLE)
    sk_paint_set_stroke_width(paint, 1f0)
    sk_paint_set_color(paint, sk_color_set_argb(0xFF, 0xAD, 0xAD, 0xAD))
    sk_canvas_draw_round_rect(canvas, Ref(bounds), 3f0, 3f0, paint)

    # Text
    fontstyle = sk_fontstyle_new(SK_FONT_STYLE_NORMAL_WEIGHT, SK_FONT_STYLE_NORMAL_WIDTH, UPRIGHT_SK_FONT_STYLE_SLANT)
    typeface = sk_typeface_create_from_name("Segoe UI", fontstyle)
    font = sk_font_new()
    sk_font_set_typeface(font, typeface)
    sk_font_set_size(font, 13f0)
    sk_font_set_edging(font, SUBPIXEL_ANTIALIAS_SK_FONT_EDGING)
    sk_font_set_subpixel(font, true)

    textwidth = sk_font_measure_text(font, pointer(label), sizeof(label), UTF8_SK_TEXT_ENCODING, C_NULL, C_NULL)
    metrics = Ref{sk_fontmetrics_t}()
    sk_font_get_metrics(font, metrics)
    offset = pressed ? 1f0 : 0f0
    x = (w - textwidth) / 2f0 + offset
    y = (h + metrics[].fCapHeight) / 2f0 + offset

    sk_paint_set_style(paint, FILL_SK_PAINT_STYLE)
    sk_paint_set_color(paint, sk_color_set_argb(0xFF, 0x1A, 0x1A, 0x1A))
    sk_canvas_draw_simple_text(canvas, pointer(label), sizeof(label), UTF8_SK_TEXT_ENCODING, x, y, font, paint)

    sk_paint_delete(paint)
    sk_surface_unref(surface)
end
