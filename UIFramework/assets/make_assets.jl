using PNGFiles
using ColorTypes
using FixedPointNumbers

n0(v::Integer) = reinterpret(N0f8, UInt8(v))

const CLEAR = RGBA{N0f8}(n0(0x00), n0(0x00), n0(0x00), n0(0x00))

# cx, cy are pixel centres in image space (0,0)..(W,H)
function inside_rrect(cx, cy, x0, y0, x1, y1, r)
    cx >= x0 && cx <= x1 && cy >= y0 && cy <= y1 || return false
    lx = cx - x0; ly = cy - y0
    w  = x1 - x0; h  = y1 - y0
    if     lx < r && ly < r         ; return (lx - r)^2       + (ly - r)^2       <= r^2
    elseif lx > w - r && ly < r     ; return (lx - (w - r))^2 + (ly - r)^2       <= r^2
    elseif lx < r && ly > h - r     ; return (lx - r)^2       + (ly - (h - r))^2 <= r^2
    elseif lx > w - r && ly > h - r ; return (lx - (w - r))^2 + (ly - (h - r))^2 <= r^2
    end
    true
end

# CRC-32 (ISO 3309) for PNG chunks
const CRC_TABLE = let
    t = zeros(UInt32, 256)
    for n in 0:255
        c = UInt32(n)
        for _ in 1:8
            c = isodd(c) ? 0xedb88320 ⊻ (c >>> 1) : c >>> 1
        end
        t[n+1] = c
    end
    t
end

function crc32(data)
    c = 0xffffffff
    for b in data
        c = CRC_TABLE[((c ⊻ UInt32(b)) & 0xff) + 1] ⊻ (c >>> 8)
    end
    c ⊻ 0xffffffff
end

function png_text_chunk(key::String, value::String)
    payload = Vector{UInt8}(key * "\0" * value)
    type    = Vector{UInt8}("tEXt")
    crc     = crc32(vcat(type, payload))
    vcat(
        reinterpret(UInt8, [hton(UInt32(length(payload)))]),
        type,
        payload,
        reinterpret(UInt8, [hton(crc)])
    )
end

function inject_png_text!(path::String, key::String, value::String)
    data = read(path)
    chunk = png_text_chunk(key, value)
    write(path, vcat(data[1:33], chunk, data[34:end]))
end

function make_rrect_png(path, W, H, R, B, fill::RGBA{N0f8}, border::RGBA{N0f8})
    img = Matrix{RGBA{N0f8}}(undef, H, W)
    for row in 1:H, col in 1:W
        cx = col - 0.5; cy = row - 0.5
        outer = inside_rrect(cx, cy, 0.0, 0.0, Float64(W), Float64(H), Float64(R))
        inner = inside_rrect(cx, cy, Float64(B), Float64(B), Float64(W-B), Float64(H-B), Float64(R-B))
        img[row, col] = !outer ? CLEAR : !inner ? border : fill
    end
    PNGFiles.save(path, img)
    inject_png_text!(path, "9slice", "$R $R $(W-R) $(H-R)")
    @info "Written $path  9slice = $R $R $(W-R) $(H-R)"
end

function make_diamonds_png(path, W, H, border)
    img = Matrix{RGBA{N0f8}}(undef, H, W)
    fill_c   = RGBA{N0f8}(n0(0xe8), n0(0xf0), n0(0xff), n0(0xff))  # pale blue center
    border_c = RGBA{N0f8}(n0(0x20), n0(0x60), n0(0xc0), n0(0xff))  # blue diamond
    bg_c     = RGBA{N0f8}(n0(0xd0), n0(0xe4), n0(0xff), n0(0xff))  # lighter blue bg
    tile     = border  # one diamond per border width
    for row in 1:H, col in 1:W
        in_center = col > border && col <= W - border && row > border && row <= H - border
        if in_center
            img[row, col] = fill_c
        else
            # diamond pattern: |dx| + |dy| < half_tile
            dx = (col - 1) % tile - tile ÷ 2
            dy = (row - 1) % tile - tile ÷ 2
            img[row, col] = (abs(dx) + abs(dy)) < tile ÷ 2 ? border_c : bg_c
        end
    end
    PNGFiles.save(path, img)
    @info "Written $path  (no 9slice metadata — border must be supplied by caller)"
end

mkpath("assets")

make_diamonds_png("assets/border-diamonds.png", 120, 120, 30)

make_rrect_png(
    "assets/button.png", 32, 32, 8, 1,
    RGBA{N0f8}(n0(0xe1), n0(0xe1), n0(0xe1), n0(0xff)),   # light gray fill
    RGBA{N0f8}(n0(0xad), n0(0xad), n0(0xad), n0(0xff)))   # gray border

make_rrect_png(
    "assets/panel.png", 40, 40, 12, 5,
    RGBA{N0f8}(n0(0xc0), n0(0xd8), n0(0xff), n0(0xff)),   # opaque blue fill
    RGBA{N0f8}(n0(0x40), n0(0x70), n0(0xc0), n0(0xff)))   # opaque blue border
