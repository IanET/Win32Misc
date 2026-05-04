using PNGFiles, ColorTypes, FixedPointNumbers

const ASSETS_DIR = joinpath(@__DIR__, "..", "Provider", "Assets")

function make_rounded_rect_png(w::Int, h::Int, r::Int, color::RGBA{N0f8})
    img = fill(RGBA{N0f8}(0, 0, 0, 0), h, w)
    for y in 1:h, x in 1:w
        cx = clamp(x, r+1, w-r)
        cy = clamp(y, r+1, h-r)
        (x-cx)^2 + (y-cy)^2 <= r^2 && (img[y, x] = color)
    end
    img
end

gray = RGBA{N0f8}(N0f8(0.18), N0f8(0.18), N0f8(0.18), N0f8(1.0))
img  = make_rounded_rect_png(300, 48, 10, gray)
path = joinpath(ASSETS_DIR, "item-bg.png")
PNGFiles.save(path, img)
println("Written $(filesize(path)) bytes to $path")
