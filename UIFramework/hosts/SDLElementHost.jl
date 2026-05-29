
import SDL2_jll: libsdl2
import .GC.@preserve

# ── SDL2 constants ────────────────────────────────────────────────────────────

const SDL_INIT_VIDEO = UInt32(0x00000020)

const SDL_WINDOWPOS_CENTERED = Int32(0x2FFF0000)
const SDL_WINDOW_SHOWN        = UInt32(0x00000004)
const SDL_WINDOW_RESIZABLE    = UInt32(0x00000020)
const SDL_WINDOW_ALLOW_HIGHDPI = UInt32(0x00002000)

# Matches Skia BGRA_8888 memory layout on little-endian (B G R A bytes = ARGB packed int)
const SDL_PIXELFORMAT_ARGB8888    = UInt32(0x16362004)
const SDL_TEXTUREACCESS_STREAMING = Int32(1)

const SDL_QUIT            = UInt32(0x100)
const SDL_WINDOWEVENT     = UInt32(0x200)
const SDL_MOUSEBUTTONDOWN = UInt32(0x401)
const SDL_MOUSEBUTTONUP   = UInt32(0x402)
const SDL_USEREVENT       = UInt32(0x8000)

const SDL_WINDOWEVENT_EXPOSED      = UInt8(3)
const SDL_WINDOWEVENT_SIZE_CHANGED = UInt8(6)

const SDL_BUTTON_LEFT = UInt8(1)

# ── SDL2 event structs (layout matches SDL2 headers exactly) ──────────────────

struct SDL_WindowEvent
    type::UInt32
    timestamp::UInt32
    windowID::UInt32
    event::UInt8
    padding1::UInt8
    padding2::UInt8
    padding3::UInt8
    data1::Int32
    data2::Int32
end

struct SDL_MouseButtonEvent
    type::UInt32
    timestamp::UInt32
    windowID::UInt32
    which::UInt32
    button::UInt8
    state::UInt8
    clicks::UInt8
    padding1::UInt8
    x::Int32
    y::Int32
end

# SDL_Event is a 56-byte union; receive it as 14 × UInt32
const SDL_EventBuffer = NTuple{14, UInt32}

new_event() = Ref{SDL_EventBuffer}(ntuple(_ -> UInt32(0), 14))

event_type(ev::Ref{SDL_EventBuffer})::UInt32 = ev[][1]

function as_window_event(ev::Ref{SDL_EventBuffer})::SDL_WindowEvent
    GC.@preserve ev unsafe_load(Ptr{SDL_WindowEvent}(Base.unsafe_convert(Ptr{SDL_EventBuffer}, ev)))
end

function as_mouse_button(ev::Ref{SDL_EventBuffer})::SDL_MouseButtonEvent
    GC.@preserve ev unsafe_load(Ptr{SDL_MouseButtonEvent}(Base.unsafe_convert(Ptr{SDL_EventBuffer}, ev)))
end

function push_repaint_event()
    ev = Ref{SDL_EventBuffer}(ntuple(i -> i == 1 ? SDL_USEREVENT : UInt32(0), 14))
    GC.@preserve ev @ccall libsdl2.SDL_PushEvent(
        Base.unsafe_convert(Ptr{SDL_EventBuffer}, ev)::Ptr{Cvoid})::Cint
end

# ── Host structs ──────────────────────────────────────────────────────────────

mutable struct SDLHost
    window::Ptr{Cvoid}
    renderer::Ptr{Cvoid}
    width::Int32         # logical pixels
    height::Int32        # logical pixels
    scale::Float32       # physical / logical pixel ratio
    sdl_physical::Bool   # true = SDL window/event coords are physical (X11 + manual DPI scaling)
                         # false = SDL manages the split internally (macOS ALLOW_HIGHDPI)
end

mutable struct SDLElementHost
    host::SDLHost
    el::AbstractElement
    texture::Ptr{Cvoid}
    tex_w::Int32
    tex_h::Int32
    x::Int32
    y::Int32
    width::Int32
    height::Int32
end

const _sdl_hosts = Dict{Int, SDLElementHost}()

# ── Lifecycle ─────────────────────────────────────────────────────────────────

function _detect_dpi_scale()::Float32
    # 1. SDL_GetDisplayDPI — reliable on Wayland; returns noise (~96.003) on X11
    ddpi = Ref{Cfloat}(0f0)
    if @ccall(libsdl2.SDL_GetDisplayDPI(Int32(0)::Int32, ddpi::Ptr{Cfloat},
                C_NULL::Ptr{Cfloat}, C_NULL::Ptr{Cfloat})::Cint) == 0
        s = ddpi[] / 96f0
        s >= 1.1f0 && return s
    end
    # 2. Xft.dpi from X resources — GNOME/KDE set this to 96*scale on X11
    try
        for line in split(readchomp(`xrdb -query`), '\n')
            if startswith(line, "Xft.dpi:")
                s = parse(Float32, strip(split(line, ':')[2])) / 96f0
                s >= 1.1f0 && return s
            end
        end
    catch; end
    # 3. GNOME gsettings scaling-factor
    try
        s = parse(Float32, strip(readchomp(`gsettings get org.gnome.desktop.interface scaling-factor`)))
        s >= 1.1f0 && return s
    catch; end
    # 4. Compositor env vars set manually or by some DEs
    for key in ("GDK_SCALE", "QT_SCALE_FACTOR")
        val = get(ENV, key, "")
        isempty(val) && continue
        try; s = parse(Float32, val); s >= 1.1f0 && return s; catch; end
    end
    return 1f0
end

function createSDLHost(title::String, w::Int, h::Int)::SDLHost
    @ccall(libsdl2.SDL_Init(SDL_INIT_VIDEO::UInt32)::Cint) < 0 &&
        error("SDL_Init: $(unsafe_string(@ccall libsdl2.SDL_GetError()::Cstring))")
    window = @ccall libsdl2.SDL_CreateWindow(
        title::Cstring,
        SDL_WINDOWPOS_CENTERED::Int32, SDL_WINDOWPOS_CENTERED::Int32,
        Int32(w)::Int32, Int32(h)::Int32,
        (SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI)::UInt32)::Ptr{Cvoid}
    window == C_NULL &&
        error("SDL_CreateWindow: $(unsafe_string(@ccall libsdl2.SDL_GetError()::Cstring))")
    renderer = @ccall libsdl2.SDL_CreateRenderer(window::Ptr{Cvoid}, Int32(-1)::Int32, UInt32(0)::UInt32)::Ptr{Cvoid}
    renderer == C_NULL &&
        error("SDL_CreateRenderer: $(unsafe_string(@ccall libsdl2.SDL_GetError()::Cstring))")

    rw = Ref{Cint}(0)
    @ccall libsdl2.SDL_GetRendererOutputSize(renderer::Ptr{Cvoid}, rw::Ptr{Cint}, C_NULL::Ptr{Cint})::Cint
    scale = Float32(rw[]) / Float32(w)
    sdl_physical = false

    if scale ≈ 1f0
        # SDL didn't handle HiDPI (X11 with software renderer). Detect scale manually
        # and resize the window to physical pixels so it appears at the right size.
        scale = _detect_dpi_scale()
        if scale > 1f0
            phys_w = round(Int32, w * scale)
            phys_h = round(Int32, h * scale)
            @ccall libsdl2.SDL_SetWindowSize(window::Ptr{Cvoid}, phys_w::Int32, phys_h::Int32)::Cvoid
            sdl_physical = true
        end
    end

    @info "DPI scale: $scale"
    return SDLHost(window, renderer, Int32(w), Int32(h), scale, sdl_physical)
end

function _update_scale!(host::SDLHost)
    rw, rh = Ref{Cint}(0), Ref{Cint}(0)
    ww, wh = Ref{Cint}(0), Ref{Cint}(0)
    @ccall libsdl2.SDL_GetRendererOutputSize(host.renderer::Ptr{Cvoid}, rw::Ptr{Cint}, rh::Ptr{Cint})::Cint
    @ccall libsdl2.SDL_GetWindowSize(host.window::Ptr{Cvoid}, ww::Ptr{Cint}, wh::Ptr{Cint})::Cint
    if rw[] != ww[]
        # macOS with ALLOW_HIGHDPI: SDL window size is in logical points
        host.width  = Int32(ww[])
        host.height = Int32(wh[])
        host.scale  = Float32(rw[]) / Float32(ww[])
    else
        # X11: window and renderer both in physical pixels; scale stays from DPI detection
        host.width  = round(Int32, ww[] / host.scale)
        host.height = round(Int32, wh[] / host.scale)
    end
end

function createSDLElementHost(host::SDLHost, e::AbstractElement, id::Int, x::Int, y::Int, w::Int, h::Int)
    eh = SDLElementHost(host, e, C_NULL, Int32(0), Int32(0), Int32(x), Int32(y), Int32(w), Int32(h))
    _sdl_hosts[id] = eh
    element(e).repaint = () -> push_repaint_event()
    return eh
end

function destroySDLHost(host::SDLHost)
    for (_, eh) in _sdl_hosts
        eh.host === host || continue
        eh.texture != C_NULL && @ccall libsdl2.SDL_DestroyTexture(eh.texture::Ptr{Cvoid})::Cvoid
    end
    @ccall libsdl2.SDL_DestroyRenderer(host.renderer::Ptr{Cvoid})::Cvoid
    @ccall libsdl2.SDL_DestroyWindow(host.window::Ptr{Cvoid})::Cvoid
    @ccall libsdl2.SDL_Quit()::Cvoid
end

# ── Layout ────────────────────────────────────────────────────────────────────

function layout(host::SDLHost, gl::GridLayout)
    rects = computeLayout(Int(host.width), Int(host.height), gl)
    for (id, (x, y, w, h)) in rects
        haskey(_sdl_hosts, id) || continue
        eh = _sdl_hosts[id]
        old_w, old_h = Int(eh.width), Int(eh.height)
        eh.x, eh.y, eh.width, eh.height = Int32(x), Int32(y), Int32(w), Int32(h)
        if w > 0 && h > 0 && (old_w != w || old_h != h)
            resize(eh.el, w, h)
        end
    end
end

# ── Rendering ─────────────────────────────────────────────────────────────────

function renderElement(eh::SDLElementHost)
    (eh.width <= 0 || eh.height <= 0) && return
    scale = eh.host.scale
    pixmap = paint(eh.el, eh.width, eh.height, scale)
    pixmap === nothing && return

    pw, ph = Int32.(size(pixmap))  # physical pixel dimensions
    if eh.texture == C_NULL || eh.tex_w != pw || eh.tex_h != ph
        eh.texture != C_NULL && @ccall libsdl2.SDL_DestroyTexture(eh.texture::Ptr{Cvoid})::Cvoid
        eh.texture = @ccall libsdl2.SDL_CreateTexture(
            eh.host.renderer::Ptr{Cvoid},
            SDL_PIXELFORMAT_ARGB8888::UInt32,
            SDL_TEXTUREACCESS_STREAMING::Int32,
            pw::Int32, ph::Int32)::Ptr{Cvoid}
        eh.tex_w, eh.tex_h = pw, ph
    end

    @preserve pixmap @ccall libsdl2.SDL_UpdateTexture(
        eh.texture::Ptr{Cvoid}, C_NULL::Ptr{Cvoid},
        Ptr{Cvoid}(pointer(pixmap))::Ptr{Cvoid},
        (pw * Int32(4))::Int32)::Cint

    px, py = round(Int32, eh.x * scale), round(Int32, eh.y * scale)
    dst = Int32[px, py, pw, ph]
    @preserve dst @ccall libsdl2.SDL_RenderCopy(
        eh.host.renderer::Ptr{Cvoid}, eh.texture::Ptr{Cvoid},
        C_NULL::Ptr{Cvoid}, Ptr{Cvoid}(pointer(dst))::Ptr{Cvoid})::Cint
end

function renderAll(host::SDLHost)
    @ccall libsdl2.SDL_SetRenderDrawColor(host.renderer::Ptr{Cvoid}, UInt8(255)::UInt8, UInt8(255)::UInt8, UInt8(255)::UInt8, UInt8(255)::UInt8)::Cint
    @ccall libsdl2.SDL_RenderClear(host.renderer::Ptr{Cvoid})::Cint
    for (_, eh) in _sdl_hosts
        eh.host === host && renderElement(eh)
    end
    @ccall libsdl2.SDL_RenderPresent(host.renderer::Ptr{Cvoid})::Cvoid
end

# ── Input ─────────────────────────────────────────────────────────────────────

function hitTest(host::SDLHost, x::Int32, y::Int32)::Union{SDLElementHost, Nothing}
    for (_, eh) in _sdl_hosts
        eh.host === host || continue
        x >= eh.x && x < eh.x + eh.width && y >= eh.y && y < eh.y + eh.height && return eh
    end
    return nothing
end

# ── Event loop ────────────────────────────────────────────────────────────────

# Storage for the live-resize watch callback (SDL_AddEventWatch fires even
# during the OS resize modal loop, unlike SDL_WaitEvent which is blocked).
const _watch_host     = Ref{Union{SDLHost, Nothing}}(nothing)
const _watch_onResize = Ref{Union{Function, Nothing}}(nothing)

function _resize_watch_cb(::Ptr{Cvoid}, event::Ptr{Cvoid})::Cint
    host = _watch_host[]
    host === nothing && return 0
    unsafe_load(Ptr{UInt32}(event)) == SDL_WINDOWEVENT || return 0
    we = unsafe_load(Ptr{SDL_WindowEvent}(event))
    we.event == SDL_WINDOWEVENT_SIZE_CHANGED || return 0
    _update_scale!(host)
    _watch_onResize[](host, we.data1, we.data2)
    renderAll(host)
    return 0
end

const _resize_watch_cfunc = @cfunction(_resize_watch_cb, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))

function sdlEventLoop(host::SDLHost, onResize::Function)
    _watch_host[]     = host
    _watch_onResize[] = onResize
    @ccall libsdl2.SDL_AddEventWatch(_resize_watch_cfunc::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::Cvoid

    ev = new_event()
    while GC.@preserve(ev, @ccall(libsdl2.SDL_WaitEvent(
                Base.unsafe_convert(Ptr{SDL_EventBuffer}, ev)::Ptr{Cvoid})::Cint)) != 0
        etype = event_type(ev)
        if etype == SDL_QUIT
            break
        elseif etype == SDL_WINDOWEVENT
            we = as_window_event(ev)
            if we.event == SDL_WINDOWEVENT_SIZE_CHANGED
                _update_scale!(host)
                onResize(host, we.data1, we.data2)
                renderAll(host)
            elseif we.event == SDL_WINDOWEVENT_EXPOSED
                renderAll(host)
            end
        elseif etype == SDL_MOUSEBUTTONDOWN
            mb = as_mouse_button(ev)
            if mb.button == SDL_BUTTON_LEFT
                lx = host.sdl_physical ? round(Int32, mb.x / host.scale) : mb.x
                ly = host.sdl_physical ? round(Int32, mb.y / host.scale) : mb.y
                eh = hitTest(host, lx, ly)
                eh !== nothing && press(eh.el)
                renderAll(host)
            end
        elseif etype == SDL_MOUSEBUTTONUP
            mb = as_mouse_button(ev)
            if mb.button == SDL_BUTTON_LEFT
                lx = host.sdl_physical ? round(Int32, mb.x / host.scale) : mb.x
                ly = host.sdl_physical ? round(Int32, mb.y / host.scale) : mb.y
                eh = hitTest(host, lx, ly)
                eh !== nothing && click(eh.el)
                renderAll(host)
            end
        elseif etype == SDL_USEREVENT
            renderAll(host)
        end
    end

    @ccall libsdl2.SDL_DelEventWatch(_resize_watch_cfunc::Ptr{Cvoid}, C_NULL::Ptr{Cvoid})::Cvoid
    _watch_host[]     = nothing
    _watch_onResize[] = nothing
end
