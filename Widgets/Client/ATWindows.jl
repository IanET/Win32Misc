include("..\\..\\Common\\Win32.jl")
using .W32

const GW_OWNER = W32.UINT(4)

function get_title(hwnd)
    buf = zeros(UInt16, 256)
    len = W32.GetWindowTextW(hwnd, buf, 256)
    len == 0 ? nothing : String(transcode(UInt8, buf[1:len]))
end

function is_alt_tab_window(hwnd)
    W32.IsWindowVisible(hwnd) == 0 && return false
    get_title(hwnd) === nothing && return false

    style = W32.GetWindowLongW(hwnd, W32.GWL_STYLE)
    style & W32.WS_POPUP != 0 && return false

    exstyle = W32.GetWindowLongW(hwnd, W32.GWL_EXSTYLE)
    exstyle & W32.WS_EX_TOOLWINDOW != 0 && return false

    owner = W32.GetWindow(hwnd, GW_OWNER)
    owner != C_NULL && exstyle & W32.WS_EX_APPWINDOW == 0 && return false

    return true
end

const _results = Tuple{W32.HWND, String}[]

function _enum_callback(hwnd::Ptr{Cvoid}, _::Int)::Cint
    if is_alt_tab_window(hwnd)
        title = get_title(hwnd)
        title !== nothing && push!(_results, (hwnd, title))
    end
    Cint(1)
end

const _enum_cb = @cfunction(_enum_callback, Cint, (Ptr{Cvoid}, Int))

function get_alt_tab_windows()
    empty!(_results)
    W32.EnumWindows(_enum_cb, 0)
    copy(_results)
end

for (hwnd, title) in get_alt_tab_windows()
    println("$hwnd  $title")
end
