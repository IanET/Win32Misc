
using HTTP
import PNGFiles
using ColorTypes
using FixedPointNumbers

# ── HTML client ───────────────────────────────────────────────────────────────
# Each element gets its own absolutely-positioned <canvas> so only changed
# elements need a new frame — no full-viewport encode on every repaint.

const _HTTP_HTML = """
<!DOCTYPE html><html>
<head><style>*{margin:0;padding:0}body{background:#c7c7c7;overflow:hidden}canvas{position:absolute}</style></head>
<body><script>
const ws = new WebSocket("ws://" + location.host + "/ws");
ws.binaryType = "arraybuffer";
const canvases = {};

function canvas_for(id) {
    if (canvases[id]) return canvases[id];
    const c = document.createElement("canvas");
    document.body.appendChild(c);
    canvases[id] = c;
    c.addEventListener("mousedown", ev => {
        const r = c.getBoundingClientRect();
        ws.send(JSON.stringify({type:"mousedown",id,x:Math.floor(ev.clientX-r.left),y:Math.floor(ev.clientY-r.top)}));
    });
    c.addEventListener("mouseup", ev => {
        const r = c.getBoundingClientRect();
        ws.send(JSON.stringify({type:"mouseup",id,x:Math.floor(ev.clientX-r.left),y:Math.floor(ev.clientY-r.top)}));
    });
    return c;
}

ws.onmessage = ev => {
    if (typeof ev.data === "string") {
        const m = JSON.parse(ev.data);
        if (m.type === "layout") {
            const c = canvas_for(m.id);
            Object.assign(c.style, {left:m.x+"px", top:m.y+"px"});
            c.width = m.w; c.height = m.h;
        }
    } else {
        const dv = new DataView(ev.data);
        const id = dv.getUint32(0, true);
        const blob = new Blob([new Uint8Array(ev.data, 4)], {type:"image/png"});
        createImageBitmap(blob).then(bmp => { canvases[id]?.getContext("2d").drawImage(bmp, 0, 0); });
    }
};

ws.onopen = () => {
    const report = () => ws.readyState === 1 &&
        ws.send(JSON.stringify({type:"resize",w:window.innerWidth,h:window.innerHeight}));
    window.addEventListener("resize", report);
    report();
};
</script></body></html>
"""

# ── Host structs ──────────────────────────────────────────────────────────────

mutable struct HTTPHost
    port::Int
    width::Int32
    height::Int32
    clients::Vector{HTTP.WebSockets.WebSocket}
    dirty_channel::Channel{Int}
end

mutable struct HTTPElementHost
    host::HTTPHost
    el::AbstractElement
    id::Int
    x::Int32
    y::Int32
    width::Int32
    height::Int32
    last_png::Union{Vector{UInt8}, Nothing}
end

const _http_hosts = Dict{Int, HTTPElementHost}()

# ── Lifecycle ─────────────────────────────────────────────────────────────────

function createHTTPHost(port::Int, w::Int, h::Int)::HTTPHost
    return HTTPHost(port, Int32(w), Int32(h), HTTP.WebSockets.WebSocket[], Channel{Int}(64))
end

function createHTTPElementHost(host::HTTPHost, e::AbstractElement, id::Int, x::Int, y::Int, w::Int, h::Int)
    eh = HTTPElementHost(host, e, id, Int32(x), Int32(y), Int32(w), Int32(h), nothing)
    _http_hosts[id] = eh
    element(e).repaint = () -> try
        put!(host.dirty_channel, id)
    catch e
        @info "repaint error id=$id: $e"
    end
    return eh
end

function destroyHTTPHost(host::HTTPHost)
    filter!(kv -> kv[2].host !== host, _http_hosts)
    close(host.dirty_channel)
end

# ── Layout ────────────────────────────────────────────────────────────────────

function layout(host::HTTPHost, gl::GridLayout)
    rects = computeLayout(Int(host.width), Int(host.height), gl)
    for (id, (x, y, w, h)) in rects
        haskey(_http_hosts, id) || continue
        eh = _http_hosts[id]
        old_w, old_h = Int(eh.width), Int(eh.height)
        eh.x, eh.y, eh.width, eh.height = Int32(x), Int32(y), Int32(w), Int32(h)
        if w > 0 && h > 0 && (old_w != w || old_h != h)
            resize(eh.el, w, h)
        end
    end
end

# ── Rendering ─────────────────────────────────────────────────────────────────

# Skia BGRA_8888: pixel UInt32 bytes = B G R A. Convert to RGBA for PNG.
function _encode_png(pixmap::Matrix{UInt32})::Vector{UInt8}
    w, h = size(pixmap)
    img = Matrix{RGBA{N0f8}}(undef, h, w)
    @inbounds for y in 1:h, x in 1:w
        px = pixmap[x, y]
        img[y, x] = RGBA{N0f8}(
            reinterpret(N0f8, UInt8((px >> 16) & 0xFF)),
            reinterpret(N0f8, UInt8((px >>  8) & 0xFF)),
            reinterpret(N0f8, UInt8( px        & 0xFF)),
            reinterpret(N0f8, UInt8((px >> 24) & 0xFF)))
    end
    buf = IOBuffer()
    PNGFiles.save(buf, img)
    return take!(buf)
end

function _ws_send_layout(ws, eh::HTTPElementHost)
    HTTP.WebSockets.send(ws,
        """{"type":"layout","id":$(eh.id),"x":$(eh.x),"y":$(eh.y),"w":$(eh.width),"h":$(eh.height)}""")
end

function _ws_send_frame(ws, id::Int, png::Vector{UInt8})
    frame = Vector{UInt8}(undef, 4 + length(png))
    frame[1] = UInt8( id        & 0xFF)
    frame[2] = UInt8((id >>  8) & 0xFF)
    frame[3] = UInt8((id >> 16) & 0xFF)
    frame[4] = UInt8((id >> 24) & 0xFF)
    copyto!(frame, 5, png, 1, length(png))
    HTTP.WebSockets.send(ws, frame)
end

function _broadcast(host::HTTPHost, f::Function)
    dead = Int[]
    for (i, ws) in enumerate(host.clients)
        try; f(ws); catch; push!(dead, i); end
    end
    deleteat!(host.clients, dead)
end

function renderElement(eh::HTTPElementHost)
    (eh.width <= 0 || eh.height <= 0) && return
    pixmap = paint(eh.el, eh.width, eh.height)
    pixmap === nothing && return
    png = _encode_png(pixmap)
    eh.last_png = png
    _broadcast(eh.host, ws -> _ws_send_frame(ws, eh.id, png))
end

function renderAll(host::HTTPHost)
    for (_, eh) in _http_hosts
        eh.host === host || continue
        _broadcast(host, ws -> _ws_send_layout(ws, eh))
        renderElement(eh)
    end
end

# ── Input ─────────────────────────────────────────────────────────────────────

function _parse_msg(s::AbstractString)
    tm = match(r"\"type\"\s*:\s*\"(\w+)\"", s)
    tm === nothing && return nothing
    nums = Dict{String, Int}()
    for m in eachmatch(r"\"(\w+)\"\s*:\s*(\d+)", s)
        nums[m[1]] = parse(Int, m[2])
    end
    return (type=tm[1], nums=nums)
end

function _handle_client_msg(host::HTTPHost, msg, onResize::Function)
    msg isa String || return
    parsed = _parse_msg(msg)
    parsed === nothing && return
    if parsed.type == "resize"
        w = get(parsed.nums, "w", 0)
        h = get(parsed.nums, "h", 0)
        w > 0 && h > 0 || return
        host.width, host.height = Int32(w), Int32(h)
        onResize(host, Int32(w), Int32(h))
        put!(host.dirty_channel, 0)
    elseif parsed.type == "mousedown"
        id = get(parsed.nums, "id", -1)
        haskey(_http_hosts, id) || return
        eh = _http_hosts[id]
        eh.host === host || return
        press(eh.el)
    elseif parsed.type == "mouseup"
        id = get(parsed.nums, "id", -1)
        haskey(_http_hosts, id) || return
        eh = _http_hosts[id]
        eh.host === host || return
        click(eh.el)
    end
end

# ── Event loop ────────────────────────────────────────────────────────────────

function httpEventLoop(host::HTTPHost, onResize::Function)
    @async try
        HTTP.listen("0.0.0.0", host.port) do http
            if HTTP.WebSockets.isupgrade(http.message)
                HTTP.WebSockets.upgrade(http) do ws
                    push!(host.clients, ws)
                    try
                        for (_, eh) in _http_hosts
                            eh.host === host || continue
                            _ws_send_layout(ws, eh)
                            eh.last_png !== nothing && _ws_send_frame(ws, eh.id, eh.last_png)
                        end
                        for msg in ws
                            _handle_client_msg(host, msg, onResize)
                        end
                    catch e
                        @info "ws handler error: $e"
                    end
                    filter!(c -> c !== ws, host.clients)
                end
            else
                HTTP.setstatus(http, 200)
                HTTP.setheader(http, "Content-Type" => "text/html; charset=utf-8")
                HTTP.startwrite(http)
                write(http, _HTTP_HTML)
            end
        end
    catch e
        @info "HTTP server error: $e"
    end

    @info "HTTP host listening on http://localhost:$(host.port)"

    for id in host.dirty_channel
        try
            if id == 0
                renderAll(host)
            else
                haskey(_http_hosts, id) || continue
                eh = _http_hosts[id]
                eh.host === host || continue
                renderElement(eh)
            end
        catch e
            @info "render error id=$id: $e"
        end
    end
end
