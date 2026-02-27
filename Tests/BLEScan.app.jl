# Scan for BLE devices and print their addresses and names

include("../common/Win32.jl")
using LibBaseTsd, .W32 

const SetupAPI = "SetupAPI.dll"
const MAX_NAME_SIZE = 256

const HDEVINFO = HANDLE
const PCWSTR = LPCWSTR
const INVALID_HANDLE_VALUE = reinterpret(HANDLE, -1)

const GUID_DEVCLASS_BLUETOOTH = GUID(0xe0cbf06c, 0xcd8b, 0x4647, (0xbb, 0x8a, 0x26, 0x3b, 0x43, 0xf0, 0xf9, 0x74))
const DIGCF_PRESENT = 0x00000002
const DIGCF_DEVICEINTERFACE = 0x00000010

const SPDRP_HARDWAREID = 0x00000001
const SPDRP_FRIENDLYNAME = 0x0000000C
const SDRP_SPDRP_CLASSGUID = 0x00000008

@kwdef struct SP_DEVINFO_DATA
    cbSize::DWORD = sizeof(SP_DEVINFO_DATA)
    ClassGuid::GUID = GUID(0, 0, 0, (0, 0, 0, 0, 0, 0, 0, 0))
    DevInst::DWORD = 0
    Reserved::ULONG_PTR = 0
end

@kwdef struct SP_DEVICE_INTERFACE_DATA
    cbSize::DWORD = sizeof(SP_DEVICE_INTERFACE_DATA)
    InterfaceClassGuid::GUID = GUID(0, 0, 0, (0, 0, 0, 0, 0, 0, 0, 0))
    Flags::DWORD = 0
    Reserved::ULONG_PTR = 0
end

const MAX_PATH = 4096

@kwdef struct SP_DEVICE_INTERFACE_DETAIL_DATA_W
    cbSize::DWORD = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_W)
    DevicePath::NTuple{MAX_PATH, WCHAR} = ntuple(i -> 0, MAX_PATH)
end

# tostring(v::AbstractArray{Cwchar_t}) = transcode(String, @view v[begin:findfirst(iszero, v)-1])

SetupDiGetClassDevsW(ClassGuid, Enumerator, hwndParent, Flags) = @ccall SetupAPI.SetupDiGetClassDevsW(ClassGuid::Ptr{GUID}, Enumerator::PCWSTR, hwndParent::HWND, Flags::DWORD)::HDEVINFO
SetupDiEnumDeviceInfo(DeviceInfoSet, MemberIndex, DeviceInfoData) = @ccall SetupAPI.SetupDiEnumDeviceInfo(DeviceInfoSet::HDEVINFO, MemberIndex::DWORD, DeviceInfoData::Ref{SP_DEVINFO_DATA})::BOOL
SetupDiGetDeviceRegistryPropertyW(DeviceInfoSet, DeviceInfoData, Property, PropertyRegDataType, PropertyBuffer, PropertyBufferSize, RequiredSize) = @ccall SetupAPI.SetupDiGetDeviceRegistryPropertyW(DeviceInfoSet::HDEVINFO, DeviceInfoData::Ref{SP_DEVINFO_DATA}, Property::DWORD, PropertyRegDataType::Ref{DWORD}, PropertyBuffer::Ptr{BYTE}, PropertyBufferSize::DWORD, RequiredSize::Ref{DWORD})::BOOL
SetupDiEnumDeviceInterfaces(DeviceInfoSet, DeviceInfoData, InterfaceClassGuid, MemberIndex, DeviceInterfaceData) = @ccall SetupAPI.SetupDiEnumDeviceInterfaces(DeviceInfoSet::HDEVINFO, DeviceInfoData::Ptr{SP_DEVINFO_DATA}, InterfaceClassGuid::Ref{GUID}, MemberIndex::DWORD, DeviceInterfaceData::Ref{SP_DEVICE_INTERFACE_DATA})::BOOL
SetupDiGetDeviceInterfaceDetailW(DeviceInfoSet, DeviceInterfaceData, DeviceInterfaceDetailData, DeviceInterfaceDetailDataSize, RequiredSize, DeviceInfoData) = @ccall SetupAPI.SetupDiGetDeviceInterfaceDetailW(DeviceInfoSet::HDEVINFO, DeviceInterfaceData::Ref{SP_DEVICE_INTERFACE_DATA}, DeviceInterfaceDetailData::Ptr{Cvoid}, DeviceInterfaceDetailDataSize::DWORD, RequiredSize::Ref{DWORD}, DeviceInfoData::Ptr{SP_DEVINFO_DATA})::BOOL

function scan_bt_device_names()
    hdi = SetupDiGetClassDevsW(Ref(GUID_DEVCLASS_BLUETOOTH), C_NULL, C_NULL, DIGCF_PRESENT)
    @info "Got device info set handle: $hdi"

    dd = SP_DEVINFO_DATA() |> Ref
    i = 0
    while SetupDiEnumDeviceInfo(hdi, i, dd) == TRUE
        i += 1
        req = DWORD(0) |> Ref
        buf = zeros(BYTE, MAX_NAME_SIZE)
        name = ""
        res = SetupDiGetDeviceRegistryPropertyW(hdi, dd, SPDRP_FRIENDLYNAME, Ref(DWORD(0)), buf, sizeof(buf), req)
        if res == TRUE
            cch = req[] ÷ 2
            name = reinterpret(TCHAR, buf) |> b -> transcode(String, @view b[begin:cch-1])
        end
        @info "Device" dd[].DevInst name
    end
end

function scan_bt_devices()
    hdi = SetupDiGetClassDevsW(Ref(GUID_DEVCLASS_BLUETOOTH), C_NULL, C_NULL, DIGCF_DEVICEINTERFACE)
    @info "Got device info set handle: $hdi"

    did = SP_DEVICE_INTERFACE_DATA() |> Ref
    i = 0
    while SetupDiEnumDeviceInterfaces(hdi, C_NULL, Ref(GUID_DEVCLASS_BLUETOOTH), i, did) == TRUE
        i += 1
        @info "Found device interface: $did"
    end
    @info "Error code: $(GetLastError())"

    @info "Found $i Bluetooth interfaces"
end

scan_bt_device_names()
scan_bt_devices()