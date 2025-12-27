using LibBaseTsd
using Sockets
import Base:GC.@preserve

const DNSAPI = "dnsapi.dll"
const KERNEL32 = "kernel32.dll"

const DNS_STATUS = UInt32
const ULONG64 = UInt64
const PCWSTR = Ptr{WCHAR}
const IP4_ADDRESS = DWORD

const DNS_QUERY_MULTICAST = 0x00000001
const DNS_QUERY_STANDARD = 0x00000000
const DNS_MAX_NAME_BUFFER_LENGTH = 256
const DNS_QUERY_REQUEST_VERSION1 = 1
const DNS_QUERY_REQUEST_VERSION2 = 2
const DNS_TYPE_A = 0x0001
const DNS_TYPE_NULL = 0x000A
const DNS_TYPE_PTR = 0x000C
const DNS_TYPE_TXT = 0x0010
const DNS_TYPE_AAAA = 0x001C
const DNS_TYPE_SRV = 0x0021
const DNS_TYPE_ALL = 0x00FF
const DNS_TYPE_NSEC = 0x002F
const MAX_CNAME_LEN = 256

const ERROR_SUCCESS = 0x00000000
const ERROR_INVALID_PARAMETER = 0x00000057
const ERROR_CANCELLED = 0x000004c7

const ANSI_GREY = "\e[90m"
const ANSI_RESET = "\e[0m"

@kwdef struct MDNS_QUERY_REQUEST
    Version::ULONG = DNS_QUERY_REQUEST_VERSION1
    ulRefCount::ULONG = 0
    Query::LPWSTR = C_NULL
    QueryType::WORD = DNS_TYPE_PTR
    QueryOptions::ULONG64 = DNS_QUERY_STANDARD
    InterfaceIndex::ULONG = 0
    pQueryCallback::LPVOID = C_NULL
    pQueryContext::LPVOID = C_NULL
    fAnswerReceived::BOOL = 0
    ulResendCount::ULONG = 0
end

@kwdef struct MDNS_QUERY_HANDLE
    nameBuf::NTuple{DNS_MAX_NAME_BUFFER_LENGTH, WCHAR} = zeros(WCHAR, DNS_MAX_NAME_BUFFER_LENGTH) |> Tuple
    wType::WORD = 0
    pSubscription::PVOID = C_NULL
    pWnfCallbackParams::PVOID = C_NULL
    stateNameData::NTuple{2, ULONG} = (0, 0)
end

@kwdef struct DNS_RECORD
    pNext::Ptr{DNS_RECORD} = C_NULL
    pName::PCWSTR = C_NULL
    wType::WORD = 0
    wDataLength::WORD = 0
    Flags::ULONG = 0
    dwTtl::DWORD = 0
    dwReserved::DWORD = 0
end

@kwdef struct DNS_RECORD_PTR
    record::DNS_RECORD = DNS_RECORD()
    pNameHost::PCWSTR = C_NULL
end

@kwdef struct DNS_RECORD_A
    record::DNS_RECORD = DNS_RECORD()
    IpAddress::IP4_ADDRESS
end

@kwdef struct DNS_RECORD_AAAA
    record::DNS_RECORD = DNS_RECORD()
    Ip6Address::NTuple{16, UInt8} = ntuple(_ -> 0x00, 16)
end

@kwdef struct DNS_RECORD_SRV
    record::DNS_RECORD = DNS_RECORD()
    pNameTarget::PCWSTR = C_NULL
    wPriority::WORD = 0
    wWeight::WORD = 0
    wPort::WORD = 0
    pad::WORD = 0
end

@kwdef struct DNS_RECORD_TXT
    record::DNS_RECORD = DNS_RECORD()
    dwStringCount::DWORD = 0
    pStringArray::Ptr{PCWSTR} = C_NULL
end

@kwdef struct DNS_QUERY_RESULT
    Version::ULONG = 0
    QueryStatus::DNS_STATUS = 0
    QueryOptions::ULONG64 = 0
    pQueryRecords::Ptr{DNS_RECORD} = C_NULL
    Reserved::PVOID = 0
end

DnsStartMulticastQuery(pQueryRequest, pHandle) = @ccall DNSAPI.DnsStartMulticastQuery(pQueryRequest::Ptr{MDNS_QUERY_REQUEST}, pHandle::Ptr{MDNS_QUERY_HANDLE})::DNS_STATUS
DnsStopMulticastQuery(pHandle) = @ccall DNSAPI.DnsStopMulticastQuery(pHandle::Ptr{MDNS_QUERY_HANDLE})::DNS_STATUS
GetLastError() = @ccall KERNEL32.GetLastError()::DWORD
SleepEx(dwMilliseconds, bWait) = @ccall KERNEL32.SleepEx(dwMilliseconds::DWORD, bWait::BOOL)::DWORD

transcode_to_str(wstr::AbstractVector{WCHAR})::String = transcode(String, @view wstr[begin:end-1])
ipv4_string(ip::IP4_ADDRESS)::String = join([ip & 0xFF, ip >> 8 & 0xFF, ip >> 16 & 0xFF, ip >> 24 & 0xFF], ".")

function string_from_pwchar(pwstr::LPWSTR)::String
    str = unsafe_wrap(Array, pwstr, MAX_CNAME_LEN)
    inull = findfirst(isequal(WCHAR(0)), str)
    return transcode_to_str(@view str[begin:inull])
end

function transcode_to_str(wstr::MemoryRef{WCHAR})::String
    izero = findfirst(isequal(WCHAR(0)), wstr.mem)
    return transcode(String, @view wstr.mem[begin:izero-1])
end

_calls::Int = 0
_records::Dict{IPAddr, String} = Dict{IPAddr, String}()

function queryCallback(pQueryContext::PVOID, pQueryHandle::Ptr{MDNS_QUERY_HANDLE}, pQueryResults::Ptr{DNS_QUERY_RESULT})::Cvoid
    try
        global _calls += 1
        res = unsafe_load(pQueryResults)
        prec = res.pQueryRecords
        # @info "Query callback invoked" res prec

        if res.QueryStatus == ERROR_CANCELLED
            @info "Query cancelled"
            return nothing
        end

        while prec != C_NULL
            rec = unsafe_load(prec)
            name = string_from_pwchar(rec.pName)

            if rec.wType == DNS_TYPE_PTR
                ptrrec = unsafe_load(Ptr{DNS_RECORD_PTR}(prec))
                host = string_from_pwchar(ptrrec.pNameHost)
                # @info "PTR record" name host
            elseif rec.wType == DNS_TYPE_A
                arec = unsafe_load(Ptr{DNS_RECORD_A}(prec))
                addr = IPv4(arec.IpAddress)
                if !haskey(_records, addr)
                    _records[addr] = name
                    # @info "A record" name ipv4_string(addr)
                    @info "A record" name addr
                end
                # @info "A record" name addr
            elseif rec.wType == DNS_TYPE_SRV
                srvrec = unsafe_load(Ptr{DNS_RECORD_SRV}(prec))
                target = string_from_pwchar(srvrec.pNameTarget)
                # @info "SRV record" name target
            elseif rec.wType == DNS_TYPE_TXT
                txtrec = unsafe_load(Ptr{DNS_RECORD_TXT}(prec))
                # @info "TXT record" name txtrec.dwStringCount
            elseif rec.wType == DNS_TYPE_AAAA
                aaarec = unsafe_load(Ptr{DNS_RECORD_AAAA}(prec))
                addr = reverse(aaarec.Ip6Address) |> a -> reinterpret(UInt128, a)[1] |> IPv6
                if !haskey(_records, addr)
                    _records[addr] = name
                    @info "AAAA record" name addr
                end
            else
                @info "$(ANSI_GREY)Other record$(ANSI_RESET)" rec.wType name
            end
            prec = rec.pNext
        end

        # @info "Query callback done"
    catch e
        @error "Error in query callback: " e
        # @info "Stacktrace: " catch_backtrace() |> stacktrace
    end
    return nothing
end

const TIMEOUT_SEC = 30
service = L"_services._dns-sd._udp.local"
# service = L"_googlecast._tcp.local"
# service = L"_workstation._tcp.local"
# service = L"_ssh._tcp.local"
# service = L"_http._tcp.local"
# service = L"_udisks-ssh._tcp.local"

request = MDNS_QUERY_REQUEST(
    Query = pointer(service), 
    pQueryCallback = @cfunction(queryCallback, Cvoid, (PVOID, Ptr{MDNS_QUERY_HANDLE}, Ptr{DNS_QUERY_RESULT}))
) |> Ref

handle = MDNS_QUERY_HANDLE() |> Ref

@info "Starting multicast query: " transcode_to_str(service)

@preserve service status = DnsStartMulticastQuery(request, handle)
# error = GetLastError()
# @show status error
@assert status == ERROR_SUCCESS
@info "Multicast query started"

# SleepEx(10*1000, TRUE)
@info "Waiting for responses for $TIMEOUT_SEC seconds..."
sleep(TIMEOUT_SEC)

@info "Stopping multicast query..."
DnsStopMulticastQuery(handle)
@info "Multicast query stopped"
@info "Number of calls to query callback: " _calls length(_records)
@info "Records" _records

sleep(1)
