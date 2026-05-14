
import .GC.@preserve

abstract type AbstractElement end
element(e::AbstractElement) = e # Support composition
repaint(e::AbstractElement) = element(e).repaint() # Ask the host to repaint this element sometime soon

# Event handlers that can be overridden by elements
onPaint(e::AbstractElement, w, h) = nothing

# Default behavior, just call the event handlers
paint(e::AbstractElement, w::Integer, h::Integer) = onPaint(e, w, h)

# Catch unhandled events
press(::AbstractElement)                    = nothing
click(::AbstractElement)                    = nothing
hover(::AbstractElement)                    = nothing
unhover(::AbstractElement)                  = nothing
resize(::AbstractElement, w::Integer, h::Integer) = nothing

@kwdef mutable struct Element <: AbstractElement
    onPaint::Function = (e, w, h) -> nothing
    repaint::Function = () -> nothing
    userData::Any = nothing
end
onPaint(e::Element, w, h) = e.onPaint(e, w, h)

# Something that renders in to a pixmap which is cached
abstract type AbstractPixmapElement <: AbstractElement end
onResize(e::AbstractPixmapElement, w, h) = nothing

function checkcache(e::AbstractPixmapElement, w::Integer, h::Integer)
    el = element(e)
    if size(el.pixmap) != (w, h)
        el.pixmap = Matrix{UInt32}(undef, w, h)
    end
end

function resize(e::AbstractPixmapElement, w::Integer, h::Integer)
    el = element(e)
    checkcache(el, w, h)
    onResize(el, w, h)
end

function paint(e::AbstractPixmapElement, w::Integer, h::Integer)
    el = element(e)
    checkcache(el, w, h)
    onPaint(e, w, h)
    return el.pixmap
end

@kwdef mutable struct PixmapElement <: AbstractPixmapElement
    pixmap::Matrix{UInt32} = Matrix{UInt32}(undef, 0, 0)
    repaint::Function = () -> nothing
    userData::Any = nothing
end

# Simplest clickable thing
abstract type AbstractButton <: AbstractPixmapElement end

const ButtonState = UInt8
const BS_NORMAL  = ButtonState(0x00)
const BS_HOVERED = ButtonState(0x01)
const BS_PRESSED = ButtonState(0x02)

onPressed(::AbstractButton) = nothing

function press(b::AbstractButton)
    element(b).state |= BS_PRESSED
    onPressed(b)
    repaint(b)
end

function click(b::AbstractButton)
    el = element(b)
    el.state &= ~BS_PRESSED
    el.onClicked()
    repaint(b)
end

function paint(b::AbstractButton, w::Integer, h::Integer)
    el = element(b)
    checkcache(el, w, h)
    onPaint(b, w, h)
    return el.pixmap
end

function resize(b::AbstractButton, w::Integer, h::Integer)
    el = element(b)
    checkcache(el, w, h)
    onResize(b, w, h)
end

@kwdef mutable struct Button <: AbstractButton
    label::String
    bgColor::UInt32     = 0xFFFFFFFF
    faceColor::UInt32   = 0xFFE1E1E1
    borderColor::UInt32 = 0xFFADADAD
    textColor::UInt32   = 0xFF1A1A1A
    pixmap::Matrix{UInt32} = Matrix{UInt32}(undef, 0, 0)
    onClicked::Function = () -> nothing
    repaint::Function = () -> nothing
    state::ButtonState = BS_NORMAL
    userData::Any = nothing
end
Button(label::String; kw...) = Button(; label=label, kw...)

_invalidate(b::Button) = (b.pixmap = Matrix{UInt32}(undef, 0, 0))

onPressed(b::Button) = _invalidate(b)

function hover(b::Button)
    b.state |= BS_HOVERED
    _invalidate(b)
    repaint(b)
end

function unhover(b::Button)
    b.state &= ~BS_HOVERED
    _invalidate(b)
    repaint(b)
end

function click(b::Button)
    b.state &= ~BS_PRESSED
    _invalidate(b)
    b.onClicked()
    repaint(b)
end

function resize(b::Button, w::Integer, h::Integer)
    b.pixmap = Matrix{UInt32}(undef, 0, 0)
    onResize(b, w, h)
end

function paint(b::Button, w::Integer, h::Integer)
    size(b.pixmap) == (w, h) && return b.pixmap
    b.pixmap = fill(b.bgColor, w, h)
    onPaint(b, w, h)
    return b.pixmap
end

function onPaint(b::Button, w, h)
    cache = b.pixmap
    label = b.label
    info = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), cache, w * 4, C_NULL, C_NULL, C_NULL)
    canvas = sk_surface_get_canvas(surface)

    pressed = b.state & BS_PRESSED != 0
    hovered = b.state & BS_HOVERED != 0
    m = 2f0  # margin between bgColor and face

    skpaint = sk_paint_new()
    sk_paint_set_antialias(skpaint, true)

    face = sk_rect_t(m, m, Float32(w) - m, Float32(h) - m)

    # Face fill: darken ~12% when pressed, lighten ~6% when hovered
    _ch(c, n, d) = UInt32(min(0xFF, UInt32((c >> 0) & 0xFF) * n ÷ d))
    _adj(base, n, d) = (base & 0xFF000000) |
        (_ch(base >> 16, n, d) << 16) |
        (_ch(base >>  8, n, d) <<  8) |
         _ch(base,       n, d)
    base = b.faceColor
    face_color = pressed ? _adj(base, 7, 8) : hovered ? _adj(base, 17, 16) : base
    sk_paint_set_style(skpaint, FILL_SK_PAINT_STYLE)
    sk_paint_set_color(skpaint, face_color)
    sk_canvas_draw_round_rect(canvas, Ref(face), 3f0, 3f0, skpaint)

    # Border
    sk_paint_set_style(skpaint, STROKE_SK_PAINT_STYLE)
    sk_paint_set_stroke_width(skpaint, 1f0)
    sk_paint_set_color(skpaint, b.borderColor)
    sk_canvas_draw_round_rect(canvas, Ref(face), 3f0, 3f0, skpaint)

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

    sk_paint_set_style(skpaint, FILL_SK_PAINT_STYLE)
    sk_paint_set_color(skpaint, b.textColor)
    sk_canvas_draw_simple_text(canvas, pointer(label), sizeof(label), UTF8_SK_TEXT_ENCODING, x, y, font, skpaint)

    sk_font_delete(font)
    sk_typeface_unref(typeface)
    sk_fontstyle_delete(fontstyle)
    sk_paint_delete(skpaint)
    sk_surface_unref(surface)
end
