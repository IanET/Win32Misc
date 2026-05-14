@info "LayersElementTest (Win32)"
using LibBaseTsd

include("../../common/Win32.jl")
using .W32
import .W32: TRUE, FALSE

include("../../common/LibSkia.jl")
using .LibSkia

include("../framework/Layout.jl")
include("../framework/Elements.jl")
include("../framework/NineSliceImage.jl")
include("../framework/LayersElement.jl")
include("../hosts/Win32ElementHost.jl")

import Base.cconvert, .GC.@preserve

const GAP = -1
const IDC_COLOR   = 1
const IDC_NSLICE  = 2
const IDC_IMAGE   = 3
const IDC_LABEL   = 4
const MIN_WIDTH   = 300
const MIN_HEIGHT  = 200

const HINST::HINSTANCE = GetModuleHandleW(C_NULL)

cwstring(s) = cconvert(Cwstring, s)
size_t(i::Int64) = reinterpret(UInt64, i) |> SIZE_T
flush_ws() = SetProcessWorkingSetSize(GetCurrentProcess(), size_t(-1), size_t(-1))

#  ┌──────────────────────────────────────────────┐
#  │  color btn  │  nine-slice btn  │  image btn  │
#  │             label strip                      │
#  └──────────────────────────────────────────────┘
_layout = GridLayout(
    [
        GAP  GAP          GAP  GAP          GAP  GAP         GAP
        GAP  IDC_COLOR    GAP  IDC_NSLICE   GAP  IDC_IMAGE   GAP
        GAP  GAP          GAP  GAP          GAP  GAP         GAP
        GAP  IDC_LABEL    GAP  IDC_LABEL    GAP  IDC_LABEL   GAP
        GAP  GAP          GAP  GAP          GAP  GAP         GAP
    ],
    [10, ★"1", 10, 30, 10],
    [10, ★"1", 10, ★"1", 10, ★"1", 10])

function onCreate(hwnd)
    panel_path = joinpath(@__DIR__, "..", "assets", "panel.png")
    button_path = joinpath(@__DIR__, "..", "assets", "button.png")

    # 1. Pure color layers — normal/hover/pressed shown via tinted overlays
    color_btn = LayersElement(layers = AbstractLayer[
        ColorLayer(0xFFE8E8E8),                                      # normal gray
        ColorLayer(0x200080FF; state_mask = BS_HOVERED),             # blue tint on hover
        ColorLayer(0x30000000; state_mask = BS_PRESSED),             # dark overlay on press
        TextLayer("Color Layers"; font_size = 12f0, color = 0xFF606060),
    ])
    createElementHost(hwnd, color_btn, IDC_COLOR, 0, 0, 100, 100)

    # 2. Nine-slice background with state overlays and text
    nslice_btn = LayersElement(layers = AbstractLayer[
        NineSliceLayer(panel_path),
        ColorLayer(0x18FF0000; state_mask = BS_HOVERED, blend_mode = SRCATOP_SK_BLENDMODE),
        ColorLayer(0xFFFFA0A0; state_mask = BS_PRESSED, blend_mode = SRCATOP_SK_BLENDMODE),
        TextLayer("Nine-Slice"; color = 0xFF1A3A6A),
    ]; bgcolor = 0xFFFFFFFF)
    createElementHost(hwnd, nslice_btn, IDC_NSLICE, 0, 0, 100, 100)

    # 3. Image layer with hover/normal text swap
    image_btn = LayersElement(layers = AbstractLayer[
        ImageLayer(button_path),
        TextLayer("Normal Image";  color = 0xFF1A1A1A, state_mask = MASK_NORMAL),
        TextLayer("Hovered"; color = 0xFF0040C0, state_mask = BS_HOVERED, exclude_mask = BS_PRESSED),
        TextLayer("Pressed"; color = 0xFF800000, state_mask = BS_PRESSED),
    ])
    createElementHost(hwnd, image_btn, IDC_IMAGE, 0, 0, 100, 100)

    # 4. Static label — always-visible color + text, no interaction
    label = LayersElement(layers = AbstractLayer[
        ColorLayer(0xFF2060C0),
        TextLayer("LayersElement Demo"; color = 0xFFFFFFFF),
    ])
    createElementHost(hwnd, label, IDC_LABEL, 0, 0, 100, 100)

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
    classname = L"LayersElementTestClass"
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
    hwnd = CreateWindowExW(DWORD(0), classname, L"LayersElement Test", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 600, 300, HWND(0), HMENU(0), HINST, LPVOID(0))
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
