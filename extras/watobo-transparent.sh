#!/bin/bash
# configure your interfaces here
INT_IN=wlan0
INT_OUT=eth0

echo "= Interface Configuration ="
echo "Incoming Interface: $INT_IN"
echo "Outgoing Interface: $INT_OUT"

echo "Resetting IPTables ..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "Restarting DHCP ..."
/etc/init.d/dhcp3-server restart

echo "Restarting DNS ..."
/etc/init.d/bind9 restart

echo "Enable IP Forwarding ..."
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Send Packets To NFQUEUE ..."
iptables -t mangle -A PREROUTING -p tcp -m state --dport 443 --state NEW -j NFQUEUE --queue-num 0

echo "Redirect Traffic to WATOBO ..."
iptables -t nat -A PREROUTING -i $INT_IN -p tcp -m tcp -j REDIRECT --dport 443 --to-ports 8081
iptables -t nat -A PREROUTING -i $INT_IN -p tcp -m tcp -j REDIRECT --dport 80 --to-ports 8081

echo "Turn on Natting ..."
iptables -t nat -A POSTROUTING -o $INT_OUT -j MASQUERADE
