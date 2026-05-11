
import SDL2_jll: libsdl2
import .GC.@preserve

# ── SDL2 constants ────────────────────────────────────────────────────────────

const SDL_INIT_VIDEO = UInt32(0x00000020)

const SDL_WINDOWPOS_CENTERED = Int32(0x2FFF0000)
const SDL_WINDOW_SHOWN       = UInt32(0x00000004)
const SDL_WINDOW_RESIZABLE   = UInt32(0x00000020)

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
    width::Int32
    height::Int32
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

function createSDLHost(title::String, w::Int, h::Int)::SDLHost
    @ccall(libsdl2.SDL_Init(SDL_INIT_VIDEO::UInt32)::Cint) < 0 &&
        error("SDL_Init: $(unsafe_string(@ccall libsdl2.SDL_GetError()::Cstring))")
    window = @ccall libsdl2.SDL_CreateWindow(
        title::Cstring,
        SDL_WINDOWPOS_CENTERED::Int32, SDL_WINDOWPOS_CENTERED::Int32,
        Int32(w)::Int32, Int32(h)::Int32,
        (SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE)::UInt32)::Ptr{Cvoid}
    window == C_NULL &&
        error("SDL_CreateWindow: $(unsafe_string(@ccall libsdl2.SDL_GetError()::Cstring))")
    renderer = @ccall libsdl2.SDL_CreateRenderer(window::Ptr{Cvoid}, Int32(-1)::Int32, UInt32(0)::UInt32)::Ptr{Cvoid}
    renderer == C_NULL &&
        error("SDL_CreateRenderer: $(unsafe_string(@ccall libsdl2.SDL_GetError()::Cstring))")
    return SDLHost(window, renderer, Int32(w), Int32(h))
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
    pixmap = paint(eh.el, eh.width, eh.height)
    pixmap === nothing && return

    pw, ph = Int32.(size(pixmap))
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

    dst = Int32[eh.x, eh.y, eh.width, eh.height]
    @preserve dst @ccall libsdl2.SDL_RenderCopy(
        eh.host.renderer::Ptr{Cvoid}, eh.texture::Ptr{Cvoid},
        C_NULL::Ptr{Cvoid}, Ptr{Cvoid}(pointer(dst))::Ptr{Cvoid})::Cint
end

function renderAll(host::SDLHost)
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

function sdlEventLoop(host::SDLHost, onResize::Function)
    ev = new_event()
    while GC.@preserve(ev, @ccall(libsdl2.SDL_WaitEvent(
                Base.unsafe_convert(Ptr{SDL_EventBuffer}, ev)::Ptr{Cvoid})::Cint)) != 0
        etype = event_type(ev)
        if etype == SDL_QUIT
            break
        elseif etype == SDL_WINDOWEVENT
            we = as_window_event(ev)
            if we.event == SDL_WINDOWEVENT_SIZE_CHANGED
                host.width, host.height = we.data1, we.data2
                onResize(host, we.data1, we.data2)
                renderAll(host)
            elseif we.event == SDL_WINDOWEVENT_EXPOSED
                renderAll(host)
            end
        elseif etype == SDL_MOUSEBUTTONDOWN
            mb = as_mouse_button(ev)
            if mb.button == SDL_BUTTON_LEFT
                eh = hitTest(host, mb.x, mb.y)
                eh !== nothing && press(eh.el)
                renderAll(host)
            end
        elseif etype == SDL_MOUSEBUTTONUP
            mb = as_mouse_button(ev)
            if mb.button == SDL_BUTTON_LEFT
                eh = hitTest(host, mb.x, mb.y)
                eh !== nothing && click(eh.el)
                renderAll(host)
            end
        elseif etype == SDL_USEREVENT
            renderAll(host)
        end
    end
end
