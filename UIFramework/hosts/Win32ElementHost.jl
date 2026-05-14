
const _hosts = Dict{HWND, AbstractElement}()

function onElementHostDestroy(hwnd)::LRESULT
    delete!(_hosts, hwnd)
    return 0
end

function onElementHostPaint(hwnd)::LRESULT
    ps = PAINTSTRUCT() |> Ref
    hdc = BeginPaint(hwnd, ps)
    if haskey(_hosts, hwnd)
        e = _hosts[hwnd]
        rcclient = LibBaseTsd.RECT() |> Ref
        GetClientRect(hwnd, rcclient)
        w = rcclient[].right - rcclient[].left
        h = rcclient[].bottom - rcclient[].top
        if w > 0 && h > 0
            pixmap = paint(e, w, h)
            if pixmap !== nothing
                bmih = BITMAPINFOHEADER(sizeof(BITMAPINFOHEADER), w, -h, 1, 32, BI_RGB, 0, 0, 0, 0, 0) |> Ref
                bmpinfo = BITMAPINFO(bmih[], (RGBQUAD(),)) |> Ref
                @preserve pixmap SetDIBitsToDevice(hdc, 0, 0, w, h, 0, 0, 0, h, Ptr{Cvoid}(pointer(pixmap)), bmpinfo, DIB_RGB_COLORS)
            end
        end
    end
    EndPaint(hwnd, ps)
    return 0
end

function onElementHostResize(hwnd, w, h)::LRESULT
    haskey(_hosts, hwnd) && resize(_hosts[hwnd], w, h)
    return 0
end

function onElementHostClick(hwnd)::LRESULT
    haskey(_hosts, hwnd) && click(_hosts[hwnd])
    return 0
end

function onElementHostPressed(hwnd)::LRESULT
    haskey(_hosts, hwnd) && press(_hosts[hwnd])
    return 0
end

function onElementHostHover(hwnd)::LRESULT
    if haskey(_hosts, hwnd)
        hover(_hosts[hwnd])
        tme = TRACKMOUSEEVENT(hwnd) |> Ref
        TrackMouseEvent(tme)
    end
    return 0
end

function onElementHostUnhover(hwnd)::LRESULT
    haskey(_hosts, hwnd) && unhover(_hosts[hwnd])
    return 0
end

function elementHostWndProc(hwnd::HWND, umsg::UINT, wparam::WPARAM, lparam::LPARAM)::LRESULT
    try
        if umsg == WM_DESTROY
            return onElementHostDestroy(hwnd)
        elseif umsg == WM_PAINT
            return onElementHostPaint(hwnd)
        elseif umsg == WM_SIZE
            return onElementHostResize(hwnd, LOWORD(lparam), HIWORD(lparam))
        elseif umsg == WM_LBUTTONDOWN
            return onElementHostPressed(hwnd)
        elseif umsg == WM_LBUTTONUP
            return onElementHostClick(hwnd)
        elseif umsg == WM_MOUSEMOVE
            return onElementHostHover(hwnd)
        elseif umsg == WM_MOUSELEAVE
            return onElementHostUnhover(hwnd)
        end
        return DefWindowProcW(hwnd, umsg, wparam, lparam)
    catch exc
        @error exc
        throw(exc)
    end

    return 0
end

function registerElement(hwnd::HWND, e::AbstractElement)
    _hosts[hwnd] = e
    element(e).repaint = () -> InvalidateRect(hwnd, C_NULL, FALSE)
end

function createElementHost(parent::HWND, e::AbstractElement, id::Int, x::Int, y::Int, w::Int, h::Int)
    hwnd = createElementHost(parent, id, x, y, w, h)
    registerElement(hwnd, e)
    return hwnd
end

function layout(hwnd::HWND, gl::GridLayout)
    rcparent = LibBaseTsd.RECT() |> Ref
    GetClientRect(hwnd, rcparent)
    rc = rcparent[]
    rects = computeLayout(Int(rc.right - rc.left), Int(rc.bottom - rc.top), gl)
    for (id, (x, y, w, h)) in rects
        child = GetDlgItem(hwnd, id)
        child != HWND(0) && SetWindowPos(child, HWND(0), x, y, w, h, SWP_NOZORDER)
    end
end

function createElementHost(parent::HWND, id::Int, x::Int, y::Int, w::Int, h::Int)
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
