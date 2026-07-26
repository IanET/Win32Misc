# Enumerate network miniports (SetupAPI, class GUID_DEVCLASS_NET) and report
# friendly name, instance id and current power (D-state), then use the INetCfg
# COM API (the same API ncpa.cpl and Microsoft's "bindview" sample use) to walk
# each miniport's binding tree and report binding status plus the protocol and
# filter drivers bound to it.

include("../common/Win32.jl")
include("../common/combase.jl")
using LibBaseTsd, .W32

# --- ole32 ---

const Ole32 = "ole32.dll"

const CLSCTX_INPROC_SERVER = DWORD(0x1)
const COINIT_APARTMENTTHREADED = DWORD(0x2)

CoInitializeEx(pvReserved, dwCoInit) = @ccall Ole32.CoInitializeEx(pvReserved::LPVOID, dwCoInit::DWORD)::HRESULT
CoUninitialize() = @ccall Ole32.CoUninitialize()::Cvoid
CoCreateInstance(rclsid, pUnkOuter, dwClsContext, riid, ppv) = @ccall Ole32.CoCreateInstance(rclsid::Ptr{GUID}, pUnkOuter::Ptr{Cvoid}, dwClsContext::DWORD, riid::Ptr{GUID}, ppv::Ptr{Ptr{Cvoid}})::HRESULT
CoTaskMemFree(pv) = @ccall Ole32.CoTaskMemFree(pv::LPVOID)::Cvoid

# --- Network device setup classes (devguid.h) ---

const GUID_DEVCLASS_NET        = GUID(0x4d36e972, 0xe325, 0x11ce, 0xbfc1, 0x08002be10318)
const GUID_DEVCLASS_NETCLIENT  = GUID(0x4d36e973, 0xe325, 0x11ce, 0xbfc1, 0x08002be10318)
const GUID_DEVCLASS_NETSERVICE = GUID(0x4d36e974, 0xe325, 0x11ce, 0xbfc1, 0x08002be10318)
const GUID_DEVCLASS_NETTRANS   = GUID(0x4d36e975, 0xe325, 0x11ce, 0xbfc1, 0x08002be10318)

# --- INetCfg (netcfgx.h) GUIDs ---

const CLSID_CNetCfg = GUID(0x5b035261, 0x40f9, 0x11d1, 0xaaec, 0x00805fc1270e)

const IID_INetCfg                       = GUID(0xc0e8ae93, 0x306e, 0x11d1, 0xaacf, 0x00805fc1270e)
const IID_INetCfgComponent              = GUID(0xc0e8ae99, 0x306e, 0x11d1, 0xaacf, 0x00805fc1270e)
const IID_INetCfgComponentBindings      = GUID(0xc0e8ae9e, 0x306e, 0x11d1, 0xaacf, 0x00805fc1270e)
const IID_IEnumNetCfgComponent          = GUID(0xc0e8ae92, 0x306e, 0x11d1, 0xaacf, 0x00805fc1270e)
const IID_INetCfgBindingPath            = GUID(0xc0e8ae96, 0x306e, 0x11d1, 0xaacf, 0x00805fc1270e)
const IID_IEnumNetCfgBindingPath        = GUID(0xc0e8ae91, 0x306e, 0x11d1, 0xaacf, 0x00805fc1270e)
const IID_INetCfgBindingInterface       = GUID(0xc0e8ae94, 0x306e, 0x11d1, 0xaacf, 0x00805fc1270e)
const IID_IEnumNetCfgBindingInterface   = GUID(0xc0e8ae90, 0x306e, 0x11d1, 0xaacf, 0x00805fc1270e)

# INetCfgComponent::GetCharacteristics flags (COMPONENT_CHARACTERISTICS)
const NCF_VIRTUAL                    = DWORD(0x00000001)
const NCF_SOFTWARE_ENUMERATED        = DWORD(0x00000002)
const NCF_PHYSICAL                   = DWORD(0x00000004)
const NCF_HIDDEN                     = DWORD(0x00000008)
const NCF_NO_SERVICE                 = DWORD(0x00000010)
const NCF_NOT_USER_REMOVABLE         = DWORD(0x00000020)
const NCF_MULTIPORT_INSTANCED_ADAPTER = DWORD(0x00000040)
const NCF_HAS_UI                     = DWORD(0x00000080)
const NCF_SINGLE_INSTANCE             = DWORD(0x00000100)
const NCF_FILTER                     = DWORD(0x00000400)
const NCF_DONTEXPOSELOWER            = DWORD(0x00001000)
const NCF_HIDE_BINDING               = DWORD(0x00002000)
const NCF_NDIS_PROTOCOL              = DWORD(0x00004000)
const NCF_FIXED_BINDING              = DWORD(0x00020000)
const NCF_LW_FILTER                  = DWORD(0x00040000)

# INetCfgComponentBindings::EnumBindingPaths flags (ENUM_BINDING_PATHS_FLAGS)
const EBP_ABOVE = DWORD(0x01)
const EBP_BELOW = DWORD(0x02)

# --- INetCfg interfaces, declared in dependency order (vtable layout matters) ---

@interface INetCfgComponent begin
    @inherit IUnknown
    GetDisplayName(this::Ptr{INetCfgComponent}, ppszwDisplayName::Ptr{LPWSTR})::HRESULT
    SetDisplayName(this::Ptr{INetCfgComponent}, pszwDisplayName::LPCWSTR)::HRESULT
    GetHelpText(this::Ptr{INetCfgComponent}, ppszwHelpText::Ptr{LPWSTR})::HRESULT
    GetId(this::Ptr{INetCfgComponent}, ppszwId::Ptr{LPWSTR})::HRESULT
    GetCharacteristics(this::Ptr{INetCfgComponent}, pdwCharacteristics::Ptr{DWORD})::HRESULT
    GetInstanceGuid(this::Ptr{INetCfgComponent}, pGuid::Ptr{GUID})::HRESULT
    GetPnpDevNodeId(this::Ptr{INetCfgComponent}, ppszwDevNodeId::Ptr{LPWSTR})::HRESULT
    GetClassGuid(this::Ptr{INetCfgComponent}, pGuid::Ptr{GUID})::HRESULT
    GetBindName(this::Ptr{INetCfgComponent}, ppszwBindName::Ptr{LPWSTR})::HRESULT
    GetDeviceStatus(this::Ptr{INetCfgComponent}, pulStatus::Ptr{ULONG})::HRESULT
    OpenParamKey(this::Ptr{INetCfgComponent}, phkey::Ptr{HKEY})::HRESULT
    RaisePropertyUi(this::Ptr{INetCfgComponent}, hwndParent::HWND, dwFlags::DWORD, punkContext::Ptr{IUnknown})::HRESULT
end

@interface IEnumNetCfgComponent begin
    @inherit IUnknown
    Next(this::Ptr{IEnumNetCfgComponent}, celt::ULONG, rgelt::Ptr{Ptr{INetCfgComponent}}, pceltFetched::Ptr{ULONG})::HRESULT
    Skip(this::Ptr{IEnumNetCfgComponent}, celt::ULONG)::HRESULT
    Reset(this::Ptr{IEnumNetCfgComponent})::HRESULT
    Clone(this::Ptr{IEnumNetCfgComponent}, ppenum::Ptr{Ptr{IEnumNetCfgComponent}})::HRESULT
end

@interface INetCfg begin
    @inherit IUnknown
    Initialize(this::Ptr{INetCfg}, pvReserved::PVOID)::HRESULT
    Uninitialize(this::Ptr{INetCfg})::HRESULT
    Apply(this::Ptr{INetCfg})::HRESULT
    Cancel(this::Ptr{INetCfg})::HRESULT
    EnumComponents(this::Ptr{INetCfg}, pguidClass::Ptr{GUID}, ppenumComponent::Ptr{Ptr{IEnumNetCfgComponent}})::HRESULT
    FindComponent(this::Ptr{INetCfg}, pszwInfId::LPCWSTR, pComponent::Ptr{Ptr{INetCfgComponent}})::HRESULT
    QueryNetCfgClass(this::Ptr{INetCfg}, pguidClass::Ptr{GUID}, riid::Ptr{GUID}, ppvObject::Ptr{Ptr{Cvoid}})::HRESULT
end

@interface INetCfgBindingInterface begin
    @inherit IUnknown
    GetName(this::Ptr{INetCfgBindingInterface}, ppszwInterfaceName::Ptr{LPWSTR})::HRESULT
    GetUpperComponent(this::Ptr{INetCfgBindingInterface}, ppnccItem::Ptr{Ptr{INetCfgComponent}})::HRESULT
    GetLowerComponent(this::Ptr{INetCfgBindingInterface}, ppnccItem::Ptr{Ptr{INetCfgComponent}})::HRESULT
end

@interface IEnumNetCfgBindingInterface begin
    @inherit IUnknown
    Next(this::Ptr{IEnumNetCfgBindingInterface}, celt::ULONG, rgelt::Ptr{Ptr{INetCfgBindingInterface}}, pceltFetched::Ptr{ULONG})::HRESULT
    Skip(this::Ptr{IEnumNetCfgBindingInterface}, celt::ULONG)::HRESULT
    Reset(this::Ptr{IEnumNetCfgBindingInterface})::HRESULT
    Clone(this::Ptr{IEnumNetCfgBindingInterface}, ppenum::Ptr{Ptr{IEnumNetCfgBindingInterface}})::HRESULT
end

@interface INetCfgBindingPath begin
    @inherit IUnknown
    IsSamePathAs(this::Ptr{INetCfgBindingPath}, pPath::Ptr{INetCfgBindingPath})::HRESULT
    IsSubPathOf(this::Ptr{INetCfgBindingPath}, pPath::Ptr{INetCfgBindingPath})::HRESULT
    IsEnabled(this::Ptr{INetCfgBindingPath})::HRESULT
    Enable(this::Ptr{INetCfgBindingPath}, fEnable::BOOL)::HRESULT
    GetPathToken(this::Ptr{INetCfgBindingPath}, ppszwPathToken::Ptr{LPWSTR})::HRESULT
    GetOwner(this::Ptr{INetCfgBindingPath}, ppComponent::Ptr{Ptr{INetCfgComponent}})::HRESULT
    GetDepth(this::Ptr{INetCfgBindingPath}, pcInterfaces::Ptr{ULONG})::HRESULT
    EnumBindingInterfaces(this::Ptr{INetCfgBindingPath}, ppenumInterface::Ptr{Ptr{IEnumNetCfgBindingInterface}})::HRESULT
end

@interface IEnumNetCfgBindingPath begin
    @inherit IUnknown
    Next(this::Ptr{IEnumNetCfgBindingPath}, celt::ULONG, rgelt::Ptr{Ptr{INetCfgBindingPath}}, pceltFetched::Ptr{ULONG})::HRESULT
    Skip(this::Ptr{IEnumNetCfgBindingPath}, celt::ULONG)::HRESULT
    Reset(this::Ptr{IEnumNetCfgBindingPath})::HRESULT
    Clone(this::Ptr{IEnumNetCfgBindingPath}, ppenum::Ptr{Ptr{IEnumNetCfgBindingPath}})::HRESULT
end

@interface INetCfgComponentBindings begin
    @inherit IUnknown
    BindTo(this::Ptr{INetCfgComponentBindings}, pnccItem::Ptr{INetCfgComponent})::HRESULT
    UnbindFrom(this::Ptr{INetCfgComponentBindings}, pnccItem::Ptr{INetCfgComponent})::HRESULT
    SupportsBindingInterface(this::Ptr{INetCfgComponentBindings}, dwFlags::DWORD, pszwInterfaceName::LPCWSTR)::HRESULT
    IsBoundTo(this::Ptr{INetCfgComponentBindings}, pnccItem::Ptr{INetCfgComponent})::HRESULT
    IsBindableTo(this::Ptr{INetCfgComponentBindings}, pnccItem::Ptr{INetCfgComponent})::HRESULT
    EnumBindingPaths(this::Ptr{INetCfgComponentBindings}, dwFlags::DWORD, ppIEnum::Ptr{Ptr{IEnumNetCfgBindingPath}})::HRESULT
    MoveBefore(this::Ptr{INetCfgComponentBindings}, pncbItemSrc::Ptr{INetCfgBindingPath}, pncbItemDest::Ptr{INetCfgBindingPath})::HRESULT
    MoveAfter(this::Ptr{INetCfgComponentBindings}, pncbItemSrc::Ptr{INetCfgBindingPath}, pncbItemDest::Ptr{INetCfgBindingPath})::HRESULT
end

# --- SetupAPI (miniport enumeration + power state) ---

const SetupApi = "setupapi.dll"

const DIGCF_PRESENT = DWORD(0x00000002)
const SPDRP_DEVICEDESC = DWORD(0x00000000)
const SPDRP_FRIENDLYNAME = DWORD(0x0000000C)

const HDEVINFO = PVOID
const INVALID_HANDLE_VALUE = Ptr{Cvoid}(-1)

struct SP_DEVINFO_DATA
    cbSize::DWORD
    ClassGuid::GUID
    DevInst::DWORD
    Reserved::ULONG_PTR
end
SP_DEVINFO_DATA() = SP_DEVINFO_DATA(sizeof(SP_DEVINFO_DATA), GUID(), 0, 0)

struct DEVPROPKEY
    fmtid::GUID
    pid::ULONG
end

const DEVPROPTYPE = ULONG

# devpkey.h: DEVPKEY_Device_PowerData, DEVPROP_TYPE_BINARY -> CM_POWER_DATA
const DEVPKEY_Device_PowerData = DEVPROPKEY(GUID(0xa45c254e, 0xdf1c, 0x4efd, 0x8020, 0x67d146a850e0), 32)

# ntpoapi.h / wdm.h: CM_POWER_DATA (DEVICE_POWER_STATE/SYSTEM_POWER_STATE are 4-byte C enums)
const POWER_SYSTEM_MAXIMUM = 7

struct CM_POWER_DATA
    PD_Size::ULONG
    PD_MostRecentPowerState::Cint
    PD_Capabilities::ULONG
    PD_D1Latency::ULONG
    PD_D2Latency::ULONG
    PD_D3Latency::ULONG
    PD_PowerStateMapping::NTuple{POWER_SYSTEM_MAXIMUM, Cint}
    PD_DeepestSystemWake::Cint
end

const DEVICE_POWER_STATE_NAMES = Dict{Int, String}(
    0 => "Unspecified",
    1 => "D0 (Working)",
    2 => "D1",
    3 => "D2",
    4 => "D3 (Off)",
    5 => "Unspecified (Maximum)",
)

function devstate_name(d)
    return get(DEVICE_POWER_STATE_NAMES, Int(d), "Unknown ($d)")
end

SetupDiGetClassDevsW(classguid, enumerator, hwndparent, flags) = @ccall SetupApi.SetupDiGetClassDevsW(classguid::Ptr{GUID}, enumerator::LPCWSTR, hwndparent::HWND, flags::DWORD)::HDEVINFO
SetupDiEnumDeviceInfo(devinfo, memberindex, devinfodata) = @ccall SetupApi.SetupDiEnumDeviceInfo(devinfo::HDEVINFO, memberindex::DWORD, devinfodata::Ptr{SP_DEVINFO_DATA})::BOOL
SetupDiDestroyDeviceInfoList(devinfo) = @ccall SetupApi.SetupDiDestroyDeviceInfoList(devinfo::HDEVINFO)::BOOL
SetupDiGetDeviceInstanceIdW(devinfo, devinfodata, buf, bufsize, reqsize) = @ccall SetupApi.SetupDiGetDeviceInstanceIdW(devinfo::HDEVINFO, devinfodata::Ptr{SP_DEVINFO_DATA}, buf::LPWSTR, bufsize::DWORD, reqsize::Ptr{DWORD})::BOOL
SetupDiGetDeviceRegistryPropertyW(devinfo, devinfodata, prop, regdatatype, buf, bufsize, reqsize) = @ccall SetupApi.SetupDiGetDeviceRegistryPropertyW(devinfo::HDEVINFO, devinfodata::Ptr{SP_DEVINFO_DATA}, prop::DWORD, regdatatype::Ptr{DWORD}, buf::Ptr{BYTE}, bufsize::DWORD, reqsize::Ptr{DWORD})::BOOL
SetupDiGetDevicePropertyW(devinfo, devinfodata, propkey, proptype, buf, bufsize, reqsize, flags) = @ccall SetupApi.SetupDiGetDevicePropertyW(devinfo::HDEVINFO, devinfodata::Ptr{SP_DEVINFO_DATA}, propkey::Ptr{DEVPROPKEY}, proptype::Ptr{DEVPROPTYPE}, buf::Ptr{BYTE}, bufsize::DWORD, reqsize::Ptr{DWORD}, flags::DWORD)::BOOL

# --- Helpers ---

function wstring(p::Ptr{WCHAR})
    if p == C_NULL
        return ""
    end
    len = 0
    while unsafe_load(p, len + 1) != 0
        len += 1
    end
    return transcode(String, unsafe_wrap(Array, p, len))
end

function device_friendly_name(hdi, devdata)
    buf = zeros(WCHAR, 512)
    reqsize = Ref(DWORD(0))
    ok = SetupDiGetDeviceRegistryPropertyW(hdi, devdata, SPDRP_FRIENDLYNAME, C_NULL, Ptr{BYTE}(pointer(buf)), DWORD(sizeof(buf)), reqsize)
    if ok == 0
        ok = SetupDiGetDeviceRegistryPropertyW(hdi, devdata, SPDRP_DEVICEDESC, C_NULL, Ptr{BYTE}(pointer(buf)), DWORD(sizeof(buf)), reqsize)
    end
    if ok == 0
        return "(unknown)"
    end
    return wstring(pointer(buf))
end

function device_instance_id(hdi, devdata)
    buf = zeros(WCHAR, 512)
    reqsize = Ref(DWORD(0))
    ok = SetupDiGetDeviceInstanceIdW(hdi, devdata, pointer(buf), DWORD(length(buf)), reqsize)
    if ok == 0
        return ""
    end
    return wstring(pointer(buf))
end

function device_power_data(hdi, devdata)
    buf = zeros(UInt8, sizeof(CM_POWER_DATA))
    proptype = Ref(DEVPROPTYPE(0))
    reqsize = Ref(DWORD(0))
    ok = SetupDiGetDevicePropertyW(hdi, devdata, Ref(DEVPKEY_Device_PowerData), proptype, pointer(buf), DWORD(length(buf)), reqsize, DWORD(0))
    if ok == 0
        return nothing
    end
    return unsafe_load(Ptr{CM_POWER_DATA}(pointer(buf)))
end

function enum_miniports_setupapi()
    result = NamedTuple[]
    hdi = SetupDiGetClassDevsW(Ref(GUID_DEVCLASS_NET), C_NULL, HWND(0), DIGCF_PRESENT)
    if hdi == INVALID_HANDLE_VALUE
        @error "SetupDiGetClassDevsW failed" lasterror = GetLastError()
        return result
    end
    idx = DWORD(0)
    while true
        devdata = Ref(SP_DEVINFO_DATA())
        ok = SetupDiEnumDeviceInfo(hdi, idx, devdata)
        if ok == 0
            break
        end
        name = device_friendly_name(hdi, devdata)
        instid = device_instance_id(hdi, devdata)
        pd = device_power_data(hdi, devdata)
        push!(result, (name = name, instance_id = instid, power = pd))
        idx += DWORD(1)
    end
    SetupDiDestroyDeviceInfoList(hdi)
    return result
end

# Generic Next()-based enumerator drain, works for any IEnumNetCfg* interface
function collect_next(penum::Ptr{E}, ::Type{I}) where {E, I}
    items = Ptr{I}[]
    pitem = Ref(Ptr{I}(C_NULL))
    fetched = Ref(ULONG(0))
    while true
        hr = Next(penum, ULONG(1), pitem, fetched)
        if hr != S_OK || fetched[] == 0
            break
        end
        push!(items, pitem[])
    end
    return items
end

function comp_display_name(pncc::Ptr{INetCfgComponent})
    p = Ref(LPWSTR(C_NULL))
    hr = GetDisplayName(pncc, p)
    if hr != S_OK
        return "?"
    end
    s = wstring(p[])
    CoTaskMemFree(p[])
    return s
end

function comp_pnp_dev_node_id(pncc::Ptr{INetCfgComponent})
    p = Ref(LPWSTR(C_NULL))
    hr = GetPnpDevNodeId(pncc, p)
    if hr != S_OK
        return ""
    end
    s = wstring(p[])
    CoTaskMemFree(p[])
    return s
end

function comp_characteristics(pncc::Ptr{INetCfgComponent})
    p = Ref(DWORD(0))
    hr = GetCharacteristics(pncc, p)
    if hr != S_OK
        return DWORD(0)
    end
    return p[]
end

function comp_class_guid(pncc::Ptr{INetCfgComponent})
    g = Ref(GUID())
    hr = GetClassGuid(pncc, g)
    if hr != S_OK
        return GUID()
    end
    return g[]
end

function comp_device_status(pncc::Ptr{INetCfgComponent})
    p = Ref(ULONG(0))
    hr = GetDeviceStatus(pncc, p)
    if hr != S_OK
        return nothing
    end
    return p[]
end

@enum ComponentKind KindMiniport KindProtocol KindFilter KindService KindClient KindOther

function comp_kind(pncc::Ptr{INetCfgComponent})
    c = comp_characteristics(pncc)
    cls = comp_class_guid(pncc)
    if (c & (NCF_FILTER | NCF_LW_FILTER)) != 0
        return KindFilter
    end
    if (c & NCF_NDIS_PROTOCOL) != 0 || cls == GUID_DEVCLASS_NETTRANS
        return KindProtocol
    end
    if cls == GUID_DEVCLASS_NET
        return KindMiniport
    end
    if cls == GUID_DEVCLASS_NETSERVICE
        return KindService
    end
    if cls == GUID_DEVCLASS_NETCLIENT
        return KindClient
    end
    return KindOther
end

function path_is_enabled(pncbp::Ptr{INetCfgBindingPath})
    hr = IsEnabled(pncbp)
    return hr == S_OK
end

function path_owner(pncbp::Ptr{INetCfgBindingPath})
    p = Ref(Ptr{INetCfgComponent}(C_NULL))
    hr = GetOwner(pncbp, p)
    if hr != S_OK
        return Ptr{INetCfgComponent}(C_NULL)
    end
    return p[]
end

function path_interfaces(pncbp::Ptr{INetCfgBindingPath})
    p = Ref(Ptr{IEnumNetCfgBindingInterface}(C_NULL))
    hr = EnumBindingInterfaces(pncbp, p)
    if hr != S_OK
        return Ptr{INetCfgBindingInterface}[]
    end
    items = collect_next(p[], INetCfgBindingInterface)
    Release(p[])
    return items
end

# Full top-to-bottom chain of components for a binding path: owner first, then
# each successively lower component (the last entry is the miniport itself).
function path_chain(pncbp::Ptr{INetCfgBindingPath})
    chain = Ptr{INetCfgComponent}[]
    owner = path_owner(pncbp)
    if owner != C_NULL
        push!(chain, owner)
    end
    for pif in path_interfaces(pncbp)
        low = Ref(Ptr{INetCfgComponent}(C_NULL))
        GetLowerComponent(pif, low)
        if low[] != C_NULL
            push!(chain, low[])
        end
        Release(pif)
    end
    return chain
end

function report_miniport(mp, netcfg_components)
    println()
    println("=== $(mp.name) ===")
    println("  Instance ID   : $(mp.instance_id)")

    if mp.power === nothing
        println("  Power state   : (unavailable)")
    else
        println("  Power state   : $(devstate_name(mp.power.PD_MostRecentPowerState))")
    end

    idx = findfirst(c -> uppercase(comp_pnp_dev_node_id(c)) == uppercase(mp.instance_id), netcfg_components)
    if idx === nothing
        println("  Device status : (not found in network configuration)")
        return nothing
    end
    pncc = netcfg_components[idx]

    status = comp_device_status(pncc)
    status_str = status === nothing ? "(unknown)" : (status == 0 ? "Enabled" : "Disabled (problem code $status)")
    println("  Device status : $status_str")

    pnccbRef = Ref(Ptr{Cvoid}(C_NULL))
    hr = QueryInterface(pncc, Ref(IID_INetCfgComponentBindings), pnccbRef)
    if hr != S_OK
        println("  Bindings      : (unavailable)")
        return nothing
    end
    pnccb = Ptr{INetCfgComponentBindings}(pnccbRef[])

    penumbpRef = Ref(Ptr{IEnumNetCfgBindingPath}(C_NULL))
    hr = EnumBindingPaths(pnccb, EBP_ABOVE, penumbpRef)
    if hr != S_OK
        println("  Bindings      : (none)")
        Release(pnccb)
        return nothing
    end
    paths = collect_next(penumbpRef[], INetCfgBindingPath)
    Release(penumbpRef[])

    filters = Set{String}()
    protocols = Set{String}()
    lines = String[]

    for pncbp in paths
        chain = path_chain(pncbp)
        enabled = path_is_enabled(pncbp)
        names = String[]
        for c in chain
            nm = comp_display_name(c)
            push!(names, nm)
            kind = comp_kind(c)
            if kind == KindFilter
                push!(filters, nm)
            elseif kind == KindProtocol
                push!(protocols, nm)
            end
        end
        push!(lines, "    [$(enabled ? "enabled " : "disabled")] " * join(names, " --> "))
        foreach(Release, chain)
        Release(pncbp)
    end

    println("  Protocol drivers bound:")
    if isempty(protocols)
        println("    (none)")
    else
        for nm in sort(collect(protocols))
            println("    - $nm")
        end
    end

    println("  Filter drivers bound:")
    if isempty(filters)
        println("    (none)")
    else
        for nm in sort(collect(filters))
            println("    - $nm")
        end
    end

    println("  Binding paths:")
    if isempty(lines)
        println("    (none)")
    else
        for l in lines
            println(l)
        end
    end

    Release(pnccb)
    return nothing
end

function main()
    hr = CoInitializeEx(C_NULL, COINIT_APARTMENTTHREADED)
    if hr != S_OK && hr != S_FALSE
        @error "CoInitializeEx failed" hr
        return nothing
    end

    try
        miniports = enum_miniports_setupapi()
        if isempty(miniports)
            println("No network miniports found.")
            return nothing
        end

        ppv = Ref(Ptr{Cvoid}(C_NULL))
        CoCreateInstance(Ref(CLSID_CNetCfg), C_NULL, CLSCTX_INPROC_SERVER, Ref(IID_INetCfg), ppv) |> AssertSuccess
        pnc = Ptr{INetCfg}(ppv[])

        try
            Initialize(pnc, C_NULL) |> AssertSuccess

            penumRef = Ref(Ptr{IEnumNetCfgComponent}(C_NULL))
            EnumComponents(pnc, Ref(GUID_DEVCLASS_NET), penumRef) |> AssertSuccess
            netcfg_components = collect_next(penumRef[], INetCfgComponent)
            Release(penumRef[])

            for mp in miniports
                report_miniport(mp, netcfg_components)
            end

            foreach(Release, netcfg_components)
        finally
            Uninitialize(pnc)
            Release(pnc)
        end
    catch e
        @error "Failed to enumerate network miniports" exception = (e, catch_backtrace())
    finally
        CoUninitialize()
    end
    return nothing
end

main()
