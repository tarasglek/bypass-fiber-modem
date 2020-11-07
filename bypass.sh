#!/bin/bash
# MAC=f8:2c:18:48:55:5c
export MODEM=red-pos
export WAN=i350top
until ip link show $WAN && ip link show $MODEM
do
  sleep 1
done
set -x
ip link del br0
ip addr flush $WAN
# reset to factory mac address
ethtool -P $WAN | awk '{{print $3}}' | xargs ip link set $WAN address
# creating a bridge
ip link add name br0 type bridge
ip link set br0 up
ip link del br0.wan
ip link add link br0 name br0.wan type macvlan
ip link set $WAN up
ip link set $MODEM up
#ip link set enp4s0 up
# add uplink and modem to bridge
ip link set $WAN master br0
ip link set $MODEM master br0
#this part forwards vlan traffic
ip link set br0 type bridge vlan_filtering 1
# this part is important. Without it the 802.1x EAP packets are not forwarded. Default behavior states to not forward auth traffic through a bridge
echo 8 > /sys/class/net/br0/bridge/group_fwd_mask
# https://www.haught.org/2018/04/13/att-router-bypass/
# forward auth traffic to att box
ebtables -t filter -A FORWARD -i $MODEM -p 802_1Q --vlan-encap 0x888e -j ACCEPT
ebtables -t filter -A FORWARD -i $MODEM -p 802_1Q -j DROP
ebtables -t filter -A FORWARD -o $MODEM -p 802_1Q --vlan-encap 0x888e -j ACCEPT
ebtables -t filter -A FORWARD -o $MODEM -p 802_1Q -j DROP
cd `dirname $0` && ./.venv/bin/python steal_dhcp.py $WAN br0.wan |sh
