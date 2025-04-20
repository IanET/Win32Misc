using LibBaseTsd, CEnum, Sockets

include("../common/Win32.jl")
using .W32

import Base:Threads.@threads, Threads.@spawn

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

@kwdef struct Echo
    name::String = "?"
    addr::IPv4 = IPv4(0)
    rtt::Int = 0
end

function main(args)

    timeout = 100
    if length(args) > 0
        timeout = parse(Int, args[1])
    end
    @info "main" timeout


    addrs = getipaddrs(IPv4; loopback=false)
    ip = ip"192.168.139.1".host |> hton |> IPAddr

    # reply = IP_ECHO_REPLY() |> Ref
    # res = IcmpSendEcho(hndl, ip, C_NULL, 0, C_NULL, reply, sizeof(reply), 1000)
    # @info "IcmpSendEcho" res reply[].RoundTripTime reply[].Status

    chan = Channel{Echo}(Inf)
    replies = Dict{IPv4, Echo}()
    # replies = 0
    # sent = Threads.Atomic{Int}(0)
    
    @spawn while true
        try
            echo = take!(chan)
            # replies += 1
            if echo === nothing; break end
            name = echo.name
            addr = echo.addr
            rtt = echo.rtt
            @info "Reply" name addr rtt
            replies[addr] = echo
        catch e
            @error "Error" e
        end
    end
    
    hndl = IcmpCreateFile()
    @threads for i in 1:254
        # sent[] += 1
        name = "?"
        addr = IPv4("192.168.139.$i")
        # println("$i: $addr\n")
        @info addr
        reply = IP_ECHO_REPLY() |> Ref
        res = IcmpSendEcho(hndl, addr.host |> hton |> IPAddr, C_NULL, 0, C_NULL, reply, sizeof(reply), timeout)
        if res != 0
            name = getnameinfo(addr)
            rtt = Int(reply[].RoundTripTime)
            status = reply[].Status
            # @info "IcmpSendEcho" addr res name rtt status
            push!(chan, Echo(name, addr, rtt))
        end
    end
    IcmpCloseHandle(hndl)
    close(chan)

    println()
    @info "Replies" length(replies)
    println()

    sortbyaddr(replies) = sort(replies, by = x -> x[1])
    sorted = collect(replies) |> sortbyaddr
    for (addr, echo) in sorted
        name = echo.name
        rtt = echo.rtt
        @info addr name rtt
    end

    # for (addr, echo) in replies
    #     name = echo.name
    #     rtt = echo.rtt
    #     @info addr name rtt
    # end
end

main(ARGS)
