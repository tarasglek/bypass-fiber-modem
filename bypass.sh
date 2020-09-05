#!/bin/bash
until ip link show wan0 && ip link show bridge0
do
  sleep 1
done
set -x
ip link del br0
ip addr flush wan0
# reset to factory mac address
ethtool -P wan0 | awk '{{print $3}}' | xargs ip link set wan0 address
# creating a bridge
ip link add name br0 type bridge
ip link set br0 up
ip link set wan0 up
ip link set bridge0 up
#ip link set enp4s0 up
# add uplink and modem to bridge
ip link set wan0 master br0
ip link set bridge0 master br0
#this part forwards vlan traffic
ip link set br0 type bridge vlan_filtering 1
# this part is important. Without it the 802.1x EAP packets are not forwarded. Default behavior states to not forward auth traffic through a bridge
echo 8 > /sys/class/net/br0/bridge/group_fwd_mask
cd `dirname $0` && ./.venv/bin/python steal_dhcp.py wan0 br0
ip link set 