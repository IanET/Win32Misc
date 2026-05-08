
import .GC.@preserve

abstract type AbstractElement end
paint(e::AbstractElement, w::Integer, h::Integer) = e.onPaint(e, w, h)
click(e::AbstractElement) = e.onClick()
resize(e::AbstractElement, w::Integer, h::Integer) = e.onResize(w, h)

abstract type AbstractImageCacheElement <: AbstractElement end

@kwdef mutable struct ImageCacheElement <: AbstractImageCacheElement
    imageCache::Matrix{UInt32} = Matrix{UInt32}(undef, 0, 0)
    onPaint::Function = (e, w, h) -> nothing
    onClick::Function = () -> nothing
    onResize::Function = (w, h) -> nothing
end

function checkcache(e::AbstractImageCacheElement, w::Integer, h::Integer)
    if size(e.imageCache) != (w, h)
        e.imageCache = Matrix{UInt32}(undef, w, h)
    end
end

function resize(e::AbstractImageCacheElement, w::Integer, h::Integer)
    checkcache(e, w, h)
    e.onResize(w, h)
end

function paint(e::AbstractImageCacheElement, w::Integer, h::Integer)
    checkcache(e, w, h)
    pbits = Ptr{Cvoid}(pointer(e.imageCache))
    e.onPaint(e, w, h)
    return pbits
end

@kwdef mutable struct Button <: AbstractImageCacheElement
    label::String
    imageCache::Matrix{UInt32} = Matrix{UInt32}(undef, 0, 0)
    onPaint::Function = (b, w, h) -> nothing
    onClick::Function = () -> nothing
    onResize::Function = (w, h) -> nothing
end

function Button(label::String)
    b = Button(label=label)
    b.onPaint = (b, w, h) -> paintButton(b, w, h)
    return b
end

function paintButton(b::Button, w::Integer, h::Integer)
    cache = b.imageCache
    label = b.label
    info = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), cache, w * 4, C_NULL, C_NULL, C_NULL)
    canvas = sk_surface_get_canvas(surface)

    paint = sk_paint_new()
    sk_paint_set_antialias(paint, true)

    bounds = sk_rect_t(0f0, 0f0, Float32(w), Float32(h))

    # Fill
    sk_paint_set_style(paint, FILL_SK_PAINT_STYLE)
    sk_paint_set_color(paint, sk_color_set_argb(0xFF, 0xE1, 0xE1, 0xE1))
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
    x = (w - textwidth) / 2f0
    y = (h + metrics[].fCapHeight) / 2f0

    sk_paint_set_style(paint, FILL_SK_PAINT_STYLE)
    sk_paint_set_color(paint, sk_color_set_argb(0xFF, 0x1A, 0x1A, 0x1A))
    sk_canvas_draw_simple_text(canvas, pointer(label), sizeof(label), UTF8_SK_TEXT_ENCODING, x, y, font, paint)

    sk_paint_delete(paint)
    sk_surface_unref(surface)
end
