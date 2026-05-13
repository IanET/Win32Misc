
using PNGFiles
import ColorTypes: red, green, blue, alpha

@kwdef mutable struct NineSliceImage <: AbstractPixmapElement
    element::PixmapElement = PixmapElement()
    skimage::Ptr{Cvoid} = C_NULL
    center::sk_irect_t = sk_irect_t(0, 0, 0, 0)
    background::UInt32 = 0x00000000
end
element(e::NineSliceImage) = e.element

function NineSliceImage(path::String)
    center  = _png_read_9slice(path)
    skimage = _png_to_skimage(PNGFiles.load(path))
    NineSliceImage(skimage=skimage, center=center)
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
    result !== nothing ? result : error("No 9slice metadata found in $path")
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

function onPaint(e::NineSliceImage, w, h)
    buf  = element(e).pixmap
    info = sk_imageinfo_t(C_NULL, w, h, BGRA_8888_SK_COLORTYPE, PREMUL_SK_ALPHATYPE)
    surface = sk_surface_new_raster_direct(Ref(info), buf, w * 4, C_NULL, C_NULL, C_NULL)
    canvas  = sk_surface_get_canvas(surface)
    if e.background >>> 24 != 0
        bgpaint = sk_paint_new()
        sk_paint_set_color(bgpaint, e.background)
        sk_canvas_draw_paint(canvas, bgpaint)
        sk_paint_delete(bgpaint)
    end
    dst = sk_rect_t(0f0, 0f0, Float32(w), Float32(h))
    sk_canvas_draw_image_nine(canvas, e.skimage, Ref(e.center), Ref(dst), LINEAR_SK_FILTER_MODE, C_NULL)
    sk_surface_unref(surface)
end
