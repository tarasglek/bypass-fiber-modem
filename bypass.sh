#!/bin/bash
WAN_MAC=f8:2c:18:48:55:5c
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
# reset to factory mac address
# ethtool -P $WAN | awk '{{print $3}}' | xargs 
ip link set $WAN address $WAN_MAC
ip link set $WAN up
killall -w goeap_proxy
goeap_proxy -if-router $MODEM -if-wan $WAN &
ip link add link $WAN name $WAN_VLAN type vlan id 0
killall -w dhclient
dhclient $WAN_VLAN