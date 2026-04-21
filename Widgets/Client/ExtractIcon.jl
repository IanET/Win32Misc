include("ATWindows.jl")
include("IconToPng.jl")

const IMAGERES   = "C:\\Windows\\System32\\imageres.dll"
const ICON_INDEX = 262

hm    = W32.GetModuleHandleW(C_NULL)
hicon = W32.ExtractIconW(hm, transcode(UInt16, IMAGERES * "\0"), ICON_INDEX)
(hicon == C_NULL || Int(hicon) == 1) && error("ExtractIconW failed — check index $ICON_INDEX")

for (path, sz) in [
    ("..\\Provider\\ProviderAssets\\TaskSwitcher_Icon.png",       32),
    ("..\\Provider\\ProviderAssets\\TaskSwitcher_Screenshot.png", 256),
    ("..\\Provider\\Assets\\StoreLogo.png",                       50),
]
    png = icon_to_png_bytes(hicon, sz)
    png === nothing && error("icon_to_png_bytes returned nothing for $path")
    write(path, png)
    println("Written $(length(png)) bytes to $path")
end
