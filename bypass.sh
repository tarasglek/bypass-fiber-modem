#!/bin/bash
export WAN_MAC=f8:2c:18:48:55:5c
export DUID=00:02:00:00:0d:e9:30:30:44:30:39:45:2d:31:37:31:36:31:4e:30:30:30:39:30:31
export MODEM=red-pos
export WAN=i350top
export WAN_VLAN=wan
until ip link show $WAN && ip link show $MODEM
do
  sleep 1
done
set -x
ip link del $WAN_VLAN || true
ip addr flush $WAN
ip link set $MODEM down
# reset to factory mac address
# ethtool -P $WAN | awk '{{print $3}}' | xargs 
ip link set $WAN address $WAN_MAC
ip link set $WAN up
ip link set $MODEM up
killall -w goeap_proxy
goeap_proxy -if-router $MODEM -if-wan $WAN &
ip link add link $WAN name $WAN_VLAN type vlan id 0
killall -w dhclient
until dhclient -4 -v $WAN_VLAN; do
  ip link set $MODEM down;
  sleep 5;
  ip link set $MODEM up;
done
# flush all ipv6 addresses
ip -6 addr flush label \*
echo default-duid $DUID\; > /var/lib/dhcp/dhclient6.leases
until dhclient -6 -v -cf /noconfig $WAN_VLAN; do
  ip link set $MODEM down;
  sysctl -w net.ipv6.conf.$WAN_VLAN.addr_gen_mode=0
  sysctl -w net.ipv6.conf.$WAN_VLAN.addr_gen_mode=1
  sleep 5;
  ip link set $MODEM up;
done