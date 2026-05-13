
using GLFW
using ModernGL
import .GC.@preserve

# ── Shaders ───────────────────────────────────────────────────────────────────
# Pixel coords (top-left origin) → NDC via Y-flip in position.
# UV v=0 = GL texture bottom = first data row = Skia row 0 = screen top. No UV flip needed.

const _vert = """
#version 330 core
layout(location=0) in vec2 pos;
uniform vec2 u_pos;
uniform vec2 u_size;
uniform vec2 u_viewport;
out vec2 v_uv;
void main(){
    vec2 ndc = (u_pos + pos * u_size) / u_viewport * 2.0 - 1.0;
    ndc.y = -ndc.y;
    gl_Position = vec4(ndc, 0.0, 1.0);
    v_uv = pos;
}
"""

const _frag = """
#version 330 core
in vec2 v_uv;
out vec4 color;
uniform sampler2D u_tex;
void main(){ color = texture(u_tex, v_uv); }
"""

function _compile_shader(src, type)
    s = glCreateShader(type)
    glShaderSource(s, 1, [pointer(src)], [Cint(sizeof(src))])
    glCompileShader(s)
    ok = Ref{GLint}(0)
    glGetShaderiv(s, GL_COMPILE_STATUS, ok)
    if ok[] == GL_FALSE
        buf = zeros(UInt8, 1024)
        glGetShaderInfoLog(s, 1024, C_NULL, buf)
        error("shader: $(unsafe_string(pointer(buf)))")
    end
    return s
end

function _build_program()
    v = _compile_shader(_vert, GL_VERTEX_SHADER)
    f = _compile_shader(_frag, GL_FRAGMENT_SHADER)
    p = glCreateProgram()
    glAttachShader(p, v); glAttachShader(p, f)
    glLinkProgram(p)
    glDeleteShader(v); glDeleteShader(f)
    return p
end

const _quad = Float32[0,0, 1,0, 1,1, 0,0, 1,1, 0,1]

function _build_vao()
    vao = Ref{GLuint}(0); vbo = Ref{GLuint}(0)
    glGenVertexArrays(1, vao); glGenBuffers(1, vbo)
    glBindVertexArray(vao[])
    glBindBuffer(GL_ARRAY_BUFFER, vbo[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(_quad), _quad, GL_STATIC_DRAW)
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, C_NULL)
    glEnableVertexAttribArray(0)
    glBindVertexArray(0)
    return vao[], vbo[]
end

# GL_BGRA pixel transfer format (OpenGL 1.2 core, 0x80E1)
const _GL_BGRA = GLenum(0x80E1)

# ── Host structs ──────────────────────────────────────────────────────────────

mutable struct GLFWHost
    window::GLFW.Window
    width::Int32
    height::Int32
    prog::GLuint
    vao::GLuint
    vbo::GLuint
end

mutable struct GLFWElementHost
    host::GLFWHost
    el::AbstractElement
    texture::GLuint
    x::Int32
    y::Int32
    width::Int32
    height::Int32
end

const _glfw_hosts = Dict{Int, GLFWElementHost}()

# ── Lifecycle ─────────────────────────────────────────────────────────────────

function createGLFWHost(title::String, w::Int, h::Int)::GLFWHost
    GLFW.Init()
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, true)
    window = GLFW.CreateWindow(w, h, title)
    GLFW.MakeContextCurrent(window)
    prog = _build_program()
    vao, vbo = _build_vao()
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    return GLFWHost(window, Int32(w), Int32(h), prog, vao, vbo)
end

function createGLFWElementHost(host::GLFWHost, e::AbstractElement, id::Int, x::Int, y::Int, w::Int, h::Int)
    eh = GLFWElementHost(host, e, GLuint(0), Int32(x), Int32(y), Int32(w), Int32(h))
    _glfw_hosts[id] = eh
    element(e).repaint = () -> GLFW.PostEmptyEvent()
    return eh
end

function destroyGLFWHost(host::GLFWHost)
    for (_, eh) in _glfw_hosts
        eh.host === host || continue
        eh.texture != 0 && glDeleteTextures(1, Ref(eh.texture))
    end
    empty!(_glfw_hosts)
    glDeleteProgram(host.prog)
    glDeleteVertexArrays(1, Ref(host.vao))
    glDeleteBuffers(1, Ref(host.vbo))
    GLFW.DestroyWindow(host.window)
    GLFW.Terminate()
end

# ── Layout ────────────────────────────────────────────────────────────────────

function layout(host::GLFWHost, gl::GridLayout)
    rects = computeLayout(Int(host.width), Int(host.height), gl)
    for (id, (x, y, w, h)) in rects
        haskey(_glfw_hosts, id) || continue
        eh = _glfw_hosts[id]
        old_w, old_h = Int(eh.width), Int(eh.height)
        eh.x, eh.y, eh.width, eh.height = Int32(x), Int32(y), Int32(w), Int32(h)
        if w > 0 && h > 0 && (old_w != w || old_h != h)
            resize(eh.el, w, h)
        end
    end
end

# ── Rendering ─────────────────────────────────────────────────────────────────

function renderElement(eh::GLFWElementHost)
    (eh.width <= 0 || eh.height <= 0) && return
    pixmap = paint(eh.el, eh.width, eh.height)
    pixmap === nothing && return

    pw, ph = Int32.(size(pixmap))

    if eh.texture == 0
        t = Ref{GLuint}(0)
        glGenTextures(1, t)
        eh.texture = t[]
        glBindTexture(GL_TEXTURE_2D, eh.texture)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    else
        glBindTexture(GL_TEXTURE_2D, eh.texture)
    end

    @preserve pixmap glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, pw, ph, 0,
        _GL_BGRA, GL_UNSIGNED_BYTE, Ptr{Cvoid}(pointer(pixmap)))

    host = eh.host
    glUseProgram(host.prog)
    glUniform2f(glGetUniformLocation(host.prog, "u_pos"),      Float32(eh.x),       Float32(eh.y))
    glUniform2f(glGetUniformLocation(host.prog, "u_size"),     Float32(eh.width),   Float32(eh.height))
    glUniform2f(glGetUniformLocation(host.prog, "u_viewport"), Float32(host.width), Float32(host.height))
    glUniform1i(glGetUniformLocation(host.prog, "u_tex"), 0)
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, eh.texture)
    glBindVertexArray(host.vao)
    glDrawArrays(GL_TRIANGLES, 0, 6)
    glBindVertexArray(0)
end

function renderAll(host::GLFWHost)
    glViewport(0, 0, host.width, host.height)
    glClearColor(0.78f0, 0.78f0, 0.78f0, 1f0)
    glClear(GL_COLOR_BUFFER_BIT)
    for (_, eh) in _glfw_hosts
        eh.host === host && renderElement(eh)
    end
    GLFW.SwapBuffers(host.window)
end

# ── Input ─────────────────────────────────────────────────────────────────────

function hitTest(host::GLFWHost, x::Float64, y::Float64)::Union{GLFWElementHost, Nothing}
    for (_, eh) in _glfw_hosts
        eh.host === host || continue
        x >= eh.x && x < eh.x + eh.width && y >= eh.y && y < eh.y + eh.height && return eh
    end
    return nothing
end

# ── Event loop ────────────────────────────────────────────────────────────────

function glfwEventLoop(host::GLFWHost, onResize::Function)
    win = host.window

    GLFW.SetFramebufferSizeCallback(win, (_, w, h) -> begin
        host.width, host.height = Int32(w), Int32(h)
        onResize(host, Int32(w), Int32(h))
    end)

    # Fires during OS resize modal loop — handles live repaint while dragging
    GLFW.SetWindowRefreshCallback(win, _ -> renderAll(host))

    pressed = Ref{Union{GLFWElementHost, Nothing}}(nothing)
    GLFW.SetMouseButtonCallback(win, (_, btn, action, _mods) -> begin
        btn == GLFW.MOUSE_BUTTON_LEFT || return
        x, y = GLFW.GetCursorPos(win)
        if action == GLFW.PRESS
            eh = hitTest(host, x, y)
            pressed[] = eh
            eh !== nothing && press(eh.el)
        elseif action == GLFW.RELEASE
            eh = hitTest(host, x, y)
            eh !== nothing && eh === pressed[] && click(eh.el)
            pressed[] = nothing
        end
    end)

    while !GLFW.WindowShouldClose(win)
        GLFW.WaitEvents()
        renderAll(host)
    end
end
