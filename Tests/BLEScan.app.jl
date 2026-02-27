# Scan for BLE devices and print their addresses and names

include("../common/Win32.jl")
include("../common/combase.jl")
using LibBaseTsd, .W32 

WindowsCreateString(mr::MemoryRef{UInt16}) = WindowsCreateString(mr.mem)

hr = RoInitialize(RO_INIT_MULTITHREADED)
classid = WindowsCreateString(L"Windows.Devices.Bluetooth.Advertisement.BluetoothLEAdvertisementWatcher") |> AssertSuccess
iid_watcher = GUID(0x61121870, 0x34ad, 0x4bbd, 0xb117, 0x57014237e8c0)

factory = PVOID() |> Ref
RoGetActivationFactory(classid, Ref(iid_watcher), factory) |> AssertSuccess

