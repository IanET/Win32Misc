@info "BorderRepeatTest (SDL2)"

include("../../common/LibSkia.jl")
using .LibSkia

include("../framework/Layout.jl")
include("../framework/Elements.jl")
include("../hosts/SDLElementHost.jl")
include("../framework/NineSliceImage.jl")

import .GC.@preserve

const GAP = -1

# 4×4 grid — columns: repeat_h (Stretch, Repeat, Round, Space)
#             rows:    repeat_v (Stretch, Repeat, Round, Space)
_layout = GridLayout(
    [
        GAP  GAP   GAP  GAP   GAP  GAP   GAP  GAP   GAP
        GAP   1    GAP   2    GAP   3    GAP   4    GAP
        GAP  GAP   GAP  GAP   GAP  GAP   GAP  GAP   GAP
        GAP   5    GAP   6    GAP   7    GAP   8    GAP
        GAP  GAP   GAP  GAP   GAP  GAP   GAP  GAP   GAP
        GAP   9    GAP  10    GAP  11    GAP  12    GAP
        GAP  GAP   GAP  GAP   GAP  GAP   GAP  GAP   GAP
        GAP  13    GAP  14    GAP  15    GAP  16    GAP
        GAP  GAP   GAP  GAP   GAP  GAP   GAP  GAP   GAP
    ],
    [5, ★"1", 5, ★"1", 5, ★"1", 5, ★"1", 5],
    [5, ★"1", 5, ★"1", 5, ★"1", 5, ★"1", 5])

const BORDER_MODES = (Stretch, Repeat, Round, Space)

function onCreate(host::SDLHost)
    asset = joinpath(@__DIR__, "..", "assets", "border-diamonds.png")
    h, w = size(PNGFiles.load(asset))
    border = sk_irect_t(Int32(30), Int32(30), Int32(w - 30), Int32(h - 30))
    id = 1
    for rv in BORDER_MODES
        for rh in BORDER_MODES
            nine = NineSliceImage(asset; border)
            nine.repeat_h = rh
            nine.repeat_v = rv
            createSDLElementHost(host, nine, id, 0, 0, 100, 100)
            id += 1
        end
    end
end

function onResize(host::SDLHost, w::Int32, h::Int32)
    w > 0 && h > 0 && layout(host, _layout)
end

function main()
    @info "UI Begin"

    host = createSDLHost("Border Repeat Test", 800, 600)
    onCreate(host)
    layout(host, _layout)
    renderAll(host)

    sdlEventLoop(host, onResize)

    destroySDLHost(host)
    @info "UI End"
end

main()
