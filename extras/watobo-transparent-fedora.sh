#!/bin/bash
# configure your interfaces here
echo "+ find wifi interfaces ... "
result=$(nmcli dev | grep " wifi " | awk '{print $1 }')
if [ -n "$result" ]; then
  PS3='Please select the WIFI interface:  '
  options=($(nmcli dev | grep " wifi " | awk '{print $1 }'))
  select opt in "${options[@]}"
  do
    INT_WIFI=$opt
    break
  done

else
  echo "! could not find a wifi interface. Please check your network configuration"
  exit
fi

echo -n "+ find lan interface ... "
result=$(nmcli dev | grep " ethernet " | grep 'connected' | awk '{print $1 }')
if [ -n "$result" ]; then
  INT_LAN=$result
else
  echo "! could not find a lan interface. Please check your network configuration"
  exit
fi
echo "[OK]"

echo "= Interface Configuration ="
echo "WIFI Interface: $INT_WIFI"
echo "LAN Interface: $INT_LAN"
#echo "Resetting IPTables ..."
#iptables -F
#iptables -X
#iptables -t nat -F
#iptables -t nat -X
#iptables -t mangle -F
#iptables -t mangle -X
#iptables -P INPUT ACCEPT
#iptables -P FORWARD ACCEPT
#iptables -P OUTPUT ACCEPT

echo "+ setup wifi configuration"
CON_AP_NAME="watobo-ap"
CON_LOCAL_NAME="watobo-local"
AP_PW=$(openssl rand -hex 24)
nmcli con delete $CON_AP_NAME
nmcli con delete $CON_LOCAL_NAME
nmcli con add type wifi ifname $INT_WIFI con-name $CON_AP_NAME autoconnect yes ssid $CON_AP_NAME
#nmcli connection add type ethernet ifname $INT_LAN ipv4.method shared con-name $CON_LOCAL_NAME
#nmcli connection modify ifname $INT_LAN ipv4.method shared

nmcli con modify $CON_AP_NAME 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
nmcli con modify $CON_AP_NAME wifi-sec.key-mgmt wpa-psk
nmcli con modify $CON_AP_NAME wifi-sec.psk $AP_PW
nmcli con up $CON_AP_NAME
#nmcli con up $CON_LOCAL_NAME

#nmcli connection show $CON_AP_NAME
nmcli device wifi show-password


# not necessary on nmcli
#echo "Enable IP Forwarding ..."
#echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Send Packets To NFQUEUE ..."
iptables -t mangle -A PREROUTING -p tcp -m state --dport 443 --state NEW -j NFQUEUE --queue-num 0

echo "Redirect Traffic to WATOBO ..."
iptables -t nat -A PREROUTING -i $INT_WIFI -p tcp -m tcp -j REDIRECT --dport 443 --to-ports 8081
iptables -t nat -A PREROUTING -i $INT_WIFI -p tcp -m tcp -j REDIRECT --dport 80 --to-ports 8081

# not necessary on nmcli
#echo "Turn on Natting ..."
#iptables -t nat -A POSTROUTING -o $INT_LAN -j MASQUERADE
