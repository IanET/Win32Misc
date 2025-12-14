import Base.GC.@preserve

include("../common/Win32.jl")
include("../common/ComBase.jl")

using .W32

include("UIAutomation.jl")


const EDGE_TITLE = "Microsoft\u200b Edge"
const EDGE_IMAGE_PATH = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"

function findEdge()
    hwnd = FindWindowExW(HWND(0), HWND(0), L"Chrome_WidgetWin_1", C_NULL)
    while hwnd != HWND(C_NULL)
        titlebuf = zeros(WCHAR, 1024)
        GetWindowTextW(hwnd, titlebuf, length(titlebuf))
        len = findfirst(iszero, titlebuf) - 1
        if len != 0 
            title = transcode(String, @view titlebuf[begin:len])
            if occursin(EDGE_TITLE, title)
                processId = DWORD(0) |> Ref
                ret = GetWindowThreadProcessId(hwnd, processId)
                @assert ret != 0
                hproc = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, processId[])
                inbuf = zeros(WCHAR, 1024)
                inbuflen = DWORD(length(inbuf)) |> Ref
                QueryFullProcessImageNameW(hproc, 0, inbuf, inbuflen)
                imagename = transcode(String, @view inbuf[begin:inbuflen[]])
                if imagename == EDGE_IMAGE_PATH
                    @info "ProcessId" hwnd title processId[] hproc imagename
                    break
                end
            end
        end
        hwnd = FindWindowExW(HWND(0), hwnd, L"Chrome_WidgetWin_1", C_NULL)
    end
    return hwnd
end

res = CoInitialize(C_NULL)

automation = Ptr{IUIAutomation}(C_NULL) |> Ref
CoCreateInstance(Ref(CLSID_CUIAutomation), C_NULL, CLSCTX_INPROC_SERVER, Ref(IID_IUIAutomation), automation) |> AssertSuccess

hwnd = findEdge()
@info "findEdge" hwnd
@assert hwnd != HWND(C_NULL)

element = Ptr{IUIAutomationElement}(C_NULL) |> Ref
ElementFromHandle(automation[], hwnd, element) |> AssertSuccess
@info "ElementFromHandle" element[]

variant = VARIANT_I4(intVal = UIA_DocumentControlTypeId)
cond = Ptr{IUIAutomationPropertyCondition}(C_NULL) |> Ref
CreatePropertyCondition(automation[], UIA_ControlTypePropertyId, variant, cond) |> AssertSuccess
id = PROPERTYID(0) |> Ref
get_PropertyId(cond[], id) |> AssertSuccess
val = VARIANT() |> Ref
get_PropertyValue(cond[], val) |> AssertSuccess
@info "CreatePropertyCondition" cond[] id[] val[]

textelem = Ptr{IUIAutomationElement}(C_NULL) |> Ref
FindFirst(element[], TreeScope_Descendants, cond[], textelem) |> AssertSuccess
@info "FindFirst" textelem[]

obj = Ptr{Cvoid}(C_NULL) |> Ref
GetCurrentPatternAs(textelem[], UIA_TextPatternId, Ref(IID_IUIAutomationTextPattern), obj) |> AssertSuccess
textPattern = Ptr{IUIAutomationTextPattern}(obj[]) |> Ref
@info "GetCurrentPatternAs" textPattern[]

textRange = Ptr{IUIAutomationTextRange}(C_NULL) |> Ref
get_DocumentRange(textPattern[], textRange) |> AssertSuccess
@info "get_DocumentRange" textRange[]

bstr = BSTR(C_NULL) |> Ref
GetText(textRange[], -1, bstr) |> AssertSuccess
@info "Bstr" bstr[]
text = unsafe_string(bstr[] |> Cwstring)
text = filter(c -> c < Char(0x80), text) # remove non-ascii characters
write("edge_uiatest_output.txt.tmp", text)

@info "Text" text

@info "Done"