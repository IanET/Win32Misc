using LibBaseTsd, CEnum, Sockets

include("../common/Win32.jl")
using .W32

const Iphlpapi = "iphlpapi.dll"

@kwdef struct IPAddr
    S_addr::ULONG = 0
end

@kwdef struct IP_OPTION_INFORMATION
    Ttl::UCHAR = 0
    Tos::UCHAR = 0
    Flags::UCHAR = 0
    OptionsSize::UCHAR = 0
    OptionsData::LPVOID = C_NULL
end
const PIP_OPTION_INFORMATION = Ptr{IP_OPTION_INFORMATION}

@kwdef struct IP_ECHO_REPLY
    Address::IPAddr = IPAddr()
    Status::ULONG = 0
    RoundTripTime::ULONG = 0
    DataSize::USHORT = 0
    Reserved::USHORT = 0
    Data::PVOID = C_NULL
    Options::IP_OPTION_INFORMATION = IP_OPTION_INFORMATION()
end
const PIP_ECHO_REPLY = Ptr{IP_ECHO_REPLY}

IcmpCreateFile() = @ccall Iphlpapi.IcmpCreateFile()::HANDLE
IcmpCloseHandle(h) = @ccall Iphlpapi.IcmpCloseHandle(h::HANDLE)::BOOL
IcmpSendEcho(IcmpHandle, DestinationAddress, RequestData, RequestSize, RequestOptions, ReplyBuffer, ReplySize, Timeout) = @ccall Iphlpapi.IcmpSendEcho(IcmpHandle::HANDLE, DestinationAddress::IPAddr, RequestData::LPVOID, RequestSize::WORD, RequestOptions::PIP_OPTION_INFORMATION, ReplyBuffer::LPVOID, ReplySize::DWORD, Timeout::DWORD)::DWORD

addrs = getipaddrs(IPv4; loopback=false)

hndl = IcmpCreateFile()
ip = ip"192.168.139.1".host |> hton |> IPAddr

reply = IP_ECHO_REPLY() |> Ref
res = IcmpSendEcho(hndl, ip, C_NULL, 0, C_NULL, reply, sizeof(reply), 1000)

