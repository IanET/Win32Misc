using JSON3, Dates, Sockets, HTTP

include("ATWindows.jl")

const PIPE_NAME        = "\\\\.\\pipe\\TestWidgetProvider.d94hev71b6gse"
const ACTION_PIPE_NAME = "\\\\.\\pipe\\TestWidgetProvider.actions.d94hev71b6gse"
const IMAGE_PORT       = 8765
const IMAGE_DIR        = "C:\\src\\ianet-github\\Win32Misc\\Widgets\\Provider\\Assets"

# Serve files from IMAGE_DIR at http://localhost:IMAGE_PORT/<filename>
HTTP.serve!(IMAGE_PORT; verbose=false) do req
    filename = lstrip(req.target, '/')
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
                                                            "url": "http://localhost:$IMAGE_PORT/LockScreenLogo.scale-200.png",
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
                                        "verb": "text1_clicked"
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
    n          = get(ITEMS_FOR_SIZE, widget_size, 5)
    all        = get_alt_tab_windows()
    total      = length(all)
    start      = clamp(page_offset, 0, max(0, total - n)) + 1
    slice      = all[start : min(start + n - 1, total)]
    can_prev = page_offset > 0
    can_next = page_offset < total - n
    JSON3.write((; windows = [(; title = first(t, 32)) for (_, t) in slice], can_prev, can_next))
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
                global page_offset = max(0, page_offset - 1)
            elseif verb == "next"
                global page_offset = min(page_offset + 1, max(0, total - n))
            end
            send_update(data=windows_data())
        elseif type == "Deactivate"
            @info "Widget deactivated"
        else
            @warn "Unknown event" line
        end
    end
end
