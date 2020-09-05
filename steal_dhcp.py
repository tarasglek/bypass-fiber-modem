#! /usr/bin/env python
from scapy.all import *
import sys

def main(wan, br):
    def arp_monitor_callback(pkt):
        if DHCP in pkt:
            info = {}
            for ls in pkt[DHCP].options:
                info[ls[0]]=ls[1]
            router = info.get('router')
            if router == None:
                return
            ip = pkt[IP].dst
            netmask = info['subnet_mask']
            mac = pkt[Ether].dst
            print(("set -x\n"
                f"ip link del {br}\n"
                f"ifconfig {wan} {ip} netmask {netmask}\n"
                f"ip route add default via {router}"
                f"ip link set wan0 address {mac}\n"
            ))
            sys.exit(0)
    # reduce python overhead by only scanning packets that are dhcp or have vlan tag
    # shoud be very few of these
    sniff(prn=arp_monitor_callback, iface=wan, filter="vlan or (udp and (port 67 or 68))", store=0)
    # sniff(offline="foo.pcap", prn=arp_monitor_callback,filter="vlan or (udp and (port 67 or 68))", store=0 )

if __name__ == "__main__":
    main(*sys.argv[1:])