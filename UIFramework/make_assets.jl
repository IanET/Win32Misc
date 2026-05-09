using PNGFiles
using ColorTypes
using FixedPointNumbers

const W = 32
const H = 32
const R = 8   # corner radius
const B = 1   # border width

n0(v::Integer) = reinterpret(N0f8, UInt8(v))

const FILL   = RGBA{N0f8}(n0(0xe1), n0(0xe1), n0(0xe1), n0(0xff))
const BORDER = RGBA{N0f8}(n0(0xad), n0(0xad), n0(0xad), n0(0xff))
const CLEAR  = RGBA{N0f8}(n0(0x00), n0(0x00), n0(0x00), n0(0x00))

# cx, cy are pixel centres in image space (0,0)..(W,H)
function inside_rrect(cx, cy, x0, y0, x1, y1, r)
    cx >= x0 && cx <= x1 && cy >= y0 && cy <= y1 || return false
    lx = cx - x0; ly = cy - y0
    w  = x1 - x0; h  = y1 - y0
    if     lx < r && ly < r         ; return (lx - r)^2     + (ly - r)^2     <= r^2
    elseif lx > w - r && ly < r     ; return (lx - (w - r))^2 + (ly - r)^2   <= r^2
    elseif lx < r && ly > h - r     ; return (lx - r)^2     + (ly - (h - r))^2 <= r^2
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
    # Insert after PNG signature (8) + IHDR chunk (25) = offset 33
    chunk = png_text_chunk(key, value)
    write(path, vcat(data[1:33], chunk, data[34:end]))
end

# Build pixel data
img = Matrix{RGBA{N0f8}}(undef, H, W)
for row in 1:H, col in 1:W
    cx = col - 0.5; cy = row - 0.5
    outer = inside_rrect(cx, cy, 0.0, 0.0, Float64(W), Float64(H), Float64(R))
    inner = inside_rrect(cx, cy, Float64(B), Float64(B), Float64(W-B), Float64(H-B), Float64(R-B))
    img[row, col] = !outer ? CLEAR : !inner ? BORDER : FILL
end

mkpath("assets")
outpath = joinpath("assets", "button.png")
PNGFiles.save(outpath, img)

inject_png_text!(outpath, "9slice", "$R $R $(W-R) $(H-R)")
@info "Written $outpath  9slice = $R $R $(W-R) $(H-R)"
