# Scan for BLE devices and print their addresses and names

include("../common/Win32.jl")
using LibBaseTsd, .W32 

const SetupAPI = "SetupAPI.dll"
const MAX_NAME_SIZE = 256

const HDEVINFO = HANDLE
const PCWSTR = LPCWSTR

# e0cbf06c-cd8b-4647-bb8a-263b43f0f974
const GUID_DEVCLASS_BLUETOOTH = GUID(0xe0cbf06c, 0xcd8b, 0x4647, (0xbb, 0x8a, 0x26, 0x3b, 0x43, 0xf0, 0xf9, 0x74))
const DIGCF_PRESENT = 0x00000002
const SPDRP_FRIENDLYNAME = 0x0000000C

@kwdef struct SP_DEVINFO_DATA
    cbSize::DWORD = sizeof(SP_DEVINFO_DATA)
    ClassGuid::GUID = GUID(0, 0, 0, (0, 0, 0, 0, 0, 0, 0, 0))
    DevInst::DWORD = 0
    Reserved::ULONG_PTR = 0
end

# tostring(v::AbstractArray{Cwchar_t}) = transcode(String, @view v[begin:findfirst(iszero, v)-1])

SetupDiGetClassDevsW(ClassGuid, Enumerator, hwndParent, Flags) = @ccall SetupAPI.SetupDiGetClassDevsW(ClassGuid::Ptr{GUID}, Enumerator::PCWSTR, hwndParent::HWND, Flags::DWORD)::HDEVINFO
SetupDiEnumDeviceInfo(DeviceInfoSet, MemberIndex, DeviceInfoData) = @ccall SetupAPI.SetupDiEnumDeviceInfo(DeviceInfoSet::HDEVINFO, MemberIndex::DWORD, DeviceInfoData::Ref{SP_DEVINFO_DATA})::BOOL
SetupDiGetDeviceRegistryPropertyW(DeviceInfoSet, DeviceInfoData, Property, PropertyRegDataType, PropertyBuffer, PropertyBufferSize, RequiredSize) = @ccall SetupAPI.SetupDiGetDeviceRegistryPropertyW(DeviceInfoSet::HDEVINFO, DeviceInfoData::Ref{SP_DEVINFO_DATA}, Property::DWORD, PropertyRegDataType::Ref{DWORD}, PropertyBuffer::Ptr{BYTE}, PropertyBufferSize::DWORD, RequiredSize::Ref{DWORD})::BOOL

hdi = SetupDiGetClassDevsW(Ref(GUID_DEVCLASS_BLUETOOTH), C_NULL, C_NULL, DIGCF_PRESENT)
@info "Got device info set handle: $hdi"

did = SP_DEVINFO_DATA() |> Ref
i = 0
while SetupDiEnumDeviceInfo(hdi, i, did) == TRUE
    # @info "Device" did[].DevInst
    i += 1

    nameData = DWORD(0) |> Ref
    nameBuffer = zeros(BYTE, MAX_NAME_SIZE)
    nameBufferSize = DWORD(0) |> Ref

    res = SetupDiGetDeviceRegistryPropertyW(hdi, did, SPDRP_FRIENDLYNAME, Ref(DWORD(0)), nameBuffer, sizeof(nameBuffer), nameData)
    if res == FALSE
        # @warn "Failed to get device name for device $i"
        continue
    end 
    # name = String(unsafe_string(pointer(nameBuffer)))
    cch = nameData[] ÷ 2
    name = reinterpret(TCHAR, nameBuffer) |> b -> transcode(String, @view b[begin:cch-1])
    @info "Device $(did[].DevInst): $name"
end

