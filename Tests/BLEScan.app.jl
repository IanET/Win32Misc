# # Scan for BLE devices and print their addresses and names

include("../common/Win32.jl")
include("../common/combase.jl")
using LibBaseTsd, .W32 

# {AF86E2E0-B12D-4C6A-9C5A-D7AA65101E90}
IID_Inspectable = GUID(0xaf86e2e0, 0xb12d, 0x4c6a, 0x9c5a, 0xd7aa65101e90)
IID_IUriFactory = GUID(0x44a9796c, 0x1108, 0x4541, 0xa279, 0x042f0bd441f1)
IID_IUNKNOWN = GUID(0x00000000, 0x0000, 0x0000, 0xc000, 0x000000000046)
IID_IActivationFactory = GUID(0x00000035, 0x0000, 0x0000, 0xc000, 0x000000000046)

# IID_IBluetoothLEAdvertisementWatcherFactory = GUID(0x9aaf2d56, 0x39ac, 0x453e, 0xb32a, 0x85c657e017f1)
IID_IBluetoothLEAdvertisementWatcherFactory = GUID(0xa6ac336f, 0xf3d3, 0x4297, 0x8d6c, 0xc81ea6623f40)

hr = RoInitialize(RO_INIT_MULTITHREADED)

classname = WindowsCreateString("Windows.Devices.Bluetooth.Advertisement.BluetoothLEAdvertisementWatcher") |> AssertSuccess
factory = PVOID() |> Ref
RoGetActivationFactory(classname, Ref(IID_Inspectable), factory) |> AssertSuccess

# classname = WindowsCreateString("Windows.Foundation.Uri") |> AssertSuccess
# factory = PVOID() |> Ref
# RoGetActivationFactory(classname, Ref(IID_Inspectable), factory) |> AssertSuccess

# classname = WindowsCreateString("Windows.Foundation.Collections.PropertySet") |> AssertSuccess
# propset = PVOID() |> Ref
# RoGetActivationFactory(classname, Ref(IID_IInspectable), propset) |> AssertSuccess

