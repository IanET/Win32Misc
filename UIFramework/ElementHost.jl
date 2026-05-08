
@kwdef mutable struct ElementHostState
    onPaint::Function = (w, h) -> Ptr{Cvoid}(0)
    onClick::Function = () -> nothing
    onResize::Function = (w, h) -> nothing
end

const _hosts = Dict{HWND, ElementHostState}()

function onElementHostCreate(hwnd)::LRESULT
    _hosts[hwnd] = ElementHostState()
    return 0
end

function onElementHostDestroy(hwnd)::LRESULT
    delete!(_hosts, hwnd)
    return 0
end

function onElementHostPaint(hwnd)::LRESULT
    state = _hosts[hwnd]
    ps = PAINTSTRUCT() |> Ref
    hdc = BeginPaint(hwnd, ps)
    rcclient = RECT() |> Ref
    GetClientRect(hwnd, rcclient)
    w = rcclient[].right - rcclient[].left
    h = rcclient[].bottom - rcclient[].top
    if w > 0 && h > 0
        pbits = state.onPaint(w, h)
        bmih = BITMAPINFOHEADER(sizeof(BITMAPINFOHEADER), w, -h, 1, 32, BI_RGB, 0, 0, 0, 0, 0) |> Ref
        bmpinfo = BITMAPINFO(bmih[], (RGBQUAD(),)) |> Ref
        SetDIBitsToDevice(hdc, 0, 0, w, h, 0, 0, 0, h, pbits, bmpinfo, DIB_RGB_COLORS)
    end
    EndPaint(hwnd, ps)
    return 0
end

function onElementHostResize(hwnd, w, h)::LRESULT
    _hosts[hwnd].onResize(w, h)
    return 0
end

function onElementHostClick(hwnd)::LRESULT
    _hosts[hwnd].onClick()
    return 0
end

function elementHostWndProc(hwnd::HWND, umsg::UINT, wparam::WPARAM, lparam::LPARAM)::LRESULT
    try
        if umsg == WM_CREATE
            return onElementHostCreate(hwnd)
        elseif umsg == WM_DESTROY
            return onElementHostDestroy(hwnd)
        elseif umsg == WM_PAINT
            return onElementHostPaint(hwnd)
        elseif umsg == WM_SIZE
            return onElementHostResize(hwnd, LOWORD(lparam), HIWORD(lparam))
        elseif umsg == WM_LBUTTONUP
            return onElementHostClick(hwnd)
        end
        return DefWindowProcW(hwnd, umsg, wparam, lparam)
    catch exc
        @error exc
        @info "Exception" catch_backtrace() |> stacktrace
    end

    return 0
end

function createElementHost(parent, id, x, y, w, h)
    classname = L"ElementHostClass"
    wc = WNDCLASSW(
        CS_HREDRAW | CS_VREDRAW,
        @cfunction(elementHostWndProc, LRESULT, (HWND, UINT, WPARAM, LPARAM)),
        0, 0,
        HINST,
        LoadIconW(HINSTANCE(0), IDI_INFORMATION),
        LoadCursorW(HINSTANCE(0), IDC_ARROW),
        HBRUSH(COLOR_WINDOW+1),
        C_NULL,
        pointer(classname))
    @preserve classname RegisterClassW(Ref(wc))
    hwnd = CreateWindowExW(DWORD(0), classname, L"ElementHost", WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS, x, y, w, h, parent, HMENU(id), HINST, LPVOID(0))
    return hwnd
end
