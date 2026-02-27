# Scan for BLE devices and print their addresses and names

include("../common/Win32.jl")
include("../common/combase.jl")
using LibBaseTsd, .W32 

WindowsCreateString(mr::MemoryRef{UInt16}) = WindowsCreateString(mr.mem)
# WindowsGetStringLen(str) = @ccall Combase.WindowsGetStringLen(str::PVOID)::UINT
# WindowsGetStringRawBuffer(str, len) = @ccall Combase.WindowsGetStringRawBuffer(str::PVOID, len::Ref{UINT})::Ptr{UInt16}

hr = RoInitialize(RO_INIT_MULTITHREADED)
classname = WindowsCreateString(L"Windows.Devices.Bluetooth.Advertisement.IBluetoothLEAdvertisementWatcherFactory") |> AssertSuccess
IID_IBluetoothLEAdvertisementWatcherFactory = GUID(0x9aaf2d56, 0x39ac, 0x453e, 0xb32a, 0x85c657e017f1)

factory = PVOID() |> Ref
RoGetActivationFactory(classname, Ref(IID_IBluetoothLEAdvertisementWatcherFactory), factory) |> AssertSuccess

classname = WindowsCreateString(L"Windows.Foundation.Uri") |> AssertSuccess
IID_IUriFactory = GUID(0x44a9796c, 0x1108, 0x4541, 0xa279, 0x042f0bd441f1)
RoGetActivationFactory(classname, Ref(IID_IUriFactory), factory) |> AssertSuccess