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

function _get_process_exe_path(hwnd)
    pid = Ref{W32.DWORD}(0)
    W32.GetWindowThreadProcessId(hwnd, pid)
    pid[] == 0 && return nothing
    hproc = W32.OpenProcess(W32.PROCESS_QUERY_LIMITED_INFORMATION, W32.FALSE, pid[])
    hproc == C_NULL && return nothing
    buf = zeros(UInt16, 260)
    size = Ref{W32.DWORD}(260)
    ok = W32.QueryFullProcessImageNameW(hproc, 0, buf, size)
    W32.CloseHandle(hproc)
    ok == 0 && return nothing
    # null-terminate for use as LPCWSTR
    vcat(buf[1:size[]], UInt16(0))
end

function get_window_icon(hwnd)
    # Try WM_GETICON: large, then small2 (DPI-scaled small), then small
    for itype in (1, 2, 0)
        r = W32.SendMessageW(hwnd, W32.WM_GETICON, itype, 0)
        r != 0 && return W32.HICON(r)
    end
    # Fall back to class icon
    r = W32.GetClassLongPtrW(hwnd, W32.GCLP_HICON)
    r != 0 && return W32.HICON(r)
    # Fall back to first icon in process executable
    path = _get_process_exe_path(hwnd)
    path === nothing && return nothing
    hicon = W32.ExtractIconW(W32.GetModuleHandleW(C_NULL), path, 0)
    (hicon == C_NULL || Int(hicon) == 1) ? nothing : hicon
end

const _results = Tuple{W32.HWND, String, Union{W32.HICON, Nothing}}[]

function _enum_callback(hwnd::Ptr{Cvoid}, _::Int)::Cint
    if is_alt_tab_window(hwnd)
        title = get_title(hwnd)
        title !== nothing && push!(_results, (hwnd, title, get_window_icon(hwnd)))
    end
    Cint(1)
end

const _enum_cb = @cfunction(_enum_callback, Cint, (Ptr{Cvoid}, Int))

function get_alt_tab_windows()
    empty!(_results)
    W32.EnumWindows(_enum_cb, 0)
    copy(_results)
end

# if abspath(PROGRAM_FILE) == @__FILE__
#     for (hwnd, title, hicon) in get_alt_tab_windows()
#         println("$hwnd  $title  icon=$(hicon)")
#     end
# end
