@info "NineSliceTest"
using LibBaseTsd

include("../common/Win32.jl")
using .W32
import .W32: TRUE, FALSE

include("../common/LibSkia.jl")
using .LibSkia

include("Layout.jl")
include("Elements.jl")
include("ElementHost.jl")
include("NineSliceImage.jl")

import Base.cconvert, .GC.@preserve

const GAP = -1
const IDC_NINESLICE = 1
const MIN_WIDTH = 200
const MIN_HEIGHT = 200

const HINST::HINSTANCE = GetModuleHandleW(C_NULL)

cwstring(s) = cconvert(Cwstring, s)
size_t(i::Int64) = reinterpret(UInt64, i) |> SIZE_T
flush_ws() = SetProcessWorkingSetSize(GetCurrentProcess(), size_t(-1), size_t(-1))

_layout = GridLayout(
    [
        GAP   GAP              GAP
        GAP   IDC_NINESLICE    GAP
        GAP   GAP              GAP
    ],
    [10, ★"1", 10],   # row heights
    [10, ★"1", 10])   # col widths

function onCreate(hwnd)
    nine = NineSliceImage("assets/button.png")
    nine.background = 0xFFFFFFFF
    createElementHost(hwnd, nine, IDC_NINESLICE, 0, 0, 100, 100)
    return 0
end

function onSize(hwnd, wparam, width, height)
    if wparam == SIZE_MINIMIZED
        flush_ws()
        return 0
    end
    if width <= 0 || height <= 0; return 0 end
    layout(hwnd, _layout)
    return 0
end

function onDestroy(_)
    PostQuitMessage(0)
    return 0
end

function onClose(hwnd)
    DestroyWindow(hwnd)
    return 0
end

function onGetMinMaxInfo(_, pmmi::Ptr{MINMAXINFO})
    unsafe_modify_cstruct(pmmi, :ptMinTrackSize, POINT(MIN_WIDTH, MIN_HEIGHT))
    return 0
end

function appWndProc(hwnd::HWND, umsg::UINT, wparam::WPARAM, lparam::LPARAM)::LRESULT
    try
        if umsg == WM_CREATE
            return onCreate(hwnd)
        elseif umsg == WM_CLOSE
            return onClose(hwnd)
        elseif umsg == WM_DESTROY
            return onDestroy(hwnd)
        elseif umsg == WM_SIZE
            return onSize(hwnd, wparam, LOWORD(lparam), HIWORD(lparam))
        elseif umsg == WM_GETMINMAXINFO
            return onGetMinMaxInfo(hwnd, Ptr{MINMAXINFO}(lparam))
        end
        return DefWindowProcW(hwnd, umsg, wparam, lparam)
    catch exc
        @error exc
        throw(exc)
    end

    return 0
end

function createMainWindow()
    classname = L"NineSliceTestClass"
    wc = WNDCLASSW(
        CS_HREDRAW | CS_VREDRAW,
        @cfunction(appWndProc, LRESULT, (HWND, UINT, WPARAM, LPARAM)),
        0, 0,
        HINST,
        LoadIconW(HINSTANCE(0), IDI_INFORMATION),
        LoadCursorW(HINSTANCE(0), IDC_ARROW),
        HBRUSH(COLOR_WINDOW+1),
        C_NULL,
        pointer(classname))
    @preserve classname RegisterClassW(Ref(wc))
    hwnd = CreateWindowExW(DWORD(0), classname, L"NineSlice Test", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 512, 512, HWND(0), HMENU(0), HINST, LPVOID(0))
    return hwnd
end

function main()
    @info "UI Begin"

    hwnd = createMainWindow()
    ShowWindow(hwnd, SW_SHOWNORMAL)
    flush_ws()

    MsgLoop() do msg
        TranslateMessage(msg)
        DispatchMessageW(msg)
    end

    @info "UI End"
end

main()
