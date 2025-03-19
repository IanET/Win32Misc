using Printf, CEnum

const Combase = "Combase.dll"
import .W32: HMODULE, HANDLE, UINT, LPCWSTR, LONG, HWND, WCHAR, BYTE, POINT, TRUE, FALSE, ULONG
import .GC: @preserve

const HRESULT = LONG
const HSTRING = HANDLE
const PCNZWCH = LPCWSTR
const LpifaceLESTR = LPCWSTR
const OLESTR = Vector{WCHAR}

const S_OK = 0
const S_FALSE = 1
const E_NOTIMPL = 0x80004001
const E_NOINTERFACE = 0x80004002
const E_POINTER = 0x80004003
const E_ABORT = 0x80004004
const E_FAIL = 0x80004005
const E_ILLEGAL_METHOD_CALL = 0x8000000E
const RPC_E_CHANGED_MODE = 0x80010106
const CLASS_E_CLASSNOTAVAILABLE = 0x80040111
const E_CLASSNOTREG = 0x80040154
const E_INVALDARG = 0x80070057
const E_OUTOFMEMORY = 0x8007000E

const RO_INIT_SINGLETHREADED = 0
const RO_INIT_MULTITHREADED = 1

const Maybe{T} = Union{T, Nothing}

Base.filter(f::Function) = x -> filter(f, x)
Base.map(f::Function) = x -> map(f, x)

@cenum TrustLevel begin
    BaseTrust = 0 
    PartialTrust = 1 
    FullTrust = 2
end

@kwdef struct GUID
    Data1::UInt32 = 0
    Data2::UInt16 = 0
    Data3::UInt16 = 0
    Data4::NTuple{8, UInt8} = ntuple(zero, 8)
end
const UUID = GUID
const IID = UUID
const REFIID = Ptr{UUID}

HIBYTE(x::UInt16) = x >> 8 & 0xFF |> UInt8
LOBYTE(x::UInt16) = x & 0xFF |> UInt8
HIWORD(x::UInt32) = x >> 16 & 0xFFFF |> UInt16
LOWORD(x::UInt32) = x & 0xFFFF |> UInt16
HIDWORD(x::UInt64) = x >> 32 & 0xFFFFFFFF |> UInt32
LODWORD(x::UInt64) = x & 0xFFFFFFFF |> UInt32

GUID(a::UInt32, b::UInt16, c::UInt16, d::UInt16, e::UInt64) = 
    return GUID(a, b, c, (
        HIBYTE(d), 
        LOBYTE(d), 
        HIDWORD(e) |> LOWORD |> HIBYTE, 
        HIDWORD(e) |> LOWORD |> LOBYTE, 
        LODWORD(e) |> HIWORD |> HIBYTE, 
        LODWORD(e) |> HIWORD |> LOBYTE, 
        LODWORD(e) |> LOWORD |> HIBYTE, 
        LODWORD(e) |> LOWORD |> LOBYTE))
Base.show(io::IO, g::GUID) = @printf(io, "{%08x-%04x-%04x-%04x-%012x}", g.Data1, g.Data2, g.Data3, UInt16(g.Data4[1]) << 8 + g.Data4[2], UInt64(g.Data4[3]) << 40 + UInt64(g.Data4[4]) << 32 + UInt64(g.Data4[5]) << 24 + UInt32(g.Data4[6]) << 16 + UInt32(g.Data4[7]) << 8 + UInt32(g.Data4[8]))

IIDFromString(lpsz, lpiid) = @ccall Combase.IIDFromString(lpsz::LpifaceLESTR, lpiid::Ptr{IID})::HRESULT
WindowsCreateString(sourceString, len, str) = @ccall Combase.WindowsCreateString(sourceString::PCNZWCH, len::UINT, str::Ptr{HSTRING})::HRESULT
WindowsDeleteString(str) = @ccall Combase.WindowsDeleteString(str::HSTRING)::HRESULT
RoInitialize(initType) = @ccall Combase.RoInitialize(initType::UINT)::HRESULT
RoUninitialize() = @ccall Combase.RoUninitialize()::HRESULT
RoGetActivationFactory(activatableClassId::HSTRING, riid, out) = @ccall Combase.RoGetActivationFactory(activatableClassId::HSTRING, riid::REFIID, out::Ptr{Ptr{Cvoid}})::HRESULT
Base.reinterpret(t::Type) = v -> reinterpret(t, v)

function IIDFromString(sz::OLESTR)
    riid = IID() |> Ref
    hr = IIDFromString(sz, riid)
    return (iid = riid[], hresult = hr)
end

const IID_IAgileObject = GUID(0x94ea2b94, 0xe9cc, 0x49e0, 0xc0ff, 0xee64ca8f5b90)

abstract type Vtbl end

@kwdef struct Interface{T <: Vtbl}
    lpvtbl::Ptr{T} = C_NULL
end
PtrInterface = Ptr{Interface{T}} where T <: Vtbl 

# NB These will allocate
Vtbl(iface::Interface{T}) where T <: Vtbl = iface.lpvtbl |> unsafe_load
Vtbl(piface::PtrInterface) = piface |> unsafe_load |> Vtbl

Base.fieldoffset(t::DataType, field::Symbol) = fieldoffset(t, Base.fieldindex(t, field))

function function_ptr_old(pif::Ptr{<:Interface}, T::DataType, name::Symbol)
    @assert pif != C_NULL
    vtblptr = unsafe_load(Ptr{UInt64}(pif))
    local off
    if name == :QueryInterface; off = Base.fieldoffset(T, 1)
    elseif name == :AddRef; off = Base.fieldoffset(T, 2)
    elseif name == :Release; off = Base.fieldoffset(T, 3)
    else off = Base.fieldoffset(T, name)
    end
    methptr = unsafe_load(Ptr{UInt64}(vtblptr + off))
    return methptr |> Ptr{Cvoid}
end

function function_offset(list...)
    off = 0
    for i in 1:length(list)-1
        t = eval(list[i])
        f = list[i+1]
        # Special case for QueryInterface, AddRef, Release
        if f == :QueryInterface; off += Base.fieldoffset(t, 1)
        elseif f == :AddRef; off += Base.fieldoffset(t, 2)
        elseif f == :Release; off += Base.fieldoffset(t, 3)
        else off += Base.fieldoffset(t, f)
        end
    end
    return off
end

function function_ptr(pif::Ptr{<:Interface}, list...)
    @assert pif != C_NULL
    pvtbl = unsafe_load(Ptr{UInt64}(pif)) |> Ptr{UInt64}
    off = function_offset(list...)
    return unsafe_load(Ptr{UInt64}(pvtbl + off)) |> Ptr{Cvoid}
end

nctionptr(pif::Ptr{<:Interface}, t::Symbol, name::Symbol) = functionptr(pif, [t, name])

const IID_IUnknown = GUID(0x00000000, 0x0000, 0x0000, 0xC000, 0x000000000046)
@kwdef struct IUnknownVtbl <: Vtbl
    QueryInterface::Ptr{Cvoid} = C_NULL
    AddRef::Ptr{Cvoid} = C_NULL
    Release::Ptr{Cvoid} = C_NULL
end
const IUnknown = Interface{IUnknownVtbl}
AddRef(piface::Ptr{Interface{T}}) where T <: Vtbl = @ccall $(function_ptr(piface, :IUnknownVtbl, :AddRef))(piface::Ptr{Cvoid})::ULONG
Release(piface::Ptr{Interface{T}}) where T <: Vtbl = @ccall $(function_ptr(piface, :IUnknownVtbl, :Release))(piface::Ptr{Cvoid})::ULONG
QueryInterface(piface::Ptr{Interface{T}}, riid, ppv) where T <: Vtbl = @ccall $(function_ptr(piface, :IUnknownVtbl, :QueryInterface))(piface::Ptr{Cvoid}, riid::REFIID, ppv::Ptr{Ptr{Cvoid}})::HRESULT

sym_expr(s::String) = :(Symbol($s))

function comcall_internal(expr)
    @assert expr.head == Symbol("::") && expr.args[1].head == :call "Expression must be a function call with explicit types ala @ccall"
    funcexp = expr.args[1]
    rettype = expr.args[2]
    p1 = funcexp.args[2].args[1]
    argnames = [x.args[1] for x in funcexp.args[2:end]]
    argtypes = [x.args[2] for x in funcexp.args[2:end]]
    if funcexp.args[1] isa Symbol
        apinamesymexp = sym_expr("$(funcexp.args[1])")
        vttexp = sym_expr("$(argtypes[1].args[2])Vtbl")
        return :(ccall(function_ptr($p1, $vttexp, $apinamesymexp), $(rettype), ($(argtypes...),), $(argnames...)))
    elseif funcexp.args[1] isa Expr && funcexp.args[1].head == :.
        ifaceexp = sym_expr("$(funcexp.args[1].args[1])Vtbl")
        apinamesymexp = sym_expr("$(funcexp.args[1].args[2].value)")
        vttexp = sym_expr("$(argtypes[1].args[2])Vtbl")
        return :(ccall(function_ptr($p1, $vttexp, $ifaceexp, $apinamesymexp), $(rettype), ($(argtypes...),), $(argnames...)))
    end

    throw(ArgumentError("Invalid function expression"))
end

macro comcall(expr)
    return esc(comcall_internal(expr))
end

# @macroexpand @comcall AddRef(this::Ptr{IUnknown})::ULONG # test

function vtbl_exp(name::Symbol)
    sym = Symbol("$(name)Vtbl")
    return :($sym::$sym)
end

call_inherited_exp(im, name, i) = :($(im)(this::Ptr{$name}, args...) = $(im)(Ptr{$i}(this), args...))

# Drop types for params other than the first (this)
function untype_method(method::Expr)
    lhs = method.args[1]
    name = lhs.args[1]
    this = lhs.args[2]
    rest = map(x -> x.args[1], lhs.args[3:end])
    return :($name($this, $(rest...)))
end

is_void_ptr_expr(expr) = expr isa Expr && expr.head == :curly && length(expr.args) == 2 && expr.args[1] == :Ptr && expr.args[2] == :Cvoid

#==

Turns:

    @interface IFoo begin
        @inherit IBase
        Bar(this::Ptr{IFoo}, x::Int)::HRESULT
    end

Into:

    struct IFooVtbl <: Vtbl
        IBaseVtbl::IBaseVtbl = IBaseVtbl()
        Bar::Ptr{Cvoid}
    end
    IFoo = Interface{IFooVtbl}
    Bar(foo::Ptr{IFoo}, x) = @comcall Bar(foo::Ptr{IFoo}, x::Int)::HRESULT

Also, it creates a wrapper for the inherited methods:

    Bar(Ptr{IFoo}(this), args...) = Bar(Ptr{IBase}(this), args...)

==#

# TODO - Needs lots more validation and error handling
macro interface(name, block)
    vtblname = Symbol("$(name)Vtbl")

    # Convert @inherit lines
    inherits_list = block.args |> 
        filter(x -> x isa Expr && x.head == :macrocall && x.args[1] == Symbol("@inherit")) |> 
        map(x -> x.args[3])
    inherited_vtbls = inherits_list |> map(x -> vtbl_exp(x))

    # Get the inherited methods and create wrappers for them
    inherited_method_calls = Expr[]
    for i in inherits_list
        t = Symbol("$(i)Vtbl") |> eval
        # TODO - recurse nested inherits, currently only one level deep
        method_calls = fieldnames(t) |> 
            filter(f -> !(fieldtype(t, f) <: Vtbl)) |> 
            map(im -> call_inherited_exp(im, name, i))
        push!(inherited_method_calls, method_calls...)
    end

    # Convert the inline method definitions in to @commcall wrappers and create the Vtbl struct
    methods = block.args |> filter(x -> x isa Expr && x.head == Symbol("::"))
    comcalls = Expr[]
    for (i, method) in enumerate(methods)
        if !is_void_ptr_expr(method.args[2])
            callexp = :($(untype_method(method)) = $(comcall_internal(method)))
            push!(comcalls, callexp)
            methodname = method.args[1].args[1]
            methods[i] = :($methodname::Ptr{Cvoid})
        end
    end

    return esc(quote
        struct $vtblname <: Vtbl
            $(inherited_vtbls...)
            $(methods...)
        end
        const $name = Interface{$vtblname}
        $(comcalls...)
        $(inherited_method_calls...)
    end)
end

const IID_IInspectable = GUID(0xAF86E2E0, 0xB12D, 0x4C6A, 0x9C5A, 0xD7AA65101E90)
@interface IInspectable begin
    @inherit IUnknown
    GetIids(this::Ptr{IInspectable}, count::Ptr{UInt32}, iids::Ptr{Ptr{GUID}})::HRESULT
    GetRuntimeClassName(this::Ptr{IInspectable}, className::Ptr{HSTRING})::HRESULT
    GetTrustLevel(this::Ptr{IInspectable}, trustLevel::Ptr{TrustLevel})::HRESULT
end

const IID_ICloseable = GUID(0x30d5a829, 0x7fa4, 0x4026, 0x83bb, 0xd75bae4ea99e)
@interface ICloseable begin
    @inherit IUnknown
    Close(this::Ptr{ICloseable})::HRESULT
end

@interface IEventHandler begin
    @inherit IUnknown
    Invoke::Ptr{Cvoid}
end

const IID_IAsyncInfo = GUID(0x00000036, 0x0000, 0x0000, 0xC000, 0x000000000046)
@interface IAsyncInfo begin
    @inherit IInspectable
    get_Id::Ptr{Cvoid}
    get_Status::Ptr{Cvoid}
    get_ErrorCode::Ptr{Cvoid}
    Cancel::Ptr{Cvoid}
    Close::Ptr{Cvoid}
end

@interface IAsyncActionCompletedHandler begin
    @inherit IAsyncInfo
    Invoke::Ptr{Cvoid}
end

@interface IAsyncOperation begin
    @inherit IInspectable
    put_Completed::Ptr{Cvoid}
    get_Completed::Ptr{Cvoid}
    GetResults::Ptr{Cvoid}
end

# --- Helpers ---

# Wrapper for native COM object pointers, autoreleases on GC
mutable struct ComObj{T <: Interface} 
    ptr::Ptr{T}

    function ComObj{T}(pv::Ptr) where T <: Interface 
        co = new{T}(Ptr{T}(pv))

        finalizer(co) do x
            if x.ptr != C_NULL
                c = Release(x.ptr)
                # ptr = co.ptr
                # @async @info "ComObj AutoRelease: $ptr $c"
                x.ptr = C_NULL
            end
        end

        return co
    end
end
Base.getindex(r::ComObj) = r.ptr
ComObj{T}(rpv::Ref) where T <: Interface = ComObj{T}(Ptr{T}(rpv[]))

# Wrapper for Julia COM object
mutable struct JComObj{T <: Interface} 
    ptr::Ptr{T}
    robj::Ref # Preserves obj to keep ptr alive

    function JComObj{T}(robj::Ref) where T <: Interface
        ptr = pointer_from_objref(robj)
        co = new{T}(ptr, robj)
        return co
    end
end
Base.getindex(r::JComObj) = r.ptr
JComObj{T}(obj) where T <: Interface = JComObj{T}(Ref(obj))

function WindowsCreateString(sz::OLESTR)
    rhstr = HSTRING(0) |> Ref
    hr = WindowsCreateString(sz, length(sz)-1, rhstr)
    return (hstring = rhstr[], hresult = hr)
end
WindowsCreateString(str::String) = Base.cconvert(Cwstring, str) |> WindowsCreateString

function AssertSuccess(hr::HRESULT)
    if hr != S_OK; throw(ErrorException(@sprintf("HRESULT: 0x%x", reinterpret(UInt32, hr)))) end
    return hr
end

# Check hresult element is S_OK
# Return others as a Named Tuple unless there is only one element, then return the element
function AssertSuccess(vals::NamedTuple)
    if length(vals) == 0; return nothing end
    ks = [keys(vals)...]
    vs = [values(vals)...]
    ret = Pair{Symbol, Any}[]
    for i in eachindex(ks)
        k = ks[i]
        v = vs[i]
        if k == :hresult
            if v != S_OK; throw(ErrorException(@sprintf("HRESULT: 0x%x", reinterpret(UInt32, hr)))) end
            continue
        end
        push!(ret, k => v)
    end
    if length(ret) == 1; return ret[1][2] end
    return NamedTuple(ret)
end

# Check hresult (last element) is S_OK
# Return others as a tuple unless there is only one element, then return the element
function AssertSuccess(vals::Tuple)
    if length(vals) == 0; return nothing end
    # Assumes hresult is the last element
    if vals[end] != S_OK; throw(ErrorException(@sprintf("HRESULT: 0x%x", reinterpret(UInt32, hr)))) end
    if length(vals) > 2
        a = [vals...]
        av = a[1:end-1]
        return Tuple(av)
    end
    return vals[1]
end

# Release on GC finalizer
function AutoRelease(rpiface::Ref{PtrInterface{T}}) where T <: Vtbl
    finalizer(rpiface) do rpiface
        if rpiface[] != C_NULL
            c = Release(rpiface[])
            # piface = rpiface[]
            # @async @info "AutoRelease: $piface $c"
            rpiface[] = C_NULL
        end
    end
    return rpiface
end
AutoRelease(piface::PtrInterface) = AutoRelease(Ref(piface))

function RoGetActivationFactory(activatableClassId::Union{String, OLESTR}, riid, out) 
    hs = WindowsCreateString(activatableClassId).hstring
    RoGetActivationFactory(hs, riid, out)
    WindowsDeleteString(hs)
end

nothing