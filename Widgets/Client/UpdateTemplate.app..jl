using JSON3, Dates, Sockets, HTTP

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
        "type":"AdaptiveCard",
        "version":"1.5",
        "body":[
            {
                "type":"TextBlock",
                "text":"\${msg}",
                "size":"small",
                "wrap":true
            },
            {
                "type":"Image",
                "url":"http://localhost:$IMAGE_PORT/LockScreenLogo.scale-200.png",
                "size":"small",
                "selectAction":{
                    "type":"Action.Execute",
                    "verb":"image_clicked"
                }
            },
            {
                "type":"Container",
                "height":"stretch",
                "items":[]
            },
            {
                "type":"ActionSet",
                "separator": true,
                "actions":[
                    {
                        "type":"Action.Execute",
                        "title":"Button 1",
                        "verb":"button1_clicked"
                    },
                    {
                        "type":"Action.Execute",
                        "title":"Button 2",
                        "verb":"button2_clicked"
                    }
                ]
            }
        ]
    }
"""

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
            nowstr = Dates.format(Dates.now(), "I:MM:SS p")
            send_update(tmpl=template, data=JSON3.write((; msg = "Current Time: $nowstr")))
        elseif type == "OnActionInvoked"
            verb = get(evt, :verb, "")
            @info "Action invoked" verb
            nowstr = Dates.format(Dates.now(), "I:MM:SS p")
            send_update(data=JSON3.write((; msg = "OnActionInvoked: $verb at $nowstr")))
        elseif type == "Deactivate"
            @info "Widget deactivated"
        else
            @warn "Unknown event" line
        end
    end
end
