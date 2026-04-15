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
                    "width": "auto",
                    "verticalContentAlignment": "top",
                    "items": [
                        { "type": "TextBlock", "text": "❮", "horizontalAlignment": "center" }
                    ]
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
                                    "id": "ITEM_TEMPLATE",
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
                                                            "text": "\${msg}",
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
                    "width": "auto",
                    "verticalContentAlignment": "top",
                    "items": [
                        { "type": "TextBlock", "text": "❯", "horizontalAlignment": "center" }
                    ]
                }
            ]
        }
    ]
}
"""

# Convert JSON3 read-only objects to mutable Dict/Vector trees
to_mutable(x::JSON3.Object) = Dict{String,Any}(String(k) => to_mutable(v) for (k,v) in x)
to_mutable(x::JSON3.Array)  = Any[to_mutable(v) for v in x]
to_mutable(x)               = x

is_item_template(x) = x isa Dict && get(x, "type", nothing) == "Container" && get(x, "id", nothing) == "ITEM_TEMPLATE"

# Recursively walk the tree; when an array contains ITEM_TEMPLATE, replace it with n copies
function expand_item_template(obj, n=5)
    if obj isa Dict
        Dict{String,Any}(k => expand_item_template(v, n) for (k,v) in obj)
    elseif obj isa Vector
        result = Any[]
        for item in obj
            if is_item_template(item)
                for _ in 1:n
                    clone = deepcopy(item)
                    delete!(clone, "id")
                    push!(result, clone)
                end
            else
                push!(result, expand_item_template(item, n))
            end
        end
        result
    else
        obj
    end
end

function build_template(tmpl::String, n=5)
    JSON3.write(expand_item_template(to_mutable(JSON3.read(tmpl)), n))
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
            nowstr = Dates.format(Dates.now(), "I:MM:SS p")
            send_update(tmpl=build_template(template), data=JSON3.write((; msg = "Current Time: $nowstr")))
        elseif type == "OnWidgetContextChanged"
            size = get(evt, :size, "")
            @info "Widget context changed" size
            nowstr = Dates.format(Dates.now(), "I:MM:SS p")
            send_update(tmpl=build_template(template), data=JSON3.write((; msg = "Current Time: $nowstr")))
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
