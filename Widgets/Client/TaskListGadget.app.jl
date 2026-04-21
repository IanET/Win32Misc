using JSON3, Dates, Sockets, HTTP, LibBaseTsd

include("ATWindows.jl")
include("IconToPng.jl")


const PIPE_NAME        = "\\\\.\\pipe\\TestWidgetProvider.d94hev71b6gse_to_provider"
const ACTION_PIPE_NAME = "\\\\.\\pipe\\TestWidgetProvider.d94hev71b6gse_from_provider"
const IMAGE_PORT       = 8765
const IMAGE_DIR        = "C:\\src\\ianet-github\\Win32Misc\\Widgets\\Provider\\Assets"

current_windows = Tuple{W32.HWND, String, Union{W32.HICON, Nothing}}[]
const icon_cache = Dict{UInt, Vector{UInt8}}()

function _cached_icon_png(hwnd_int::UInt)
    haskey(icon_cache, hwnd_int) && return icon_cache[hwnd_int]
    idx = findfirst(w -> UInt(w[1]) == hwnd_int, current_windows)
    idx === nothing && return nothing
    hicon = current_windows[idx][3]
    hicon === nothing && return nothing
    png = icon_to_png_bytes(hicon)
    png === nothing && return nothing
    icon_cache[hwnd_int] = png
end

HTTP.serve!(IMAGE_PORT; verbose=false) do req
    target = req.target
    if startswith(target, "/icon/")
        hwnd_int = tryparse(UInt, target[7:end])
        if hwnd_int !== nothing
            png = _cached_icon_png(hwnd_int)
            png !== nothing && return HTTP.Response(200, ["Content-Type" => "image/png"], png)
        end
        return HTTP.Response(404, "Not found")
    end
    filename = lstrip(target, '/')
    path = joinpath(IMAGE_DIR, filename)
    isfile(path) ? HTTP.Response(200, read(path)) : HTTP.Response(404, "Not found")
end
@info "Image server running on http://localhost:$IMAGE_PORT/"

const template = """
{
    "type": "AdaptiveCard",
    "version": "1.5",
    "body": [
        {
            "type": "Container"
        },
        {
            "type": "ColumnSet",
            "columns": [
                {
                    "type": "Column",
                    "width": "20px",
                    "style": "emphasis",
                    "verticalContentAlignment": "center",
                    "\$when": "\${can_prev}",
                    "items": [
                        { "type": "TextBlock", "text": "❮", "horizontalAlignment": "center" }
                    ],
                    "selectAction": { "type": "Action.Execute", "verb": "prev" }
                },
                {
                    "type": "Column",
                    "width": "20px",
                    "style": "emphasis",
                    "\$when": "\${!can_prev}"
                },
                {
                    "type": "Column",
                    "width": "stretch",
                    "items": [
                        {
                            "type": "Container",
                            "items": [
                                {
                                    "type": "Container",
                                    "\$data": "\${windows}",
                                    "bleed": true,
                                    "showBorder": true,
                                    "style": "emphasis",
                                    "items": [
                                        {
                                            "type": "ColumnSet",
                                            "verticalContentAlignment": "center",
                                            "columns": [
                                                {
                                                    "type": "Column",
                                                    "width": "auto",
                                                    "items": [
                                                        {
                                                            "type": "Image",
                                                            "url": "http://localhost:$IMAGE_PORT/icon/\${hwnd}",
                                                            "size": "small"
                                                        }
                                                    ]
                                                },
                                                {
                                                    "type": "Column",
                                                    "width": "stretch",
                                                    "verticalContentAlignment": "center",
                                                    "items": [
                                                        {
                                                            "type": "TextBlock",
                                                            "text": "\${title}",
                                                            "size": "small",
                                                            "wrap": true
                                                        }
                                                    ]
                                                }
                                            ]
                                        }
                                    ],
                                    "selectAction": {
                                        "type": "Action.Execute",
                                        "verb": "activate_\${hwnd}"
                                    }
                                }
                            ]
                        }
                    ]
                },
                {
                    "type": "Column",
                    "width": "20px",
                    "style": "emphasis",
                    "\$when": "\${!can_next}"
                },
                {
                    "type": "Column",
                    "width": "20px",
                    "style": "emphasis",
                    "verticalContentAlignment": "center",
                    "\$when": "\${can_next}",
                    "items": [
                        { "type": "TextBlock", "text": "❯", "horizontalAlignment": "center" }
                    ],
                    "selectAction": { "type": "Action.Execute", "verb": "next" }
                }
            ]
        }
    ]
}
"""

const ITEMS_FOR_SIZE = Dict("Small" => 2, "Medium" => 5, "Large" => 9)
widget_size  = "Medium"
page_offset  = 0

function windows_data()
    n = get(ITEMS_FOR_SIZE, widget_size, 5)
    global current_windows = get_alt_tab_windows()
    empty!(icon_cache)
    total    = length(current_windows)
    start    = clamp(page_offset, 0, max(0, total - n)) + 1
    slice    = current_windows[start : min(start + n - 1, total)]
    can_prev = page_offset > 0
    can_next = page_offset < total - n
    JSON3.write((; windows = [(; title = first(t, 32), hwnd = string(UInt(h))) for (h, t, _) in slice], can_prev, can_next))
end

function dismiss_widget_host()
    hwnd = W32.FindWindowW(L"Chrome_WidgetWin_1", L"Widgets")
    if hwnd != C_NULL
        W32.PostMessageW(hwnd, W32.WM_KEYDOWN, W32.VK_ESCAPE, W32.LPARAM(0))
        W32.PostMessageW(hwnd, W32.WM_KEYUP,   W32.VK_ESCAPE, W32.LPARAM(0))
        @info "Sent Escape to widget host" hwnd
    end
end

function activate_window(verb)
    dismiss_widget_host()
    hwnd   = W32.HWND(parse(UInt, verb[10:end]))
    W32.IsIconic(hwnd) != 0 && W32.ShowWindow(hwnd, W32.SW_RESTORE)
    fg_tid = W32.GetWindowThreadProcessId(W32.GetForegroundWindow(), C_NULL)
    my_tid = W32.GetCurrentThreadId()
    W32.AttachThreadInput(fg_tid, my_tid, W32.TRUE)
    # W32.SetForegroundWindow(W32.GetShellWindow())
    W32.SetForegroundWindow(hwnd)
    W32.BringWindowToTop(hwnd)
    W32.AttachThreadInput(fg_tid, my_tid, W32.FALSE)
    @info "Activated window" hwnd
end

function send_update(; tmpl=nothing, data)
    msg = JSON3.write((; template = tmpl, data))
    open(PIPE_NAME, "w") do pipe
        println(pipe, msg)
    end
end

server = Sockets.listen(ACTION_PIPE_NAME)
@info "Listening for actions on: $ACTION_PIPE_NAME"

while true
    conn = accept(server)
    @async for line in eachline(conn)
        evt = JSON3.read(line)
        type = get(evt, :type, nothing)
        if type == "Activate"
            @info "Widget activated — sending template"
            send_update(tmpl=template, data=windows_data())
        elseif type == "OnWidgetContextChanged"
            global widget_size = get(evt, :size, widget_size)
            @info "Widget context changed" widget_size
            send_update(tmpl=template, data=windows_data())
        elseif type == "OnActionInvoked"
            verb = get(evt, :verb, "")
            @info "Action invoked" verb
            n     = get(ITEMS_FOR_SIZE, widget_size, 5)
            total = length(get_alt_tab_windows())
            if verb == "prev"
                global page_offset = max(0, page_offset - n)
            elseif verb == "next"
                global page_offset = min(page_offset + n, max(0, total - n))
            elseif startswith(verb, "activate_")
                activate_window(verb)
            end
            send_update(data=windows_data())
        elseif type == "Deactivate"
            @info "Widget deactivated"
        else
            @warn "Unknown event" line
        end
    end
end
