# IconToPng.jl — requires W32 already in scope via ATWindows.jl include
using PNGFiles, ColorTypes, FixedPointNumbers

function icon_to_png_bytes(hicon::W32.HICON, sz::Int = 32)::Union{Vector{UInt8}, Nothing}
    hicon == C_NULL && return nothing

    hdc_scr = W32.GetDC(C_NULL)
    hdc     = W32.CreateCompatibleDC(hdc_scr)
    W32.ReleaseDC(C_NULL, hdc_scr)

    bmi = Ref(W32.BITMAPINFO(bmiHeader = W32.BITMAPINFOHEADER(
        biSize        = UInt32(sizeof(W32.BITMAPINFOHEADER)),
        biWidth       = Int32(sz),
        biHeight      = Int32(-sz),     # negative = top-down scanlines
        biPlanes      = UInt16(1),
        biBitCount    = UInt16(32),
        biCompression = UInt32(W32.BI_RGB),
    )))
    ppvBits = Ref{Ptr{Cvoid}}(C_NULL)
    hbm = W32.CreateDIBSection(hdc, bmi, W32.DIB_RGB_COLORS, ppvBits, C_NULL, UInt32(0))
    if hbm == C_NULL
        W32.DeleteDC(hdc)
        return nothing
    end

    W32.SelectObject(hdc, hbm)
    W32.DrawIconEx(hdc, 0, 0, hicon, sz, sz, 0, C_NULL, W32.DI_NORMAL)

    nbytes = sz * sz * 4
    bgra   = unsafe_wrap(Array, Ptr{UInt8}(ppvBits[]), nbytes; own=false)
    rgba   = copy(bgra)
    for i in 1:4:nbytes
        rgba[i], rgba[i+2] = rgba[i+2], rgba[i]    # BGRA → RGBA
    end

    W32.DeleteObject(hbm)
    W32.DeleteDC(hdc)

    img = rgba |> x -> reinterpret(RGBA{N0f8}, x) |> x -> reshape(x, sz, sz) |> permutedims
    buf = IOBuffer()
    PNGFiles.save(buf, img)
    take!(buf)
end
