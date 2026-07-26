@info "BorderRepeatTest (Win32)"
using LibBaseTsd

include("../../common/Win32.jl")
using .W32
import .W32: TRUE, FALSE

include("../../common/LibSkia.jl")
using .LibSkia

include("../framework/Layout.jl")
include("../framework/Elements.jl")
include("../hosts/Win32ElementHost.jl")
include("../framework/NineSliceImage.jl")

import Base.cconvert, .GC.@preserve

const GAP = -1
const MIN_WIDTH = 400
const MIN_HEIGHT = 300

const HINST::HINSTANCE = GetModuleHandleW(C_NULL)

cwstring(s) = cconvert(Cwstring, s)
size_t(i::Int64) = reinterpret(UInt64, i) |> SIZE_T
flush_ws() = SetProcessWorkingSetSize(GetCurrentProcess(), size_t(-1), size_t(-1))

# 4×4 grid — columns: repeat_h (Stretch, Repeat, Round, Space)
#             rows:    repeat_v (Stretch, Repeat, Round, Space)
_layout = GridLayout(
    [
        GAP  GAP   GAP  GAP   GAP  GAP   GAP  GAP   GAP
        GAP   1    GAP   2    GAP   3    GAP   4    GAP
        GAP  GAP   GAP  GAP   GAP  GAP   GAP  GAP   GAP
        GAP   5    GAP   6    GAP   7    GAP   8    GAP
        GAP  GAP   GAP  GAP   GAP  GAP   GAP  GAP   GAP
        GAP   9    GAP  10    GAP  11    GAP  12    GAP
        GAP  GAP   GAP  GAP   GAP  GAP   GAP  GAP   GAP
        GAP  13    GAP  14    GAP  15    GAP  16    GAP
        GAP  GAP   GAP  GAP   GAP  GAP   GAP  GAP   GAP
    ],
    [5, ★"1", 5, ★"1", 5, ★"1", 5, ★"1", 5],
    [5, ★"1", 5, ★"1", 5, ★"1", 5, ★"1", 5])

const BORDER_MODES = (Stretch, Repeat, Round, Space)

function onCreate(hwnd)
    asset = joinpath(@__DIR__, "..", "assets", "border-diamonds.png")
    h, w = size(PNGFiles.load(asset))
    border = sk_irect_t(Int32(30), Int32(30), Int32(w - 30), Int32(h - 30))
    id = 1
    for rv in BORDER_MODES
        for rh in BORDER_MODES
            nine = NineSliceImage(asset; border)
            nine.repeat_h = rh
            nine.repeat_v = rv
            createElementHost(hwnd, nine, id, 0, 0, 100, 100)
            id += 1
        end
    end
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
    classname = L"BorderRepeatTestClass"
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
    hwnd = CreateWindowExW(DWORD(0), classname, L"Border Repeat Test", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 800, 600, HWND(0), HMENU(0), HINST, LPVOID(0))
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
