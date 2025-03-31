using LibBaseTsd
import Base:GC.@preserve

const DNSAPI = "dnsapi.dll"
const KERNEL32 = "kernel32.dll"

const DNS_STATUS = UInt32
const ULONG64 = UInt64
const PCWSTR = Ptr{WCHAR}

const DNS_QUERY_MULTICAST = 0x00000001
const DNS_QUERY_STANDARD = 0x00000000
const DNS_MAX_NAME_BUFFER_LENGTH = 256
const DNS_QUERY_REQUEST_VERSION1 = 1
const DNS_QUERY_REQUEST_VERSION2 = 2
const DNS_TYPE_ALL = 0x00FF
const ERROR_SUCCESS = 0x00000000
const ERROR_INVALID_PARAMETER = 0x00000057

@kwdef struct MDNS_QUERY_REQUEST
    Version::ULONG = DNS_QUERY_REQUEST_VERSION1
    ulRefCount::ULONG = 0
    Query::LPWSTR = C_NULL
    QueryType::WORD = DNS_TYPE_ALL
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
    stateNameData::NTuple{2, ULONG} = (0, 0) |> Tuple
end

@kwdef struct DNS_RECORD
    pNext::Ptr{DNS_RECORD} = C_NULL
    pName::PCWSTR = C_NULL
    wType::WORD = 0
    wDataLength::WORD = 0
    Flags::ULONG = 0
    dwTtl::DWORD = 0
    dwReserved::DWORD = 0
    # TBD
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

_calls::Int = 0
function queryCallback(pQueryContext::PVOID, pQueryHandle::Ptr{MDNS_QUERY_HANDLE}, pQueryResults::Ptr{DNS_QUERY_RESULT})::Cvoid
    # @async @info "Query callback invoked"
    global _calls += 1
    nothing
end

service = L"_googlecast._tcp.local"
request = MDNS_QUERY_REQUEST(
    Query = pointer(service), 
    pQueryCallback = @cfunction(queryCallback, Cvoid, (PVOID, Ptr{MDNS_QUERY_HANDLE}, Ptr{DNS_QUERY_RESULT}))
) |> Ref

handle = MDNS_QUERY_HANDLE() |> Ref

@info "Starting multicast query..."
@preserve service status = DnsStartMulticastQuery(request, handle)
# error = GetLastError()
# @show status error
@assert status == ERROR_SUCCESS
@info "Multicast query started."

sleep(5)

@info "Stopping multicast query..."
DnsStopMulticastQuery(handle)
@info "Multicast query stopped."
@info "Number of calls to query callback: " _calls

