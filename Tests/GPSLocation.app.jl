# Get the current GPS location using the WinRT Windows.Devices.Geolocation API
# (Windows.Devices.Geolocation.Geolocator / IGeolocator::GetGeopositionAsync).
#
# Note: this needs Windows Settings > Privacy & security > Location enabled
# ("Let apps access your location" / "Let desktop apps access your location").

using Dates

include("../common/Win32.jl")
include("../common/combase.jl")
using LibBaseTsd, Printf, .W32

# --- IIDs (from windows.devices.geolocation.h) ---

const IID_IActivationFactory = GUID(0x00000035, 0x0000, 0x0000, 0xc000, 0x000000000046)
const IID_IGeolocator = GUID(0xa9c3bf62, 0x4524, 0x4989, 0x8aa9, 0xde019d2e551f)
const IID_IGeoposition = GUID(0xc18d0454, 0x7d41, 0x4ff7, 0xa957, 0x9dffb4ef7f5b)
const IID_IGeocoordinate = GUID(0xee21a3aa, 0x976a, 0x4c70, 0x803d, 0x083ea55bcbc4)
const IID_IReference_double = GUID(0x2f2d6c29, 0x5473, 0x5f3e, 0x92e7, 0x96572bb990e2)
const IID_IAsyncOperationCompletedHandler_Geoposition = GUID(0x7668a704, 0x244e, 0x5e12, 0x8dcb, 0x92a3299eba26)

const Classname_Geolocator = "Windows.Devices.Geolocation.Geolocator"

@cenum PositionAccuracy begin
    PositionAccuracy_Default = 0
    PositionAccuracy_High = 1
end

@cenum PositionStatus begin
    PositionStatus_Ready = 0
    PositionStatus_Initializing = 1
    PositionStatus_NoData = 2
    PositionStatus_Disabled = 3
    PositionStatus_NotInitialized = 4
    PositionStatus_NotAvailable = 5
end

# --- WinRT interfaces ---

@interface IActivationFactory begin
    @inherit IInspectable
    ActivateInstance(this::Ptr{IActivationFactory}, instance::Ptr{Ptr{IInspectable}})::HRESULT
end

@interface IReferenceDouble begin
    @inherit IInspectable
    get_Value(this::Ptr{IReferenceDouble}, value::Ptr{Cdouble})::HRESULT
end

@interface IGeocoordinate begin
    @inherit IInspectable
    get_Latitude(this::Ptr{IGeocoordinate}, value::Ptr{Cdouble})::HRESULT
    get_Longitude(this::Ptr{IGeocoordinate}, value::Ptr{Cdouble})::HRESULT
    get_Altitude(this::Ptr{IGeocoordinate}, value::Ptr{Ptr{IReferenceDouble}})::HRESULT
    get_Accuracy(this::Ptr{IGeocoordinate}, value::Ptr{Cdouble})::HRESULT
    get_AltitudeAccuracy(this::Ptr{IGeocoordinate}, value::Ptr{Ptr{IReferenceDouble}})::HRESULT
    get_Heading(this::Ptr{IGeocoordinate}, value::Ptr{Ptr{IReferenceDouble}})::HRESULT
    get_Speed(this::Ptr{IGeocoordinate}, value::Ptr{Ptr{IReferenceDouble}})::HRESULT
    get_Timestamp(this::Ptr{IGeocoordinate}, value::Ptr{Int64})::HRESULT
end

@interface IGeoposition begin
    @inherit IInspectable
    get_Coordinate(this::Ptr{IGeoposition}, value::Ptr{Ptr{IGeocoordinate}})::HRESULT
    get_CivicAddress(this::Ptr{IGeoposition}, value::Ptr{Ptr{Cvoid}})::HRESULT
end

@interface IGeolocator begin
    @inherit IInspectable
    get_DesiredAccuracy(this::Ptr{IGeolocator}, value::Ptr{PositionAccuracy})::HRESULT
    put_DesiredAccuracy(this::Ptr{IGeolocator}, value::PositionAccuracy)::HRESULT
    get_MovementThreshold(this::Ptr{IGeolocator}, value::Ptr{Cdouble})::HRESULT
    put_MovementThreshold(this::Ptr{IGeolocator}, value::Cdouble)::HRESULT
    get_ReportInterval(this::Ptr{IGeolocator}, value::Ptr{UInt32})::HRESULT
    put_ReportInterval(this::Ptr{IGeolocator}, value::UInt32)::HRESULT
    get_LocationStatus(this::Ptr{IGeolocator}, value::Ptr{PositionStatus})::HRESULT
    GetGeopositionAsync(this::Ptr{IGeolocator}, value::Ptr{Ptr{IAsyncOperation}})::HRESULT
    GetGeopositionAsyncWithAgeAndTimeout::Ptr{Cvoid}
    add_PositionChanged::Ptr{Cvoid}
    remove_PositionChanged::Ptr{Cvoid}
    add_StatusChanged::Ptr{Cvoid}
    remove_StatusChanged::Ptr{Cvoid}
end

# --- Helpers ---

# DateTime (Windows.Foundation) is 100ns ticks since 1601-01-01, same epoch as FILETIME
const FILETIME_EPOCH = DateTime(1601, 1, 1)
filetime_to_datetime(ticks::Int64) = FILETIME_EPOCH + Millisecond(ticks ÷ 10_000)

function opt_double(pref::Ptr{IReferenceDouble})
    if pref == C_NULL
        return nothing
    end
    v = Cdouble(0) |> Ref
    get_Value(pref, v) |> AssertSuccess
    return v[]
end

# --- Completed handler (fires when GetGeopositionAsync finishes) ---

const done = Base.Event()
const result = Ref{Any}(nothing)

function GeopositionHandler_QueryInterface(this::Ptr{IAsyncOperationCompletedHandler}, riid::Ptr{GUID}, ppv::Ptr{Ptr{Cvoid}})::HRESULT
    guid = unsafe_load(riid)
    if guid == IID_IUnknown || guid == IID_IAsyncOperationCompletedHandler_Geoposition
        unsafe_store!(ppv, this)
        return S_OK
    end
    unsafe_store!(ppv, C_NULL)
    return reinterpret(HRESULT, E_NOINTERFACE)
end

GeopositionHandler_AddRef(this::Ptr{IAsyncOperationCompletedHandler})::UInt32 = return 1
GeopositionHandler_Release(this::Ptr{IAsyncOperationCompletedHandler})::UInt32 = return 1

function GeopositionHandler_Invoke(this::Ptr{IAsyncOperationCompletedHandler}, asyncInfo::Ptr{IAsyncOperation}, asyncStatus::AsyncStatus)::HRESULT
    try
        if asyncStatus == Completed
            ppv = Ptr{Cvoid}(C_NULL) |> Ref
            GetResults(asyncInfo, ppv) |> AssertSuccess
            position = Ptr{IGeoposition}(ppv[])

            pcoord = Ptr{IGeocoordinate}(C_NULL) |> Ref
            get_Coordinate(position, pcoord) |> AssertSuccess
            coord = pcoord[]

            lat = Cdouble(0) |> Ref
            lon = Cdouble(0) |> Ref
            acc = Cdouble(0) |> Ref
            ts = Int64(0) |> Ref
            paltref = Ptr{IReferenceDouble}(C_NULL) |> Ref
            get_Latitude(coord, lat) |> AssertSuccess
            get_Longitude(coord, lon) |> AssertSuccess
            get_Accuracy(coord, acc) |> AssertSuccess
            get_Timestamp(coord, ts) |> AssertSuccess
            get_Altitude(coord, paltref) |> AssertSuccess

            result[] = (
                latitude = lat[],
                longitude = lon[],
                accuracy = acc[],
                altitude = opt_double(paltref[]),
                timestamp = filetime_to_datetime(ts[]),
            )

            Release(coord)
            Release(position)
        else
            errcode = HRESULT(0) |> Ref
            get_ErrorCode(Ptr{IAsyncInfo}(asyncInfo), errcode)
            @error "GetGeopositionAsync did not complete" asyncStatus errcode = @sprintf("0x%x", reinterpret(UInt32, errcode[]))
        end
    catch e
        @error "Error handling geoposition result" exception = (e, catch_backtrace())
    finally
        notify(done)
    end
    return S_OK
end

handlerImp = IAsyncOperationCompletedHandlerVtbl(
    IUnknownVtbl(
        @cfunc(GeopositionHandler_QueryInterface(::Ptr{IAsyncOperationCompletedHandler}, ::Ptr{GUID}, ::Ptr{Ptr{Cvoid}})::HRESULT),
        @cfunc(GeopositionHandler_AddRef(::Ptr{IAsyncOperationCompletedHandler})::UInt32),
        @cfunc(GeopositionHandler_Release(::Ptr{IAsyncOperationCompletedHandler})::UInt32)
    ),
    @cfunc(GeopositionHandler_Invoke(::Ptr{IAsyncOperationCompletedHandler}, ::Ptr{IAsyncOperation}, ::AsyncStatus)::HRESULT)
) |> Ref
handler = IAsyncOperationCompletedHandler(pointer_from_objref(handlerImp)) |> Ref

# --- Main ---

function main()
    hr = RoInitialize(RO_INIT_MULTITHREADED)
    if hr != S_OK && hr != S_FALSE
        @error "RoInitialize failed" hr
        return nothing
    end

    try
        ppv = PVOID() |> Ref
        RoGetActivationFactory(Classname_Geolocator, Ref(IID_IActivationFactory), ppv) |> AssertSuccess
        factory = Ptr{IActivationFactory}(ppv[])

        insp = Ptr{IInspectable}(C_NULL) |> Ref
        ActivateInstance(factory, insp) |> AssertSuccess
        Release(factory)

        QueryInterface(insp[], Ref(IID_IGeolocator), ppv) |> AssertSuccess
        geolocator = Ptr{IGeolocator}(ppv[])
        Release(insp[])

        put_DesiredAccuracy(geolocator, PositionAccuracy_High) |> AssertSuccess

        status = PositionStatus(0) |> Ref
        get_LocationStatus(geolocator, status) |> AssertSuccess
        @info "Location status: $(status[])"

        asyncop = Ptr{IAsyncOperation}(C_NULL) |> Ref
        GetGeopositionAsync(geolocator, asyncop) |> AssertSuccess
        put_Completed(asyncop[], handler) |> AssertSuccess

        @info "Waiting for location..."
        wait(done)
        Release(asyncop[])
        Release(geolocator)

        if result[] === nothing
            println("Failed to get location.")
        else
            r = result[]
            println("Latitude:  $(r.latitude)")
            println("Longitude: $(r.longitude)")
            println("Accuracy:  $(r.accuracy) meters")
            if r.altitude !== nothing
                println("Altitude:  $(r.altitude) meters")
            end
            println("Timestamp: $(r.timestamp)")
        end
    catch e
        @error "Failed to get GPS location" exception = (e, catch_backtrace())
    finally
        RoUninitialize()
    end
    return nothing
end

main()
