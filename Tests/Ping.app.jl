using LibBaseTsd, CEnum, Sockets

include("../common/Win32.jl")
using .W32

import Base:Threads.@threads, Threads.@spawn, Threads.Atomic

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
# Seems like 1000 is the min
IcmpSendEcho(IcmpHandle, DestinationAddress, RequestData, RequestSize, RequestOptions, ReplyBuffer, ReplySize, Timeout) = @ccall Iphlpapi.IcmpSendEcho(IcmpHandle::HANDLE, DestinationAddress::IPAddr, RequestData::LPVOID, RequestSize::WORD, RequestOptions::PIP_OPTION_INFORMATION, ReplyBuffer::LPVOID, ReplySize::DWORD, Timeout::DWORD)::DWORD

@kwdef struct Echo
    name::String = "?"
    addr::IPv4 = IPv4(0)
    rtt::Int = 0
end

function main(args)
    if length(args) != 2
        addrs = getipaddrs(IPv4; loopback=false)
        @info "Addresses" addrs
        println("Usage: Ping <ipaddr> <timeout>")
        return
    end

    baseaddr = IPv4(args[1])
    baseaddr = IPv4(baseaddr.host & 0xFFFFFF00)
    timeout = parse(Int, args[2])
    @info "Ping" baseaddr timeout

    chan = Channel{Echo}(Inf)
    replies = Dict{IPv4, Echo}()
    
    @spawn while true
        try
            echo = take!(chan)
            if echo === nothing; break end
            name = echo.name
            addr = echo.addr
            rtt = echo.rtt
            @info "Reply" name addr rtt
            replies[addr] = echo
        catch e
            if e isa InvalidStateException; break end
            @error "Error" e
            break
        end
    end
    
    hndl = IcmpCreateFile()
    count = Atomic{Int}(0)
    @time @threads for i in 1:254
        name = "?"
        addr = IPv4(baseaddr.host & 0xFFFFFF00 | i)
        count[] += 1
        c = count[]
        @info "Sent #$c ($addr)"
        reply = IP_ECHO_REPLY() |> Ref
        haddr = addr.host |> hton |> IPAddr
        res = IcmpSendEcho(hndl, haddr, C_NULL, 0, C_NULL, reply, sizeof(reply), timeout)
        if res != 0 && reply[].Address.S_addr == haddr.S_addr
            name = getnameinfo(addr)
            rtt = Int(reply[].RoundTripTime)
            # status = reply[].Status
            push!(chan, Echo(name, addr, rtt))
        end
    end
    IcmpCloseHandle(hndl)
    close(chan)

    println()
    @info "Replies: $(length(replies))"

    sortbyaddr(replies) = sort(replies, by = x -> x[1])
    sorted = collect(replies) |> sortbyaddr

    for (addr, echo) in sorted
        name = echo.name
        rtt = echo.rtt
        @info "$addr $name ($(rtt)ms)"
    end

    nothing
end

main(ARGS)
