using JSON3, Dates

const PIPE_NAME = "\\\\.\\pipe\\TestWidgetProvider.d94hev71b6gse"
const nowstr = Dates.format(Dates.now(), "I:MM:SS p")
const template = """
    {
        "type":"AdaptiveCard",
        "version":"1.5",
        "body":[
            {
                "type":"TextBlock",
                "text":"Current Time: $nowstr",
                "size":"small",
                "wrap":true
            }
        ]
    }
"""

# Escape the template JSON as a string value inside the outer JSON message
escaped = replace(template, "\\" => "\\\\", "\"" => "\\\"", "\n" => "")
msg = """{"template":"$escaped","data":"{}"}"""

pipe = open(PIPE_NAME, "w")
println(pipe, msg)
flush(pipe)
close(pipe)
@info "Message sent to provider, length=$(length(msg))"
