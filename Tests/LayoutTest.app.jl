include("../common/Win32.jl")
using .W32
using LibBaseTsd

# @info "Press enter to continue" getpid(); readline()

include("layout.jl")

import Base.cconvert, .GC.@preserve

const GAP = -1
const IDC_LISTBOX = 1
const IDC_OK = 2
const IDC_CANCEL = 3

const BLUE_GRAY_BRUSH = W32.CreateSolidBrush(RGB(0xD0, 0xD0, 0xE0)) |> LRESULT
const HINST::HINSTANCE = W32.GetModuleHandleW(C_NULL)

cwstring(s) = cconvert(Cwstring, s)
tostring(v::AbstractArray{Cwchar_t}) = transcode(String, @view v[begin:findfirst(iszero, v)-1])
tolparam(s::String) = s |> cwstring |> pointer |> LPARAM
Base.Tuple(v::MemoryRef{UInt16}, len) = copyto!(zeros(eltype(v), len), v.mem) |> Tuple

_layout::GridLayout = GridLayout()

function onCreate(hwnd)
    lbstyle =  W32.WS_BORDER | W32.WS_CHILD | W32.WS_VISIBLE | W32.WS_VSCROLL | W32.ES_AUTOVSCROLL | W32.LBS_NOINTEGRALHEIGHT | W32.LBS_HASSTRINGS | W32.LBS_NOTIFY | W32.WS_TABSTOP
    listbox = W32.CreateWindowExW(0, L"LISTBOX", C_NULL, lbstyle, 0, 0, 100, 100, hwnd, HMENU(IDC_LISTBOX), HINST, C_NULL)
    facename = Tuple(L"Segoe UI", 32)
    lf = W32.LOGFONTW(-16, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 0, 0, facename)
    hfont = W32.CreateFontIndirectW(Ref(lf))
    W32.SendMessageW(listbox, W32.WM_SETFONT, WPARAM(hfont), LPARAM(W32.TRUE))

    W32.SendMessageW(listbox, W32.LB_ADDSTRING, C_NULL, tolparam("Item 1"))
    W32.SendMessageW(listbox, W32.LB_ADDSTRING, C_NULL, tolparam("Item 2"))
    W32.SendMessageW(listbox, W32.LB_ADDSTRING, C_NULL, tolparam("Item 3"))

    ok = W32.CreateWindowExW(0, L"BUTTON", L"OK", W32.WS_CHILD | W32.WS_VISIBLE | W32.WS_CLIPSIBLINGS | W32.WS_TABSTOP, 10, 10, 100, 100, hwnd, HMENU(IDC_OK), HINST, C_NULL)
    W32.SendMessageW(ok, W32.WM_SETFONT, WPARAM(hfont), LPARAM(W32.TRUE))

    cancel = W32.CreateWindowExW(0, L"BUTTON", L"Cancel", W32.WS_CHILD | W32.WS_VISIBLE | W32.WS_CLIPSIBLINGS | W32.WS_TABSTOP, 20, 20, 100, 100, hwnd, HMENU(IDC_CANCEL), HINST, C_NULL)
    W32.SendMessageW(cancel, W32.WM_SETFONT, WPARAM(hfont), LPARAM(W32.TRUE))

    # global _layout = GridLayout(hwnd, 
    #     [   
    #         IDC_LISTBOX IDC_LISTBOX IDC_LISTBOX
    #         GAP         IDC_OK      IDC_CANCEL
    #     ], 
    #     [★"1", 30],   # row heights
    #     [100, 100, 100])  # col widths

    # global _layout = GridLayout(hwnd, 
    #     [   
    #         IDC_LISTBOX IDC_LISTBOX IDC_LISTBOX
    #         GAP         IDC_OK      IDC_CANCEL
    #     ], 
    #     [★"1", 30],   # row heights
    #     [★"3", ★"1", ★"1"])  # col widths

    global _layout = GridLayout(hwnd, 
        [   
            GAP     GAP         GAP         GAP         GAP    
            GAP     IDC_LISTBOX IDC_LISTBOX IDC_LISTBOX GAP
            GAP     GAP         GAP         GAP         GAP    
            GAP     GAP         IDC_OK      IDC_CANCEL  GAP 
            GAP     GAP         GAP         GAP         GAP    
        ], 
        [5, ★"1", 5, 30, 5],   # row heights
        [5, ★"1", 75, 75, 5])  # col widths

    return 0
end

function onSize(hwnd, width, height)
    layout(_layout)
    return 0
end

function onDestroy(hwnd)
    W32.PostQuitMessage(0)
    return 0
end

function onListboxCommand(hlistbox::HWND, code)
    if code == W32.LBN_SELCHANGE
        sel = W32.SendMessageW(hlistbox, W32.LB_GETCURSEL, C_NULL, C_NULL)
        @info "Selected" sel
    end
    return 0
end

function onCtlColorListbox(_)
    return BLUE_GRAY_BRUSH
end

function onClose(hwnd)
    W32.DestroyWindow(hwnd)
    return 0
end

# Msgs from parent process
function onCopyData(hwnd, hwndSrc::HWND, pcopydata::Ptr{W32.COPYDATASTRUCT})
    copydata = unsafe_load(pcopydata)
    # @info "UI: onCopyData" pcopydata copydata.dwData copydata.cbData copydata.lpData
    return TRUE
end

function onCommand(hwnd, id, code)
    if id == IDC_OK
        @info "OK"
    elseif id == IDC_CANCEL
        @info "Cancel"
    end
    return 0
end

function wndProc(hwnd::HWND, umsg::UINT, wparam::WPARAM, lparam::LPARAM)::LRESULT
    try
        if umsg == W32.WM_CREATE
            return onCreate(hwnd)
        elseif umsg == W32.WM_CLOSE
            return onClose(hwnd)
        elseif umsg == W32.WM_DESTROY
            return onDestroy(hwnd)
        elseif umsg == W32.WM_SIZE
            return onSize(hwnd, W32.LOWORD(lparam), W32.HIWORD(lparam))
        elseif umsg == W32.WM_COMMAND && W32.LOWORD(wparam) == IDC_LISTBOX
            return onListboxCommand(HWND(lparam), W32.HIWORD(wparam))
        elseif umsg == W32.WM_CTLCOLORLISTBOX
            return onCtlColorListbox((HWND(lparam)))
        elseif umsg == W32.WM_COPYDATA
            return onCopyData(hwnd, HWND(wparam), Ptr{W32.COPYDATASTRUCT}(lparam))
        elseif umsg == W32.WM_COMMAND
            return onCommand(hwnd, W32.LOWORD(wparam), W32.HIWORD(wparam))
        end

        return W32.DefWindowProcW(hwnd, umsg, wparam, lparam)
    catch exc
        @error exc
        @info "Exception" catch_backtrace() |> stacktrace
    end

    return 0
end

function main()
    @info "UI Begin"

    hicon = W32.LoadIconW(HINSTANCE(0), W32.IDI_INFORMATION)
    hcursor = W32.LoadCursorW(HINSTANCE(0), W32.IDC_ARROW)
    hbrush = HBRUSH(W32.COLOR_WINDOW+1)
    classname = L"LayoutTestClass"
    cwndproc = @cfunction(wndProc, LRESULT, (HWND, UINT, WPARAM, LPARAM))

    wc = WNDCLASSW(W32.CS_HREDRAW | W32.CS_VREDRAW, cwndproc, 0, 0, HINST, hicon, hcursor, hbrush, C_NULL, pointer(classname))
    @preserve classname W32.RegisterClassW(Ref(wc))
    hwnd = W32.CreateWindowExW(DWORD(0), classname, L"Layout Test", W32.WS_OVERLAPPEDWINDOW, W32.CW_USEDEFAULT, W32.CW_USEDEFAULT, 512, 512, HWND(0), HMENU(0), HINST, LPVOID(0))
            
    W32.ShowWindow(hwnd, W32.SW_SHOWNORMAL)
    size_t(i::Int64) = reinterpret(UInt64, i) |> SIZE_T
    W32.SetProcessWorkingSetSize(W32.GetCurrentProcess(), size_t(-1), size_t(-1))

    MsgLoop() do msg
        W32.TranslateMessage(msg)
        W32.DispatchMessageW(msg)
    end

    @info "UI End"
end

main()
