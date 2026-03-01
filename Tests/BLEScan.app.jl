# # Scan for BLE devices and print their addresses and names

# Wait for debugger to attach
@info "Waiting for debugger to attach..."
readline()

@info "Started"

include("../common/Win32.jl")
include("../common/combase.jl")
using LibBaseTsd, Printf, .W32 
import Base.Threads: @spawn

IID_Inspectable = GUID(0xaf86e2e0, 0xb12d, 0x4c6a, 0x9c5a, 0xd7aa65101e90)
IID_IUriFactory = GUID(0x44a9796c, 0x1108, 0x4541, 0xa279, 0x042f0bd441f1)
IID_IActivationFactory = GUID(0x00000035, 0x0000, 0x0000, 0xc000, 0x000000000046)
IID_IBluetoothLEAdvertisementFilter = GUID(0x131eb0d3, 0xd04e, 0x47b1, 0x837e, 0x49405bf6f80f)
IID_INoMarshal = GUID(0xecc8691b, 0xc1db, 0x4dc0, 0x855e, 0x65f6c551af49)
IID_Typed_Event_Handler = GUID(0x90eb4eca, 0xd465, 0x5ea0, 0xa61c, 0x033c8c5ecef2)

seen = Set{UInt64}()

@interface IActivationFactory begin
    @inherit IInspectable
    ActivateInstance(this::Ptr{IActivationFactory}, instance::Ptr{Ptr{IInspectable}})::HRESULT
end

const Classname_IBluetoothLEAdvertisementFilter = "Windows.Devices.Bluetooth.Advertisement.BluetoothLEAdvertisementFilter"
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

const Classname_IBluetoothLEAdvertisementWatcher = "Windows.Devices.Bluetooth.Advertisement.BluetoothLEAdvertisementWatcher"
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
    add_Received(this::Ptr{IBluetoothLEAdvertisementWatcher}, handler::Ptr{IEventHandler}, token::Ptr{UInt64})::HRESULT
    remove_Received(this::Ptr{IBluetoothLEAdvertisementWatcher}, token::UInt64)::HRESULT
    add_Stopped::Ptr{Cvoid}
    remove_Stopped::Ptr{Cvoid}
end

IID_IBluetoothLEAdvertisementWatcherFactory = GUID(0x9aaf2d56, 0x39ac, 0x453e, 0xb32a, 0x85c657e017f1)
@interface IBluetoothLEAdvertisementWatcherFactory begin
    @inherit IInspectable
    Create(this::Ptr{IBluetoothLEAdvertisementWatcherFactory}, advertisementFilter::Ptr{IBluetoothLEAdvertisementFilter}, value::Ptr{Ptr{IBluetoothLEAdvertisementWatcher}})::HRESULT
end

@interface IBluetoothLEAdvertisement begin
    @inherit IInspectable
    get_Flags::Ptr{Cvoid}
    put_Flags::Ptr{Cvoid}
    get_LocalName(this::Ptr{IBluetoothLEAdvertisement}, value::Ptr{HSTRING})::HRESULT
    put_LocalName::Ptr{Cvoid}
    get_ServiceUuids::Ptr{Cvoid}
    get_ManufacturerData::Ptr{Cvoid}
    get_DataSections::Ptr{Cvoid}
    get_GetManufacturerDataByCompanyId::Ptr{Cvoid}
    get_SectionsByType::Ptr{Cvoid}
end

@interface IBluetoothLEAdvertisementReceivedEventArgs begin
    @inherit IInspectable
    get_RawSignalStrengthInDBm(this::Ptr{IBluetoothLEAdvertisementReceivedEventArgs}, value::Ptr{Int16})::HRESULT
    get_BluetoothAddress(this::Ptr{IBluetoothLEAdvertisementReceivedEventArgs}, value::Ptr{UInt64})::HRESULT
    get_AdvertisementType::Ptr{Cvoid}
    get_Timestamp::Ptr{Cvoid}
    get_Advertisement(this::Ptr{IBluetoothLEAdvertisementReceivedEventArgs}, value::Ptr{Ptr{IBluetoothLEAdvertisement}})::HRESULT
end

const Classname_IBluetoothLEDevice = "Windows.Devices.Bluetooth.BluetoothLEDevice"
IID_IBluetoothLEDeviceStatics = GUID(0xC8CF1A19, 0xF0B6, 0x4BF0, 0x8689, 0x41303DE2D9F4)
@interface IBluetoothLEDeviceStatics begin
    @inherit IInspectable
    FromIdAsync::Ptr{Cvoid}
    FromBluetoothAddressAsync(this::Ptr{IBluetoothLEDeviceStatics}, bluetoothAddress::UInt64, operation::Ptr{Ptr{IAsyncOperation}})::HRESULT
    GetDeviceSelector::Ptr{Cvoid}
end

function RecievedCallback_QueryInterface(this::Ptr{IEventHandler}, riid::Ptr{GUID}, ppv::Ptr{Ptr{Cvoid}})::HRESULT
    guid = unsafe_load(riid)
    # @info "Received QueryInterface: $guid"
    if guid == IID_IUnknown || guid == IID_Typed_Event_Handler
        unsafe_store!(ppv, this)
        return S_OK
    end
    unsafe_store!(ppv, C_NULL)
    return reinterpret(HRESULT, E_NOINTERFACE)
end

RecievedCallback_AddRef(this::Ptr{IEventHandler})::UInt32 = return 1
RecievedCallback_Release(this::Ptr{IEventHandler})::UInt32 = return 1

function AsyncCompletedHandler_QueryInterface(this::Ptr{IAsyncOperationCompletedHandler}, riid::Ptr{GUID}, ppv::Ptr{Ptr{Cvoid}})::HRESULT
    guid = unsafe_load(riid)
    @info "Received QueryInterface: $guid"
    if guid == IID_IUnknown || guid == IID_IAsyncOperationCompletedHandler
        unsafe_store!(ppv, this)
        return S_OK
    end
    unsafe_store!(ppv, C_NULL)
    return reinterpret(HRESULT, E_NOINTERFACE)
end

AsyncCompletedHandler_AddRef(this::Ptr{IAsyncOperationCompletedHandler})::UInt32 = return 1
AsyncCompletedHandler_Release(this::Ptr{IAsyncOperationCompletedHandler})::UInt32 = return 1

# ---- Main code ----

hr = RoInitialize(RO_INIT_MULTITHREADED)
ppv = PVOID() |> Ref

# Helpers
RoGetActivationFactory(Classname_IBluetoothLEDevice, Ref(IID_IBluetoothLEDeviceStatics), ppv) |> AssertSuccess
bledevice = Ptr{IBluetoothLEDeviceStatics}(ppv[]) |> Ref

# Create a filter for the watcher
RoGetActivationFactory(Classname_IBluetoothLEAdvertisementFilter, Ref(IID_IActivationFactory), ppv) |> AssertSuccess
activation_factory = Ptr{IActivationFactory}(ppv[])
insp = Ptr{IInspectable}(C_NULL) |> Ref
ActivateInstance(activation_factory, insp) |> AssertSuccess
QueryInterface(insp[], Ref(IID_IBluetoothLEAdvertisementFilter), ppv) |> AssertSuccess
filter = Ptr{IBluetoothLEAdvertisementFilter}(ppv[])
@info "Filter: $(filter)"

# Create the watcher
RoGetActivationFactory(Classname_IBluetoothLEAdvertisementWatcher, Ref(IID_IBluetoothLEAdvertisementWatcherFactory), ppv) |> AssertSuccess
factory = Ptr{IBluetoothLEAdvertisementWatcherFactory}(ppv[])
@info "Factory: $(factory)"

watcher = Ptr{IBluetoothLEAdvertisementWatcher}(C_NULL) |> Ref
Create(factory, filter, watcher) |> AssertSuccess
@info "Watcher: $(watcher[])"

filter = Ptr{IBluetoothLEAdvertisementFilter}(C_NULL) |> Ref
get_AdvertisementFilter(watcher[], filter) |> AssertSuccess
@info "Filter: $(filter[])"

function AsyncOperationCompletedHandler_Invoke(this::Ptr{IAsyncOperationCompletedHandler}, asyncInfo::Ptr{IAsyncInfo}, asyncStatus::AsyncStatus)::HRESULT
    @info "Async operation completed with status: $asyncStatus"
    return S_OK
end

asyncCompletedHandlerImp = IAsyncOperationCompletedHandlerVtbl(
    IUnknownVtbl(
        @cfunction(AsyncCompletedHandler_QueryInterface, HRESULT, (Ptr{IAsyncOperationCompletedHandler}, Ptr{GUID}, Ptr{Ptr{Cvoid}})),
        @cfunction(AsyncCompletedHandler_AddRef, UInt32, (Ptr{IAsyncOperationCompletedHandler},)),
        @cfunction(AsyncCompletedHandler_Release, UInt32, (Ptr{IAsyncOperationCompletedHandler},))
    ),
    @cfunction(AsyncOperationCompletedHandler_Invoke, HRESULT, (Ptr{IAsyncOperationCompletedHandler}, Ptr{IAsyncInfo}, AsyncStatus))
) |> Ref
asyncCompletedHandler = IAsyncOperationCompletedHandler(pointer_from_objref(asyncCompletedHandlerImp)) |> Ref

# IID_IAsyncOperation_BluetoothLEDevice = GUID(0xea7c76c4, 0x7310, 0x529e, 0x9c15, 0x6f3940f5a46e)

function RecievedCallback_Invoke(this::Ptr{IEventHandler}, watcher::Ptr{IBluetoothLEAdvertisementWatcher}, eventArgs::Ptr{Cvoid})::HRESULT
    # try
        # @info "Received Invoke"
        eventArgs = Ptr{IBluetoothLEAdvertisementReceivedEventArgs}(eventArgs)
        addr = UInt64(0) |> Ref
        get_BluetoothAddress(eventArgs, addr) |> AssertSuccess
        if !(addr[] in seen)
            push!(seen, addr[])
            signal = Int16(0) |> Ref
            get_RawSignalStrengthInDBm(eventArgs, signal) |> AssertSuccess
            addrstr = @sprintf("%012X", addr[])
            advertisement = Ptr{IBluetoothLEAdvertisement}(C_NULL) |> Ref
            get_Advertisement(eventArgs, advertisement) |> AssertSuccess
            hlocalname = HSTRING() |> Ref
            get_LocalName(advertisement[], hlocalname) |> AssertSuccess
            plocalname = WindowsGetStringRawBuffer(hlocalname[], C_NULL) 
            len = WindowsGetStringLen(hlocalname[])
            localname = unsafe_wrap(Array, plocalname, len) |> v -> transcode(String, v)
            @info "Invoke: Address: $addrstr Signal Strength: $(signal[]) Local Name: $(localname)"
            asyncop = Ptr{IAsyncOperation}(C_NULL) |> Ref
            hr = FromBluetoothAddressAsync(bledevice[], addr[], asyncop)
            if hr == S_OK
                @info "Got async operation: $(asyncop[])"
                QueryInterface(asyncop[], Ref(IID_IUnknown), ppv) |> AssertSuccess
                QueryInterface(asyncop[], Ref(IID_IInspectable), ppv) |> AssertSuccess
                QueryInterface(asyncop[], Ref(IID_IAsyncInfo), ppv) |> AssertSuccess

                # Dump the vtable for debugging
                unsafe_load(asyncop[]).lpvtbl |> unsafe_load |> dump

                level = TrustLevel(0) |> Ref
                GetTrustLevel(insp[], level) |> AssertSuccess
                @info "Trust level: $(level[])"

# @ccall DebugBreak()::Cvoid
# @ccall SetConsoleTitleW("Debug Console"::Cwstring)::Cvoid

                # Crashes
                id = Int32(0) |> Ref
                asyncinfo = Ptr{IAsyncInfo}(asyncop[]) |> Ref
                get_Id(asyncinfo[], id) |> AssertSuccess


                # QueryInterface(asyncop[], Ref(IID_IAsyncOperation_BluetoothLEDevice), ppv) |> AssertSuccess

                # @info "AddRef" AddRef(asyncop[])
                # @info "Release" Release(asyncop[])

                # count = UInt32(0) |> Ref
                # ids = Ptr{GUID}(C_NULL) |> Ref
                # insp = Ptr{IInspectable}(asyncop[]) |> Ref
                # GetIids(insp[], count, ids) |> AssertSuccess

                # GetRuntimeClassName(asyncop[], HSTRING(0) |> Ref) |> AssertSuccess

                # get_Status(asyncop[], ppv) |> AssertSuccess
                # get_ErrorCode(asyncop[], ppv) |> AssertSuccess
                # put_Completed(asyncop[], asyncCompletedHandler) |> AssertSuccess
            else
                @error "Error calling FromBluetoothAddressAsync: $hr"
            end
        end
    # catch e
    #     @error "Error in callback: $e"
    # end
    return S_OK
end

eventHandlerImp = IEventHandlerVtbl(
    IUnknownVtbl(
        @cfunction(RecievedCallback_QueryInterface, HRESULT, (Ptr{IEventHandler}, Ptr{GUID}, Ptr{Ptr{Cvoid}})),
        @cfunction(RecievedCallback_AddRef, UInt32, (Ptr{IEventHandler},)),
        @cfunction(RecievedCallback_Release, UInt32, (Ptr{IEventHandler},))
    ),
    @cfunction(RecievedCallback_Invoke, HRESULT, (Ptr{IEventHandler}, Ptr{IBluetoothLEAdvertisementWatcher}, Ptr{Cvoid}))
) |> Ref
eventHandler = IEventHandler(pointer_from_objref(eventHandlerImp)) |> Ref

status = BluetoothLEAdvertisementWatcherStatus(0) |> Ref
mode = BluetoothLEScanningMode(0) |> Ref
token = UInt64(0) |> Ref

put_ScanningMode(watcher[], Active) |> AssertSuccess
add_Received(watcher[], eventHandler, token)
Start(watcher[]) |> AssertSuccess
for i in 10:-1:1
    get_Status(watcher[], status) |> AssertSuccess
    get_ScanningMode(watcher[], mode) |> AssertSuccess
    @info "($i) Status: $(status[]) Mode: $(mode[])"
    sleep(5)
end
put_ScanningMode(watcher[], Passive) |> AssertSuccess
Stop(watcher[]) |> AssertSuccess

@info "Waiting..."
wait() # Forever

@info "Done"

# TODO
# - GetGattServicesAsync
# - GetGattCharacteristicsAsync
# - GetGattDescriptorsAsync
