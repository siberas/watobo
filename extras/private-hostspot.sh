#!/bin/bash
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "Turning on Natting"
iptables -t nat -A POSTROUTING -o eno16777736 -j MASQUERADE

echo "Allowing ip forwarding"
echo 1 > /proc/sys/net/ipv4/ip_forward

