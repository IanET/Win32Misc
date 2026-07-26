
using PNGFiles
import ColorTypes: red, green, blue, alpha

@enum BorderRepeat Stretch Repeat Round Space

@kwdef mutable struct NineSliceImage <: AbstractPixmapElement
    element::PixmapElement = PixmapElement()
    skimage::Ptr{Cvoid} = C_NULL
    center::sk_irect_t = sk_irect_t(0, 0, 0, 0)
    border::Union{sk_irect_t, Nothing} = nothing  # overrides center when set
    background::UInt32 = 0x00000000
    repeat_h::BorderRepeat = Stretch
    repeat_v::BorderRepeat = Stretch
end
element(e::NineSliceImage) = e.element

function NineSliceImage(path::String; border::Union{sk_irect_t, Nothing} = nothing)
    metadata = _png_read_9slice(path)
    center   = something(border, metadata)  # errors if no border and no metadata
    skimage  = _png_to_skimage(PNGFiles.load(path))
    NineSliceImage(skimage=skimage, center=center, border=border)
end

# Read tEXt chunks from a PNG binary to find the "9slice" keyword.
# Returns sk_irect_t parsed from "left top right bottom" value.
function _png_read_9slice(path::String)
    result = open(path, "r") do io
        read(io, 8)  # PNG signature
        while !eof(io)
            len  = ntoh(read(io, UInt32))
            type = String(read(io, 4))
            data = read(io, len)
            read(io, 4)  # CRC
            if type == "tEXt"
                sep = findfirst(==(0x00), data)
                sep === nothing && continue
                key = String(data[1:sep-1])
                if key == "9slice"
                    vals = parse.(Int32, split(String(data[sep+1:end])))
                    length(vals) == 4 || error("9slice metadata must be \"left top right bottom\"")
                    return sk_irect_t(vals[1], vals[2], vals[3], vals[4])
                end
            end
        end
        nothing
    end
    return result
end

function _png_to_skimage(img)
    H, W = size(img)
    pixels = Matrix{UInt32}(undef, W, H)  # W×H for row-major memory layout
    for row in 1:H, col in 1:W
        c = img[row, col]
        r = UInt32(reinterpret(UInt8, red(c)))
        g = UInt32(reinterpret(UInt8, green(c)))
        b = UInt32(reinterpret(UInt8, blue(c)))
        a = UInt32(reinterpret(UInt8, alpha(c)))
        pixels[col, row] = (a << 24) | (b << 16) | (g << 8) | r  # RGBA_8888
    end
    info = sk_imageinfo_t(C_NULL, W, H, RGBA_8888_SK_COLORTYPE, UNPREMUL_SK_ALPHATYPE)
    @preserve pixels return sk_image_new_raster_copy(Ref(info), pixels, W * 4)
end

const _SAMPLING = Ref(sk_sampling_options_t(0, false, sk_cubic_resampler_t(0f0, 0f0), LINEAR_SK_FILTER_MODE, NONE_SK_MIPMAP_MODE))

# Returns a list of (tile_start, tile_end) positions along one axis.
# dst0/dst1: destination range. tile_sz: natural size of the source tile.
function _tile_placements(dst0::Float32, dst1::Float32, tile_sz::Float32, mode::BorderRepeat)
    dlen = dst1 - dst0
    dlen <= 0f0 && return Tuple{Float32,Float32}[]
    if mode == Stretch
        return [(dst0, dst1)]
    elseif mode == Round
        n = max(1, round(Int, dlen / tile_sz))
        tw = dlen / n
        return [(dst0 + i * tw, dst0 + (i + 1) * tw) for i in 0:n-1]
    elseif mode == Space
        n = max(1, floor(Int, dlen / tile_sz))
        gap      = (dlen - n * tile_sz) / n  # gap between tiles (= 2× edge margin)
        half_gap = gap / 2f0
        step     = tile_sz + gap
        return [(dst0 + half_gap + i * step, dst0 + half_gap + i * step + tile_sz) for i in 0:n-1]
    else  # Repeat — centre tiles so overflow is clipped equally at both edges
        n = max(1, ceil(Int, dlen / tile_sz))
        offset = (dlen - n * tile_sz) / 2f0
        return [(dst0 + offset + i * tile_sz, dst0 + offset + (i + 1) * tile_sz) for i in 0:n-1]
    end
end

# Draws src tiled into dst_clip using mode_h horizontally and mode_v vertically.
function _draw_tiled(canvas, image, src::sk_rect_t, dst_clip::sk_rect_t, mode_h::BorderRepeat, mode_v::BorderRepeat)
    sw = src.right - src.left
    sh = src.bottom - src.top
    (sw <= 0f0 || sh <= 0f0) && return
    tiles_x = _tile_placements(dst_clip.left, dst_clip.right,  sw, mode_h)
    tiles_y = _tile_placements(dst_clip.top,  dst_clip.bottom, sh, mode_v)
    (isempty(tiles_x) || isempty(tiles_y)) && return
    sk_canvas_save(canvas)
    sk_canvas_clip_rect_with_operation(canvas, Ref(dst_clip), INTERSECT_SK_CLIPOP, false)
    for (y0, y1) in tiles_y, (x0, x1) in tiles_x
        dst = sk_rect_t(x0, y0, x1, y1)
        sk_canvas_draw_image_rect(canvas, image, Ref(src), Ref(dst), _SAMPLING, C_NULL)
    end
    sk_canvas_restore(canvas)
end

function onPaint(e::NineSliceImage, w, h)
    iw = Float32(sk_image_get_width(e.skimage))
    ih = Float32(sk_image_get_height(e.skimage))
    c  = something(e.border, e.center)
    sl = Float32(c.left)
    st = Float32(c.top)
    sr = iw - Float32(c.right)
    sb = ih - Float32(c.bottom)
    fw = Float32(w)
    fh = Float32(h)

    buf     = element(e).pixmap
    info    = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), buf, w * 4, C_NULL, C_NULL, C_NULL)
    canvas  = sk_surface_get_canvas(surface)

    sk_canvas_clear(canvas, e.background)

    # Source slice rects
    src_tl = sk_rect_t(0f0,  0f0,  sl,    st)
    src_t  = sk_rect_t(sl,   0f0,  iw-sr, st)
    src_tr = sk_rect_t(iw-sr,0f0,  iw,    st)
    src_l  = sk_rect_t(0f0,  st,   sl,    ih-sb)
    src_c  = sk_rect_t(sl,   st,   iw-sr, ih-sb)
    src_r  = sk_rect_t(iw-sr,st,   iw,    ih-sb)
    src_bl = sk_rect_t(0f0,  ih-sb,sl,    ih)
    src_b  = sk_rect_t(sl,   ih-sb,iw-sr, ih)
    src_br = sk_rect_t(iw-sr,ih-sb,iw,    ih)

    # Destination clip rects
    dst_tl = sk_rect_t(0f0,  0f0,  sl,    st)
    dst_t  = sk_rect_t(sl,   0f0,  fw-sr, st)
    dst_tr = sk_rect_t(fw-sr,0f0,  fw,    st)
    dst_l  = sk_rect_t(0f0,  st,   sl,    fh-sb)
    dst_c  = sk_rect_t(sl,   st,   fw-sr, fh-sb)
    dst_r  = sk_rect_t(fw-sr,st,   fw,    fh-sb)
    dst_bl = sk_rect_t(0f0,  fh-sb,sl,    fh)
    dst_b  = sk_rect_t(sl,   fh-sb,fw-sr, fh)
    dst_br = sk_rect_t(fw-sr,fh-sb,fw,    fh)

    rh = e.repeat_h
    rv = e.repeat_v

    # Corners always stretch
    _draw_tiled(canvas, e.skimage, src_tl, dst_tl, Stretch, Stretch)
    _draw_tiled(canvas, e.skimage, src_tr, dst_tr, Stretch, Stretch)
    _draw_tiled(canvas, e.skimage, src_bl, dst_bl, Stretch, Stretch)
    _draw_tiled(canvas, e.skimage, src_br, dst_br, Stretch, Stretch)

    # Top/bottom edges tile horizontally
    _draw_tiled(canvas, e.skimage, src_t, dst_t, rh, Stretch)
    _draw_tiled(canvas, e.skimage, src_b, dst_b, rh, Stretch)

    # Left/right edges tile vertically
    _draw_tiled(canvas, e.skimage, src_l, dst_l, Stretch, rv)
    _draw_tiled(canvas, e.skimage, src_r, dst_r, Stretch, rv)

    # Center always stretches
    _draw_tiled(canvas, e.skimage, src_c, dst_c, Stretch, Stretch)

    sk_surface_unref(surface)
end
