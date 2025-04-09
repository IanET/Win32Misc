# using LibBaseTsd
# using CEnum

# include("../common/Win32.jl")
# using .W32

# const Iphlpapi = "iphlpapi.dll"

# @kwdef struct IPAddr
#     S_addr::ULONG = 0
# end

# @kwdef struct IP_OPTION_INFORMATION
#     Ttl::UCHAR = 0
#     Tos::UCHAR = 0
#     Flags::UCHAR = 0
#     OptionsSize::UCHAR = 0
#     OptionsData::PUCHAR = C_NULL
# end
# const PIP_OPTION_INFORMATION = Ptr{IP_OPTION_INFORMATION}

# @kwdef struct sockaddr
#     sa_family::USHORT = 0
#     sa_data::NTuple{14, Cchar} = zeros(Cchar, 14) |> Tuple
# end
# const LPSOCKADDR = Ptr{sockaddr}

# @kwdef struct SOCKET_ADDRESS
#     lpSockaddr::LPSOCKADDR = C_NULL
#     iSockaddrLength::INT = 0
# end

# @kwdef struct IP_ADAPTER_ANYCAST_ADDRESS_XP
#     Length::ULONG = 0
#     Flags::DWORD = 0
#     Next::Ptr{IP_ADAPTER_ANYCAST_ADDRESS_XP} = C_NULL
#     Address::SOCKET_ADDRESS = SOCKET_ADDRESS(C_NULL, 0)
# end
# const PIP_ADAPTER_ANYCAST_ADDRESS_XP = Ptr{IP_ADAPTER_ANYCAST_ADDRESS_XP}
# const PIP_ADAPTER_DNS_SERVER_ADDRESS_XP = Ptr{IP_ADAPTER_ANYCAST_ADDRESS_XP}

# @kwdef struct IP_ADAPTER_MULTICAST_ADDRESS_XP
#     Length::ULONG = 0
#     Flags::DWORD = 0
#     Next::Ptr{IP_ADAPTER_MULTICAST_ADDRESS_XP} = C_NULL
#     Address::SOCKET_ADDRESS = SOCKET_ADDRESS()
# end
# const PIP_ADAPTER_MULTICAST_ADDRESS_XP = Ptr{IP_ADAPTER_MULTICAST_ADDRESS_XP}

# @cenum IF_OPER_STATUS begin
#     IfOperStatusUp = 1
#     IfOperStatusDown
#     IfOperStatusTesting
#     IfOperStatusUnknown
#     IfOperStatusDormant
#     IfOperStatusNotPresent
#     IfOperStatusLowerLayerDown
# end

# @cenum IFTYPE begin
#     IF_TYPE_OTHER = 1
#     IF_TYPE_ETHERNET_CSMACD = 6
#     IF_TYPE_ISO88025_TOKENRING = 9
#     IF_TYPE_PPP = 23
#     IF_TYPE_SOFTWARE_LOOPBACK = 24
#     IF_TYPE_ATM = 37
#     IF_TYPE_IEEE80211 = 71
#     IF_TYPE_TUNNEL = 131
#     IF_TYPE_IEEE1394 = 144
# end

# @cenum IF_OPER_STATUS begin
#     IfOperStatusUp = 1
#     IfOperStatusDown
#     IfOperStatusTesting
#     IfOperStatusUnknown
#     IfOperStatusDormant
#     IfOperStatusNotPresent
#     IfOperStatusLowerLayerDown
# end

# @kwdef struct IP_ADAPTER_PREFIX
#     Length::ULONG = 0
#     Flags::DWORD = 0
#     Next::Ptr{IP_ADAPTER_PREFIX} = C_NULL
#     Address::SOCKET_ADDRESS = SOCKET_ADDRESS(C_NULL, 0)
#     PrefixLength::ULONG = 0
# end
# const PIP_ADAPTER_PREFIX = Ptr{IP_ADAPTER_PREFIX}

# @cenum IP_PREFIX_ORIGIN begin
#     IpPrefixOriginOther = 0
#     IpPrefixOriginManual
#     IpPrefixOriginWellKnown
#     IpPrefixOriginDhcp
#     IpPrefixOriginRouterAdvertisement
# end

# @cenum IP_DAD_STATE begin
#     IpDadStateInvalid = 0
#     IpDadStateTentative
#     IpDadStateDuplicate
#     IpDadStateDeprecated
#     IpDadStatePreferred
# end

# const UINT8 = UInt8

# @kwdef struct IP_ADAPTER_UNICAST_ADDRESS_LH
#     Length::ULONG = 0
#     Flags::DWORD = 0
#     Next::Ptr{IP_ADAPTER_UNICAST_ADDRESS_LH} = C_NULL
#     Address::SOCKET_ADDRESS = SOCKET_ADDRESS(C_NULL, 0)
#     PrefixOrigin::IP_PREFIX_ORIGIN = 0
#     SuffixOrigin::IP_PREFIX_ORIGIN = 0
#     DadState::IP_DAD_STATE = 0
#     ValidLifetime::ULONG = 0
#     PreferredLifetime::ULONG = 0
#     LeaseLifetime::ULONG = 0
#     OnLinkPrefixLength::UINT8 = 0
# end
# const PIP_ADAPTER_UNICAST_ADDRESS_LH = Ptr{IP_ADAPTER_UNICAST_ADDRESS_LH}

# const PWCHAR = Ptr{Cwchar_t}

# const MAX_DNS_SUFFIX_STRING_LENGTH = 256

# @kwdef struct IP_ADAPTER_DNS_SUFFIX
#     Next::Ptr{IP_ADAPTER_DNS_SUFFIX} = C_NULL
#     String::NTuple{MAX_DNS_SUFFIX_STRING_LENGTH, Cwchar_t} = ntuple(_ -> '\0', MAX_DNS_SUFFIX_STRING_LENGTH)
# end
# const PIP_ADAPTER_DNS_SUFFIX = Ptr{IP_ADAPTER_DNS_SUFFIX}

# @kwdef struct IP_ADAPTER_WINS_SERVER_ADDRESS_LH
#     Length::ULONG = 0
#     Reserved::DWORD = 0
#     Next::Ptr{IP_ADAPTER_WINS_SERVER_ADDRESS_LH} = C_NULL
#     Address::SOCKET_ADDRESS = SOCKET_ADDRESS(C_NULL, 0)
# end
# const PIP_ADAPTER_WINS_SERVER_ADDRESS_LH = Ptr{IP_ADAPTER_WINS_SERVER_ADDRESS_LH}

# @kwdef struct IP_ADAPTER_GATEWAY_ADDRESS_LH
#     Length::ULONG = 0
#     Reserved::DWORD = 0
#     Next::Ptr{IP_ADAPTER_GATEWAY_ADDRESS_LH} = C_NULL
#     Address::SOCKET_ADDRESS = SOCKET_ADDRESS(C_NULL, 0)
# end
# const PIP_ADAPTER_GATEWAY_ADDRESS_LH = Ptr{IP_ADAPTER_GATEWAY_ADDRESS_LH}

# @kwdef struct IF_LUID
#     Value::UInt64 = 0
# end
# const PIF_LUID = Ptr{IF_LUID}

# const NET_IF_COMPARTMENT_ID = UInt32

# @kwdef struct GUID
#     Data1::UInt32 = 0
#     Data2::UInt16 = 0
#     Data3::UInt16 = 0
#     Data4::NTuple{8, UInt8} = ntuple(_ -> 0x00, 8)
# end
# const NET_IF_NETWORK_GUID = GUID

# @cenum NET_IF_CONNECTION_TYPE begin
#     NET_IF_CONNECTION_DEDICATED = 1
#     NET_IF_CONNECTION_PASSIVE
#     NET_IF_CONNECTION_DEMAND
#     NET_IF_CONNECTION_MAXIMUM
# end

# @cenum TUNNEL_TYPE begin
#     TUNNEL_TYPE_NONE = 0
#     TUNNEL_TYPE_OTHER = 1
#     TUNNEL_TYPE_DIRECT = 2
#     TUNNEL_TYPE_6TO4 = 11
#     TUNNEL_TYPE_ISATAP = 13
#     TUNNEL_TYPE_TEREDO = 14
#     TUNNEL_TYPE_IPHTTPS = 15
# end

# const MAX_DHCPV6_DUID_LENGTH = 130

# @kwdef struct IP_ADAPTER_ADDRESSES_LH
#     Length::ULONG = 0
#     IfIndex::DWORD = 0
#     Next::Ptr{IP_ADAPTER_ADDRESSES_LH} = C_NULL
#     AdapterName::PCHAR = C_NULL
#     FirstUnicastAddress::PIP_ADAPTER_UNICAST_ADDRESS_LH = C_NULL
#     FirstAnycastAddress::PIP_ADAPTER_ANYCAST_ADDRESS_XP = C_NULL
#     FirstMulticastAddress::PIP_ADAPTER_MULTICAST_ADDRESS_XP = C_NULL
#     FirstDnsServerAddress::PIP_ADAPTER_DNS_SERVER_ADDRESS_XP = C_NULL
#     DnsSuffix::PWCHAR = C_NULL
#     Description::PWCHAR = C_NULL
#     FriendlyName::PWCHAR = C_NULL
#     PhysicalAddressLength::BYTE = 0
#     Flags::ULONG = 0
#     Mtu::ULONG = 0
#     IfType::IFTYPE = 0
#     OperStatus::IF_OPER_STATUS = 0
#     Ipv6IfIndex::ULONG = 0
#     ZoneIndices::NTuple{16, ULONG} = zeros(ULONG, 16) |> Tuple
#     FirstPrefix::PIP_ADAPTER_PREFIX = C_NULL
#     TransmitLinkSpeed::UInt64 = 0
#     ReceiveLinkSpeed::UInt64 = 0
#     FirstWinsServerAddress::PIP_ADAPTER_WINS_SERVER_ADDRESS_LH = C_NULL
#     FirstGatewayAddress::PIP_ADAPTER_GATEWAY_ADDRESS_LH = C_NULL
#     Ipv4Metric::ULONG = 0
#     Ipv6Metric::ULONG = 0
#     Luid::IF_LUID = IF_LUID(0, 0)
#     Dhcpv4Server::SOCKET_ADDRESS = SOCKET_ADDRESS(C_NULL, 0)
#     CompartmentId::NET_IF_COMPARTMENT_ID = 0
#     NetworkGuid::NET_IF_NETWORK_GUID = NTuple{16, UInt8}(ntuple(_ -> 0x00, 16))
#     ConnectionType::NET_IF_CONNECTION_TYPE = 0
#     TunnelType::TUNNEL_TYPE = 0
#     Dhcpv6Server::SOCKET_ADDRESS = SOCKET_ADDRESS(C_NULL, 0)
#     Dhcpv6ClientDuid::NTuple{MAX_DHCPV6_DUID_LENGTH, BYTE} = ntuple(_ -> 0x00, MAX_DHCPV6_DUID_LENGTH)
#     Dhcpv6ClientDuidLength::ULONG = 0
#     Dhcpv6Iaid::ULONG = 0
#     FirstDnsSuffix::PIP_ADAPTER_DNS_SUFFIX = C_NULLs
# end
# const IP_ADAPTER_ADDRESSES = IP_ADAPTER_ADDRESSES_LH
# const PIP_ADAPTER_ADDRESSES = Ptr{IP_ADAPTER_ADDRESSES}

# IcmpCreateFile() = @ccall Iphlpapi.IcmpCreateFile()::HANDLE
# IcmpCloseHandle(h) = @ccall Iphlpapi.IcmpCloseHandle(h::HANDLE)::BOOL
# IcmpSendEcho(IcmpHandle, DestinationAddress, RequestData, RequestSize, RequestOptions, ReplyBuffer, ReplySize, Timeout) = @ccall Iphlpapi.IcmpSendEcho(IcmpHandle::HANDLE, DestinationAddress::IPAddr, RequestData::LPVOID, RequestSize::WORD, RequestOptions::PIP_OPTION_INFORMATION, ReplyBuffer::LPVOID, ReplySize::DWORD, Timeout::DWORD)::DWORD
# GetAdaptersAddresses(Family, Flags, Reserved, AdapterAddresses, SizePointer) = @ccall Iphlpapi.GetAdaptersAddresses(Family::DWORD, Flags::DWORD, Reserved::LPVOID, AdapterAddresses::PIP_ADAPTER_ADDRESSES, SizePointer::PULONG)::DWORD

# buffsize = ULONG(0) |> Ref
# res = GetAdaptersAddresses(0, 0, C_NULL, C_NULL, buffsize)
# @show buffsize[]

# buf = zeros(UInt8, buffsize[])
# res = GetAdaptersAddresses(0, 0, C_NULL, buf, buffsize)
# @show res

# currentAdapter = unsafe_load(pointer(buf) |> PIP_ADAPTER_ADDRESSES)
# unicastAddress = currentAdapter.FirstUnicastAddress