# # Scan for BLE devices and print their addresses and names

include("../common/Win32.jl")
include("../common/combase.jl")
using LibBaseTsd, .W32 

# {AF86E2E0-B12D-4C6A-9C5A-D7AA65101E90}
IID_Inspectable = GUID(0xaf86e2e0, 0xb12d, 0x4c6a, 0x9c5a, 0xd7aa65101e90)
IID_IUriFactory = GUID(0x44a9796c, 0x1108, 0x4541, 0xa279, 0x042f0bd441f1)
IID_IUNKNOWN = GUID(0x00000000, 0x0000, 0x0000, 0xc000, 0x000000000046)
IID_IActivationFactory = GUID(0x00000035, 0x0000, 0x0000, 0xc000, 0x000000000046)
IID_IBluetoothLEAdvertisementFilter = GUID(0x131eb0d3, 0xd04e, 0x47b1, 0x837e, 0x49405bf6f80f)

@interface IActivationFactory begin
    @inherit IInspectable
    ActivateInstance(this::Ptr{IActivationFactory}, instance::Ptr{Ptr{IInspectable}})::HRESULT
end

@interface IBluetoothLEAdvertisementFilter begin
    @inherit IInspectable
    # TODO
end

@cenum BluetoothLEAdvertisementWatcherStatus begin
    Created = 0
    Started = 1
    Stopping = 2
    Stopped = 3
    Aborted = 4
end

@cenum BluetoothLEScanningMode begin
    Passive = 0
    Active = 1
end

@interface IBluetoothLEAdvertisementWatcher begin
    @inherit IInspectable
    get_MinSamplingInterval::Ptr{Cvoid}
    get_MaxSamplingInterval::Ptr{Cvoid}
    get_MinOutOfRangeTimeout::Ptr{Cvoid}
    get_MaxOutOfRangeTimeout::Ptr{Cvoid}
    get_Status(this::Ptr{IBluetoothLEAdvertisementWatcher}, value::Ptr{BluetoothLEAdvertisementWatcherStatus})::HRESULT
    get_ScanningMode(this::Ptr{IBluetoothLEAdvertisementWatcher}, value::Ptr{BluetoothLEScanningMode})::HRESULT
    put_ScanningMode(this::Ptr{IBluetoothLEAdvertisementWatcher}, value::BluetoothLEScanningMode)::HRESULT
    get_SignalStrengthFilter::Ptr{Cvoid}
    put_SignalStrengthFilter::Ptr{Cvoid}
    get_AdvertisementFilter::Ptr{Cvoid}
    put_AdvertisementFilter::Ptr{Cvoid}
    Start(this::Ptr{IBluetoothLEAdvertisementWatcher})::HRESULT
    Stop(this::Ptr{IBluetoothLEAdvertisementWatcher})::HRESULT
    add_Received::Ptr{Cvoid}
    remove_Received::Ptr{Cvoid}
    add_Stopped::Ptr{Cvoid}
    remove_Stopped::Ptr{Cvoid}
end

IID_IBluetoothLEAdvertisementWatcherFactory = GUID(0x9aaf2d56, 0x39ac, 0x453e, 0xb32a, 0x85c657e017f1)
@interface IBluetoothLEAdvertisementWatcherFactory begin
    @inherit IInspectable
    Create(this::Ptr{IBluetoothLEAdvertisementWatcherFactory}, advertisementFilter::Ptr{IBluetoothLEAdvertisementFilter}, value::Ptr{Ptr{IBluetoothLEAdvertisementWatcher}})::HRESULT
end

hr = RoInitialize(RO_INIT_MULTITHREADED)
ppv = PVOID() |> Ref

# Create a filter for the watcher
RoGetActivationFactory("Windows.Devices.Bluetooth.Advertisement.BluetoothLEAdvertisementFilter", Ref(IID_IActivationFactory), ppv) |> AssertSuccess
activation_factory = Ptr{IActivationFactory}(ppv[])
insp = Ptr{IInspectable}(C_NULL) |> Ref
ActivateInstance(activation_factory, insp) |> AssertSuccess
QueryInterface(insp[], Ref(IID_IBluetoothLEAdvertisementFilter), ppv) |> AssertSuccess
filter = Ptr{IBluetoothLEAdvertisementFilter}(ppv[])
@info "Filter: $(filter)"

# Create the watcher
RoGetActivationFactory("Windows.Devices.Bluetooth.Advertisement.BluetoothLEAdvertisementWatcher", Ref(IID_Inspectable), ppv) |> AssertSuccess
insp = Ptr{IInspectable}(ppv[])
QueryInterface(insp, Ref(IID_IBluetoothLEAdvertisementWatcherFactory), ppv) |> AssertSuccess
factory = Ptr{IBluetoothLEAdvertisementWatcherFactory}(ppv[])
@info "Factory: $(factory)"

watcher = Ptr{IBluetoothLEAdvertisementWatcher}(C_NULL) |> Ref
Create(factory, filter, watcher) |> AssertSuccess
@info "Watcher: $(watcher[])"

status = BluetoothLEAdvertisementWatcherStatus(0) |> Ref
mode = BluetoothLEScanningMode(0) |> Ref

put_ScanningMode(watcher[], Active) |> AssertSuccess
Start(watcher[]) |> AssertSuccess
for i in 1:10
    get_Status(watcher[], status) |> AssertSuccess
    get_ScanningMode(watcher[], mode) |> AssertSuccess
    @info "Status: $(status[]) Mode: $(mode[])"
    sleep(1)
end
Stop(watcher[]) |> AssertSuccess

@info "Done"