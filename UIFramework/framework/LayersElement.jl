
# Requires NineSliceImage.jl to be included first.

const MASK_ALWAYS = ButtonState(0x00)  # layer always visible
const MASK_NORMAL = ButtonState(0xFF)  # layer visible only when state == BS_NORMAL

abstract type AbstractLayer end

# ── Layer types ────────────────────────────────────────────────────────────────

struct ColorLayer <: AbstractLayer
    color::UInt32
    state_mask::ButtonState
    exclude_mask::ButtonState
    blend_mode::sk_blendmode_t
end
ColorLayer(color::UInt32; state_mask = MASK_ALWAYS, exclude_mask = ButtonState(0), blend_mode = SRCOVER_SK_BLENDMODE) =
    ColorLayer(color, state_mask, exclude_mask, blend_mode)

struct ImageLayer <: AbstractLayer
    image::Ptr{Cvoid}
    state_mask::ButtonState
    exclude_mask::ButtonState
end
function ImageLayer(path::String; state_mask = MASK_ALWAYS, exclude_mask = ButtonState(0))
    ImageLayer(_png_to_skimage(PNGFiles.load(path)), state_mask, exclude_mask)
end

struct NineSliceLayer <: AbstractLayer
    image::Ptr{Cvoid}
    center::sk_irect_t
    repeat_h::BorderRepeat
    repeat_v::BorderRepeat
    state_mask::ButtonState
    exclude_mask::ButtonState
end
function NineSliceLayer(path::String; border = nothing, repeat_h = Stretch, repeat_v = Stretch,
                        state_mask = MASK_ALWAYS, exclude_mask = ButtonState(0))
    metadata = _png_read_9slice(path)
    center   = something(border, metadata)  # errors if neither provided
    NineSliceLayer(_png_to_skimage(PNGFiles.load(path)), center, repeat_h, repeat_v, state_mask, exclude_mask)
end

@kwdef struct TextLayer <: AbstractLayer
    text::String
    color::UInt32            = 0xFF000000
    font_name::String        = "Segoe UI"
    font_size::Float32       = 13f0
    state_mask::ButtonState  = MASK_ALWAYS
    exclude_mask::ButtonState = ButtonState(0)
end
TextLayer(text::String; kw...) = TextLayer(; text, kw...)

# ── Element ────────────────────────────────────────────────────────────────────

@kwdef mutable struct LayersElement <: AbstractPixmapElement
    element::PixmapElement        = PixmapElement()
    layers::Vector{AbstractLayer} = AbstractLayer[]
    state::ButtonState            = BS_NORMAL
end
element(e::LayersElement) = e.element

hover(e::LayersElement)   = (e.state |= BS_HOVERED; repaint(e))
unhover(e::LayersElement) = (e.state &= ~BS_HOVERED; repaint(e))
press(e::LayersElement)   = (e.state |= BS_PRESSED;  repaint(e))
click(e::LayersElement)   = (e.state &= ~BS_PRESSED; repaint(e))

function _layer_visible(state, layer)
    mask = layer.state_mask
    mask == MASK_NORMAL && return state == BS_NORMAL
    (mask == MASK_ALWAYS || state & mask != 0) && state & layer.exclude_mask == 0
end

function onPaint(e::LayersElement, w, h)
    buf     = element(e).pixmap
    info    = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), buf, w * 4, C_NULL, C_NULL, C_NULL)
    canvas  = sk_surface_get_canvas(surface)
    sk_canvas_clear(canvas, 0x00000000)
    for layer in e.layers
        _layer_visible(e.state, layer) && _paint_layer(canvas, layer, w, h)
    end
    sk_surface_unref(surface)
end

# ── Layer painters ─────────────────────────────────────────────────────────────

function _paint_layer(canvas, layer::ColorLayer, ::Integer, ::Integer)
    paint = sk_paint_new()
    sk_paint_set_color(paint, layer.color)
    sk_paint_set_blendmode(paint, layer.blend_mode)
    sk_canvas_draw_paint(canvas, paint)
    sk_paint_delete(paint)
end

function _paint_layer(canvas, layer::ImageLayer, w, h)
    iw  = Float32(sk_image_get_width(layer.image))
    ih  = Float32(sk_image_get_height(layer.image))
    src = sk_rect_t(0f0, 0f0, iw, ih)
    dst = sk_rect_t(0f0, 0f0, Float32(w), Float32(h))
    sk_canvas_draw_image_rect(canvas, layer.image, Ref(src), Ref(dst), _SAMPLING, C_NULL)
end

function _paint_layer(canvas, layer::NineSliceLayer, w, h)
    iw = Float32(sk_image_get_width(layer.image))
    ih = Float32(sk_image_get_height(layer.image))
    c  = layer.center
    sl = Float32(c.left);  st = Float32(c.top)
    sr = iw - Float32(c.right);  sb = ih - Float32(c.bottom)
    fw = Float32(w);  fh = Float32(h)
    rh = layer.repeat_h;  rv = layer.repeat_v

    src_tl = sk_rect_t(0f0,  0f0,  sl,    st);     dst_tl = sk_rect_t(0f0,  0f0,  sl,    st)
    src_t  = sk_rect_t(sl,   0f0,  iw-sr, st);     dst_t  = sk_rect_t(sl,   0f0,  fw-sr, st)
    src_tr = sk_rect_t(iw-sr,0f0,  iw,    st);     dst_tr = sk_rect_t(fw-sr,0f0,  fw,    st)
    src_l  = sk_rect_t(0f0,  st,   sl,    ih-sb);  dst_l  = sk_rect_t(0f0,  st,   sl,    fh-sb)
    src_c  = sk_rect_t(sl,   st,   iw-sr, ih-sb);  dst_c  = sk_rect_t(sl,   st,   fw-sr, fh-sb)
    src_r  = sk_rect_t(iw-sr,st,   iw,    ih-sb);  dst_r  = sk_rect_t(fw-sr,st,   fw,    fh-sb)
    src_bl = sk_rect_t(0f0,  ih-sb,sl,    ih);     dst_bl = sk_rect_t(0f0,  fh-sb,sl,    fh)
    src_b  = sk_rect_t(sl,   ih-sb,iw-sr, ih);     dst_b  = sk_rect_t(sl,   fh-sb,fw-sr, fh)
    src_br = sk_rect_t(iw-sr,ih-sb,iw,    ih);     dst_br = sk_rect_t(fw-sr,fh-sb,fw,    fh)

    _draw_tiled(canvas, layer.image, src_tl, dst_tl, Stretch, Stretch)
    _draw_tiled(canvas, layer.image, src_tr, dst_tr, Stretch, Stretch)
    _draw_tiled(canvas, layer.image, src_bl, dst_bl, Stretch, Stretch)
    _draw_tiled(canvas, layer.image, src_br, dst_br, Stretch, Stretch)
    _draw_tiled(canvas, layer.image, src_t,  dst_t,  rh,      Stretch)
    _draw_tiled(canvas, layer.image, src_b,  dst_b,  rh,      Stretch)
    _draw_tiled(canvas, layer.image, src_l,  dst_l,  Stretch, rv)
    _draw_tiled(canvas, layer.image, src_r,  dst_r,  Stretch, rv)
    _draw_tiled(canvas, layer.image, src_c,  dst_c,  Stretch, Stretch)
end

function _paint_layer(canvas, layer::TextLayer, w, h)
    text      = layer.text
    paint     = sk_paint_new()
    sk_paint_set_color(paint, layer.color)
    fontstyle = sk_fontstyle_new(SK_FONT_STYLE_NORMAL_WEIGHT, SK_FONT_STYLE_NORMAL_WIDTH, UPRIGHT_SK_FONT_STYLE_SLANT)
    typeface  = sk_typeface_create_from_name(layer.font_name, fontstyle)
    font      = sk_font_new()
    sk_font_set_typeface(font, typeface)
    sk_font_set_size(font, layer.font_size)
    sk_font_set_edging(font, SUBPIXEL_ANTIALIAS_SK_FONT_EDGING)
    sk_font_set_subpixel(font, true)
    metrics   = Ref{sk_fontmetrics_t}()
    sk_font_get_metrics(font, metrics)
    tw = sk_font_measure_text(font, pointer(text), sizeof(text), UTF8_SK_TEXT_ENCODING, C_NULL, C_NULL)
    x  = (Float32(w) - tw) / 2f0
    y  = (Float32(h) + metrics[].fCapHeight) / 2f0
    @preserve text sk_canvas_draw_simple_text(canvas, pointer(text), sizeof(text), UTF8_SK_TEXT_ENCODING, x, y, font, paint)
    sk_font_delete(font)
    sk_typeface_unref(typeface)
    sk_fontstyle_delete(fontstyle)
    sk_paint_delete(paint)
end
