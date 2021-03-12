iptables -t mangle -L --line-numbers
iptables -t mangle -D PREROUTING 1
iptables -t nat -L --line-numbers
iptables -t nat -D PREROUTING 1
iptables -t nat -L --line-numbers
iptables -t nat -D PREROUTING 1

