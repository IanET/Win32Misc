@info "NineSliceTest (SDL2)"

include("../common/LibSkia.jl")
using .LibSkia

include("Layout.jl")
include("Elements.jl")
include("SDLElementHost.jl")
include("NineSliceImage.jl")

import .GC.@preserve

const GAP = -1
const IDC_NINESLICE = 1

_layout = GridLayout(
    [GAP  GAP           GAP
     GAP  IDC_NINESLICE GAP
     GAP  GAP           GAP],
    [10, ★"1", 10],
    [10, ★"1", 10])

function onCreate(host::SDLHost)
    nine = NineSliceImage("assets/panel.png")
    nine.background = 0xFF000000
    createSDLElementHost(host, nine, IDC_NINESLICE, 10, 10, host.width - 20, host.height - 20)
end

function onResize(host::SDLHost, w::Int32, h::Int32)
    w > 0 && h > 0 && layout(host, _layout)
end

function main()
    @info "UI Begin"

    host = createSDLHost("NineSlice Test", 512, 512)
    onCreate(host)
    layout(host, _layout)
    renderAll(host)

    sdlEventLoop(host, onResize)

    destroySDLHost(host)
    @info "UI End"
end

main()
