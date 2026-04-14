using JSON3, Dates

const PIPE_NAME = "\\\\.\\pipe\\HelloWidgetProvider.d94hev71b6gse"
const nowstr = Dates.format(Dates.now(), "HH:MM:SS")
const template = """
    {
        "type":"AdaptiveCard",
        "version":"1.5",
        "body":[
            {
                "type":"TextBlock",
                "text":"Hello World ($nowstr)",
                "size":"small",
                "wrap":true
            }
        ]
    }
"""

# Escape the template JSON as a string value inside the outer JSON message
escaped = replace(template, "\\" => "\\\\", "\"" => "\\\"", "\n" => "")
msg = """{"template":"$escaped","data":"{}"}"""
# @info "Message" msg
# json = JSON3.read(msg)
# template_parsed = JSON3.read(json["template"])
# data_parsed = JSON3.read(json["data"])
# @info "Parsed" JSON3.write(json) template_parsed data_parsed

pipe = open(PIPE_NAME, "w")
println(pipe, msg)
flush(pipe)
close(pipe)
@info "Message sent to provider, length=$(length(msg))"
