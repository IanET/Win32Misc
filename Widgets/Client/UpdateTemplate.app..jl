using JSON3, Dates, Sockets

const PIPE_NAME        = "\\\\.\\pipe\\TestWidgetProvider.d94hev71b6gse"
const ACTION_PIPE_NAME = "\\\\.\\pipe\\TestWidgetProvider.actions.d94hev71b6gse"

# Start action pipe server before sending the template so C# can connect immediately
server = Sockets.listen(ACTION_PIPE_NAME)
@info "Listening for actions on: $ACTION_PIPE_NAME"

# Send template update
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
                "type":"TextBlock",
                "text":"Testing",
                "size":"small",
                "wrap":true
            },
            {
                "type":"Image",
                "url":"https://www.wikipedia.org/portal/wikipedia.org/assets/img/Wikipedia-logo-v2@1.5x.png",
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
nowstr = Dates.format(Dates.now(), "I:MM:SS p")
data = JSON3.write((; msg = "Current Time: $nowstr"))
msg = JSON3.write((; template, data))
open(PIPE_NAME, "w") do pipe
    println(pipe, msg)
end
@info "Template sent, waiting for actions..."

# Block waiting for button presses
while true
    conn = accept(server)
    @async for line in eachline(conn)
        evt = JSON3.read(line)
        if get(evt, :type, nothing) == "OnActionInvoked"
            verb = get(evt, :verb, "")
            @info "Action invoked" verb
            nowstr = Dates.format(Dates.now(), "I:MM:SS p")
            data = JSON3.write((; msg = "OnActionInvoked: $verb at $nowstr"))
            msg = JSON3.write((; nothing, data))
            open(PIPE_NAME, "w") do pipe
                println(pipe, msg)
            end
        else
            @warn "Unknown event" line
        end
    end
end
