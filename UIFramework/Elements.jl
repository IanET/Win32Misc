
abstract type AbstractElement end

mutable struct Element <: AbstractElement
    buffer::Vector{UInt8}
    cache_w::Int32
    cache_h::Int32
    _paint::Function
    onPaint::Function
    function Element(paint::Function)
        e = new(UInt8[], Int32(0), Int32(0), paint, (w, h) -> Ptr{Cvoid}(0))
        e.onPaint = function(w, h)
            if e.cache_w != w || e.cache_h != h
                resize!(e.buffer, Int(w) * Int(h) * 4)
                e.cache_w = w
                e.cache_h = h
            end
            pbits = Ptr{Cvoid}(pointer(e.buffer))
            e._paint(pbits, w, h)
            return pbits
        end
        return e
    end
end

mutable struct Button <: AbstractElement
    label::String
    buffer::Vector{UInt8}
    cache_w::Int32
    cache_h::Int32
    onPaint::Function
    function Button(label::String)
        b = new(label, UInt8[], Int32(0), Int32(0), (w, h) -> Ptr{Cvoid}(0))
        b.onPaint = function(w, h)
            if b.cache_w != w || b.cache_h != h
                resize!(b.buffer, Int(w) * Int(h) * 4)
                b.cache_w = w
                b.cache_h = h
            end
            pbits = Ptr{Cvoid}(pointer(b.buffer))
            paintButton(pbits, w, h, b.label)
            return pbits
        end
        return b
    end
end

function paintButton(pbits::Ptr{Cvoid}, w::Integer, h::Integer, label::String)
    info = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), pbits, w * 4, C_NULL, C_NULL, C_NULL)
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
