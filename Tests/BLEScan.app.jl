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

@kwdef mutable struct IRecievedCallbackVtbl <: Vtbl
    QueryInterface::Ptr{Cvoid} = C_NULL
    AddRef::Ptr{Cvoid} = C_NULL
    Release::Ptr{Cvoid} = C_NULL
    Invoke::Ptr{Cvoid} = C_NULL
end
const IRecievedCallback = Interface{IRecievedCallbackVtbl}

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
    get_AdvertisementFilter(this::Ptr{IBluetoothLEAdvertisementWatcher}, value::Ptr{Ptr{IBluetoothLEAdvertisementFilter}})::HRESULT
    put_AdvertisementFilter(this::Ptr{IBluetoothLEAdvertisementWatcher}, value::Ptr{IBluetoothLEAdvertisementFilter})::HRESULT
    Start(this::Ptr{IBluetoothLEAdvertisementWatcher})::HRESULT
    Stop(this::Ptr{IBluetoothLEAdvertisementWatcher})::HRESULT
    add_Received(this::Ptr{IBluetoothLEAdvertisementWatcher}, handler::Ptr{IRecievedCallback}, token::Ptr{UInt64})::HRESULT
    remove_Received(this::Ptr{IBluetoothLEAdvertisementWatcher}, token::UInt64)::HRESULT
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

filter = Ptr{IBluetoothLEAdvertisementFilter}(C_NULL) |> Ref
get_AdvertisementFilter(watcher[], filter) |> AssertSuccess
@info "Filter: $(filter[])"

IID_INoMarshal = GUID(0xecc8691b, 0xc1db, 0x4dc0, 0x855e, 0x65f6c551af49)
IID_Typed_Event_Handler = GUID(0x90eb4eca, 0xd465, 0x5ea0, 0xa61c, 0x033c8c5ecef2)

function RecievedCallback_QueryInterface(this::Ptr{IRecievedCallback}, riid::Ptr{GUID}, ppv::Ptr{Ptr{Cvoid}})::HRESULT
    guid = unsafe_load(riid)
    # @info "Received QueryInterface: $guid"
    if guid == IID_IUNKNOWN || guid == IID_Typed_Event_Handler
        unsafe_store!(ppv, this)
        return S_OK
    end
    unsafe_store!(ppv, C_NULL)
    return reinterpret(HRESULT, E_NOINTERFACE)
end

function RecievedCallback_AddRef(this::Ptr{IRecievedCallback})::UInt32
    # @info "Received AddRef"
    return 1
end

function RecievedCallback_Release(this::Ptr{IRecievedCallback})::UInt32
    # @info "Received Release"
    return 1
end

function RecievedCallback_Invoke(this::Ptr{IRecievedCallback}, watcher::Ptr{IBluetoothLEAdvertisementWatcher}, eventArgs::Ptr{Cvoid})::HRESULT
    @info "Received Invoke"
    return S_OK
end

vtbl = IRecievedCallbackVtbl()
vtbl.QueryInterface = @cfunction(RecievedCallback_QueryInterface, HRESULT, (Ptr{IRecievedCallback}, Ptr{GUID}, Ptr{Ptr{Cvoid}}))
vtbl.AddRef = @cfunction(RecievedCallback_AddRef, UInt32, (Ptr{IRecievedCallback},))
vtbl.Release = @cfunction(RecievedCallback_Release, UInt32, (Ptr{IRecievedCallback},))
vtbl.Invoke = @cfunction(RecievedCallback_Invoke, HRESULT, (Ptr{IRecievedCallback}, Ptr{IBluetoothLEAdvertisementWatcher}, Ptr{Cvoid})) 
recived_callback = Interface{IRecievedCallbackVtbl}(pointer_from_objref(vtbl)) 
jco = JComObj{IRecievedCallback}(Ref(recived_callback))

status = BluetoothLEAdvertisementWatcherStatus(0) |> Ref
mode = BluetoothLEScanningMode(0) |> Ref
token = UInt64(0) |> Ref

put_ScanningMode(watcher[], Active) |> AssertSuccess
add_Received(watcher[], jco[], token)
Start(watcher[]) |> AssertSuccess
for i in 25:-1:1
    get_Status(watcher[], status) |> AssertSuccess
    get_ScanningMode(watcher[], mode) |> AssertSuccess
    @info "($i) Status: $(status[]) Mode: $(mode[])"
    sleep(1)
end
put_ScanningMode(watcher[], Passive) |> AssertSuccess
Stop(watcher[]) |> AssertSuccess

@info "Done"