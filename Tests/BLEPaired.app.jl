@info "Started"

include("../common/Win32.jl")
include("../common/combase.jl")
using LibBaseTsd, Printf, .W32 

# Get the BluetoothLEDevice 
IID_IBluetoothLEDevice = GUID(0x1ecee3e6, 0x0b9c, 0x4f8d, 0x87b2, 0x364d62cde1a7)
IID_IActivationFactory = GUID(0x00000035, 0x0000, 0x0000, 0xc000, 0x000000000046)
IID_IBluetoothLEDeviceStatics = GUID(0xC8CF1A19, 0xF0B6, 0x4BF0, 0x8689, 0x41303DE2D9F4)
IID_IBluetoothLEDeviceStatics2 = GUID(0x5F12C06B, 0x3BAC, 0x43E8, 0xAD16, 0x563271BD41C2)

const Classname_IBluetoothLEDevice = "Windows.Devices.Bluetooth.BluetoothLEDevice"

@interface IBluetoothLEDeviceStatics2 begin
    @inherit IInspectable
    GetDeviceSelectorFromPairingState(this::Ptr{IBluetoothLEDeviceStatics2}, paired::Bool, selector::Ref{HSTRING})::HRESULT
    GetDeviceSelectorFromConnectionStatus::Ptr{Cvoid}
    GetDeviceSelectorFromDeviceName::Ptr{Cvoid}
    GetDeviceSelectorFromBluetoothAddress::Ptr{Cvoid}
    GetDeviceSelectorFromBluetoothAddressWithBluetoothAddressType::Ptr{Cvoid}
    GetDeviceSelectorFromAppearance::Ptr{Cvoid}
    FromBluetoothAddressWithBluetoothAddressTypeAsync::Ptr{Cvoid}
end

# DeviceInformation interfaces
IID_IDeviceInformationStatics = GUID(0xC17F100E, 0x3A46, 0x4A78, 0x8013, 0x769DC9B97390)
const Classname_IDeviceInformation = "Windows.Devices.Enumeration.DeviceInformation"

@interface IDeviceInformationStatics begin
    @inherit IInspectable
    CreateFromIdAsync::Ptr{Cvoid}
    CreateFromIdAsyncAdditionalProperties::Ptr{Cvoid}
    FindAllAsync(this::Ptr{IDeviceInformationStatics}, aqsFilter::HSTRING, operation::Ptr{Ptr{IAsyncOperation}})::HRESULT
    FindAllAsyncDeviceClass::Ptr{Cvoid}
    FindAllAsyncDeviceClassAdditionalProperties::Ptr{Cvoid}
    CreateWatcher::Ptr{Cvoid}
    CreateWatcherDeviceClass::Ptr{Cvoid}
    CreateWatcherAqsFilter::Ptr{Cvoid}
    CreateWatcherAqsFilterDeviceClass::Ptr{Cvoid}
end

@interface IDeviceInformation begin
    @inherit IInspectable
    get_Id(this::Ptr{IDeviceInformation}, value::Ref{HSTRING})::HRESULT
    get_Name(this::Ptr{IDeviceInformation}, value::Ref{HSTRING})::HRESULT
    get_IsEnabled(this::Ptr{IDeviceInformation}, value::Ref{Bool})::HRESULT
    get_IsDefault::Ptr{Cvoid}
    get_EnclosureLocation::Ptr{Cvoid}
    get_Properties::Ptr{Cvoid}
    Update::Ptr{Cvoid}
    GetThumbnailAsync::Ptr{Cvoid}
    GetGlyphThumbnailAsync::Ptr{Cvoid}
end

# Assuming IVectorView_IDeviceInformation is defined similarly
@interface IVectorView_IDeviceInformation begin
    @inherit IInspectable
    GetAt(this::Ptr{IVectorView_IDeviceInformation}, index::UInt32, item::Ref{Ptr{IDeviceInformation}})::HRESULT
    get_Size(this::Ptr{IVectorView_IDeviceInformation}, size::Ref{UInt32})::HRESULT
    IndexOf::Ptr{Cvoid}
    GetMany::Ptr{Cvoid}
end

@interface IDeviceInformationCollection begin
    @inherit IVectorView_IDeviceInformation
end

# IID for IAsyncOperation<DeviceInformationCollection*>
# Computed as SHA-1 of "pinterface(9fc2b0bbe44644e2aa619cab8f636af2;Windows.Devices.Enumeration.DeviceInformationCollection)"
IID_IAsyncOperation_DeviceInformationCollection = GUID(0x000000b1, 0x001f, 0x0072, 0x190c, 0x55d541d66033)

# --- Main Code ---

hr = RoInitialize(RO_INIT_MULTITHREADED)

ppv = Ptr{Cvoid}(C_NULL) |> Ref
RoGetActivationFactory(Classname_IBluetoothLEDevice, Ref(IID_IBluetoothLEDeviceStatics2), ppv) |> AssertSuccess 
bledevicestatics2 = Ptr{IBluetoothLEDeviceStatics2}(ppv[])

hs = HSTRING() |> Ref
GetDeviceSelectorFromPairingState(bledevicestatics2, true, hs) |> AssertSuccess
@info "AQS Filter: $(HstringToString(hs[]))"

# Now get DeviceInformation statics
RoGetActivationFactory(Classname_IDeviceInformation, Ref(IID_IDeviceInformationStatics), ppv) |> AssertSuccess
deviceInfoStatics = Ptr{IDeviceInformationStatics}(ppv[])

# Call FindAllAsync
asyncOp = Ptr{IAsyncOperation}(C_NULL) |> Ref
FindAllAsync(deviceInfoStatics, hs[], asyncOp) |> AssertSuccess
@assert asyncOp[] != C_NULL

# Query for the specific interface if needed, but since GetResults returns the result, proceed
result = Ptr{Cvoid}(C_NULL) |> Ref
GetResults(asyncOp[], result) |> AssertSuccess
collection = Ptr{IDeviceInformationCollection}(result[])

# Get size
size = UInt32(0) |> Ref
get_Size(collection, size) |> AssertSuccess

println("Found $(size[]) paired BLE devices:")

for i in 0:(size[] - 1)
    device = Ptr{IDeviceInformation}(C_NULL) |> Ref
    GetAt(collection, i, device) |> AssertSuccess
    
    name = HSTRING() |> Ref
    get_Name(device[], name) |> AssertSuccess
    
    id = HSTRING() |> Ref
    get_Id(device[], id) |> AssertSuccess
    
    isEnabled = Bool(false) |> Ref
    get_IsEnabled(device[], isEnabled) |> AssertSuccess
    
    println("Name: $(name[])")
    println("ID: $(id[])")
    println("Is Enabled: $(isEnabled[])")
    println("-----------------------------------")
end

