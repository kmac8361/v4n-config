#!/bin/bash
#version 0.1
#set -x 

#A script to configure a factory default Mikrotik CRS125 switch for the Orangebox
#Also usable to rebuild a misconfigured switch - reset using hardware reset button first.

if [ "$(id -u)" != "0" ]; then
  echo "Must be run with sudo or by root"
  exit 77
fi

#get interface names

#declare interface=()
#for inter_face in $(ifconfig | egrep "eno|enp|enx" | awk '{print $1}')
#do
#   echo "Interface read $inter_face"
#   interface=("${interface[@]}" "$inter_face")
#   echo "Interface assigned "${interface[@]}""
#done

interface=$(ifconfig -a | grep enp | awk '{print $1}')

if ( ip addr show eth0 ) ; then
    INT=eth0
else
    INT=${interface}
fi

# Tell us what the primary interface name is
#
echo
echo
echo "Primary int is $INT"
echo

#OB=$(hostname | sed -e "s/[^0-9]//g")
# Get OrangeBox number
#
OB=`hostname | cut -c 10-`
BYTE1=$(echo $OB | cut -c 1)
BYTE2=$(echo $OB | cut -c 2-)

# Parse the variables for the OrangeBox number to eliminate any zero's at the beginning of the number.
#
if [ $BYTE1 -eq 0 ] 
then
	OB=$BYTE2
fi

# Set the network subnet variables
#
PLUS1=`expr $OB + 1`
PLUS2=`expr $OB + 2`
PLUS3=`expr $OB + 3`

ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R 192.168.88.1
ssh-keygen -f "/root/.ssh/known_hosts" -R 192.168.88.1

# Adding the primary interface of Node 0 to the 88 subnet for communication with the switch
#
echo
echo "Adding IP 192.168.88.2/24 to $INT"
sudo ip addr add 192.168.88.2/24 dev $INT

echo
echo "Adding IP 172.27.252.199/22 to $INT"
sudo ip addr add 172.27.252.199/22 dev $INT

echo
echo "Completed adding IPs"
echo
echo "Waiting 10 seconds for interfaces to come up ..."
sleep 10

# Remove the configuration file already in place
#
rm Orangebox$OB-initial-config.rsc

# Start the buildout of the new configuration file
#
echo
echo
echo "This is OrangeBox$OB...building a configuration file now..."

echo "/interface bridge" >>Orangebox$OB-initial-config.rsc
echo "remove 0" >>Orangebox$OB-initial-config.rsc

echo "add name=vlan1" >>Orangebox$OB-initial-config.rsc

echo "add name=vlan2" >>Orangebox$OB-initial-config.rsc

echo "add name=vlan-laptop_wireless" >>Orangebox$OB-initial-config.rsc

echo "/interface wireless" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=wlan1 ] disabled=no mode=ap-bridge name=wlan3" >>Orangebox$OB-initial-config.rsc

echo "/interface ethernet" >>Orangebox$OB-initial-config.rsc
echo "set master-port=none 1,22,24" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether1 ] name=ether1-master-local" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether2 ] name=ether2-master-local" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether23 ] name=ether23-master-local" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether24 ] master-port=ether23-master-local name=ether24-slave-local" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether3 ] master-port=ether2-master-local name=node1-eth0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether4 ] master-port=ether2-master-local name=node1-usb0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether5 ] master-port=ether2-master-local name=node2-eth0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether6 ] master-port=ether2-master-local name=node2-usb0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether7 ] master-port=ether2-master-local name=node3-eth0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether8 ] master-port=ether2-master-local name=node3-usb0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether9 ] master-port=ether2-master-local name=node4-eth0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether10 ] master-port=ether2-master-local name=node4-usb0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether11 ] master-port=ether2-master-local name=node5-eth0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether12 ] master-port=ether2-master-local name=node5-usb0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether13 ] master-port=ether2-master-local name=node6-eth0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether14 ] master-port=ether2-master-local name=node6-usb0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether15 ] master-port=ether2-master-local name=node7-eth0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether16 ] master-port=ether2-master-local name=node7-usb0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether17 ] master-port=ether2-master-local name=node8-eth0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether18 ] master-port=ether2-master-local name=node8-usb0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether19 ] master-port=ether2-master-local name=node9-eth0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether20 ] master-port=ether2-master-local name=node9-usb0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether21 ] master-port=ether2-master-local name=node10-eth0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=ether22 ] master-port=ether2-master-local name=node10-usb0" >>Orangebox$OB-initial-config.rsc

echo "set [ find default-name=sfp1 ] name=sfp1-master-local" >>Orangebox$OB-initial-config.rsc

echo "/ip neighbor discovery" >>Orangebox$OB-initial-config.rsc

echo "set ether1-master-local discover=no" >>Orangebox$OB-initial-config.rsc

echo "/interface wireless" >>Orangebox$OB-initial-config.rsc

echo "add disabled=no mac-address=E6:8D:8C:B3:4B:43 master-interface=wlan3 name=wlan2 ssid=Canonical wds-default-bridge=vlan-laptop_wireless" >>Orangebox$OB-initial-config.rsc
echo "set ssid=OrangeBox$OB 1" >>Orangebox$OB-initial-config.rsc
echo "disable 0,1" >>Orangebox$OB-initial-config.rsc

echo "/interface wireless security-profiles" >>Orangebox$OB-initial-config.rsc

echo "set [ find default=yes ] authentication-types=wpa-psk,wpa2-psk mode=dynamic-keys supplicant-identity=MikroTik wpa-pre-shared-key=adroitreliable wpa2-pre-shared-key=adroitreliable" >>Orangebox$OB-initial-config.rsc

echo "/ip ipsec proposal" >>Orangebox$OB-initial-config.rsc

echo "set [ find default=yes ] enc-algorithms=aes-128-cbc" >>Orangebox$OB-initial-config.rsc

echo "/ip pool" >>Orangebox$OB-initial-config.rsc

echo "add name=vlan3-pool ranges=172.27.254.101-172.27.255.254" >>Orangebox$OB-initial-config.rsc

echo "/ip dhcp-server" >>Orangebox$OB-initial-config.rsc

echo "add address-pool=vlan3-pool disabled=no interface=vlan-laptop_wireless lease-time=12h name=dhcpserver-vlan3" >>Orangebox$OB-initial-config.rsc

echo "/routing ospf instance" >>Orangebox$OB-initial-config.rsc

echo "set [ find default=yes ] metric-bgp=75 metric-connected=50 redistribute-bgp=as-type-1 redistribute-connected=as-type-1 router-id=172.27.252.$OB" >>Orangebox$OB-initial-config.rsc

echo "/interface bridge port" >>Orangebox$OB-initial-config.rsc
echo "remove 0,1" >>Orangebox$OB-initial-config.rsc

echo "add bridge=vlan1 interface=ether2-master-local" >>Orangebox$OB-initial-config.rsc

echo "add bridge=vlan2 interface=ether1-master-local" >>Orangebox$OB-initial-config.rsc

echo "add bridge=vlan-laptop_wireless interface=ether23-master-local" >>Orangebox$OB-initial-config.rsc

echo "add bridge=vlan-laptop_wireless interface=wlan3" >>Orangebox$OB-initial-config.rsc

echo "/ip settings" >>Orangebox$OB-initial-config.rsc

echo "set accept-redirects=yes" >>Orangebox$OB-initial-config.rsc

echo "/interface ethernet switch vlan" >>Orangebox$OB-initial-config.rsc

echo "add learn=no ports="ether2-master-local,node1-usb0,node2-usb0,node3-usb0,node4-usb0,node5-usb0,node6-usb0,node7-usb0,node8-usb0,node9-usb0,node10-usb0,switch1-cpu" vlan-id=2" >>Orangebox$OB-initial-config.rsc

echo "add learn=no ports=ether23-master-local,ether24-slave-local,switch1-cpu vlan-id=3" >>Orangebox$OB-initial-config.rsc

echo "add learn=no ports=sfp1-master-local,switch1-cpu vlan-id=4" >>Orangebox$OB-initial-config.rsc

echo "add learn=no ports="ether1-master-local,node1-eth0,node2-eth0,node3-eth0,node4-eth0,node5-eth0,node6-eth0,node7-eth0,node8-eth0,node9-eth0,node10-eth0,switch1-cpu" vlan-id=1" >>Orangebox$OB-initial-config.rsc

echo "/ip address" >>Orangebox$OB-initial-config.rsc

echo "add address=172.27.$PLUS1.254/23 interface=vlan1 network=172.27.$OB.0" >>Orangebox$OB-initial-config.rsc

echo "add address=172.27.$PLUS3.254/23 interface=vlan2 network=172.27.$PLUS2.0" >>Orangebox$OB-initial-config.rsc

echo "add address=172.27.252.$OB/22 interface=vlan-laptop_wireless network=172.27.252.0" >>Orangebox$OB-initial-config.rsc

echo "/ip dhcp-client" >>Orangebox$OB-initial-config.rsc

echo "add default-route-distance=0 dhcp-options=hostname,clientid disabled=no interface=sfp1-master-local" >>Orangebox$OB-initial-config.rsc

echo "/ip dhcp-server network" >>Orangebox$OB-initial-config.rsc

echo "add address=172.27.252.0/22 dns-server=172.27.252.$OB gateway=172.27.252.$OB netmask=22" >>Orangebox$OB-initial-config.rsc

echo "/ip dns" >>Orangebox$OB-initial-config.rsc

echo "set allow-remote-requests=yes servers=8.8.8.8" >>Orangebox$OB-initial-config.rsc

echo "/ip dns static" >>Orangebox$OB-initial-config.rsc

echo "add address=172.27.1.254 name=router" >>Orangebox$OB-initial-config.rsc

echo "/ip firewall filter" >>Orangebox$OB-initial-config.rsc

echo "/ip firewall nat" >>Orangebox$OB-initial-config.rsc

echo "add action=dst-nat chain=dstnat dst-port=2222 protocol=tcp to-addresses=172.27.$OB.1 to-ports=22" >>Orangebox$OB-initial-config.rsc

echo "add action=masquerade chain=srcnat comment=\"default configuration\" out-interface=sfp1-master-local" >>Orangebox$OB-initial-config.rsc

echo "/interface bridge port add bridge=vlan-laptop_wireless interface=wlan2" >>Orangebox$OB-initial-config.rsc

echo "/routing ospf interface" >>Orangebox$OB-initial-config.rsc

echo "add authentication=md5 authentication-key=protectorangebox authentication-key-id=2 cost=20 interface=sfp1-master-local network-type=broadcast priority=$OB" >>Orangebox$OB-initial-config.rsc

echo "add interface=vlan1 passive=yes" >>Orangebox$OB-initial-config.rsc

echo "add interface=vlan2 passive=yes" >>Orangebox$OB-initial-config.rsc

echo "add interface=vlan-laptop_wireless passive=yes" >>Orangebox$OB-initial-config.rsc

echo "/routing ospf network" >>Orangebox$OB-initial-config.rsc

echo "add area=backbone network=172.27.0.0/16" >>Orangebox$OB-initial-config.rsc

echo "add area=backbone network=192.168.0.0/16" >>Orangebox$OB-initial-config.rsc

echo "/system identity" >>Orangebox$OB-initial-config.rsc

echo "set name=OrangeBox$OB" >>Orangebox$OB-initial-config.rsc

echo "/system ntp client" >>Orangebox$OB-initial-config.rsc

echo "set enabled=yes primary-ntp=91.189.89.199 secondary-ntp=216.228.192.51" >>Orangebox$OB-initial-config.rsc
echo "/system backup save name=ob$OB-as-built" >>Orangebox$OB-initial-config.rsc
echo
echo "Config file built for OrangeBox$OB"
echo
echo "Checking network configuration..."
echo
until ping -c 1 192.168.88.1; do
    echo "Cannot reach 192.168.88.1, check network config, testing again in 5 seconds..."
    sleep 5
done
echo
echo "Uploading config file..."
echo
ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R 192.168.88.1
scp -o "StrictHostKeyChecking no" Orangebox$OB-initial-config.rsc admin@192.168.88.1:

echo "Config file uploaded."
echo
echo "Attempting to apply configuration..."
echo
ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R 192.168.88.1
ssh -o "StrictHostKeyChecking no" admin@192.168.88.1 /import Orangebox$OB-initial-config.rsc &
echo
echo "Finishing applying config, testing connectivity..."
echo
until ping -c 1 172.27.252.$OB; do
    echo "Cannot reach OrangeBox on 172.27.252.$OB...testing again in 5 seconds..."
    sleep 5
done

echo "Success"
echo
echo "Configuration finished, retrieving a configuration backup..."
echo
ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R 172.27.252.56
ssh-keygen -f "/root/.ssh/known_hosts" -R 172.27.252.56
scp -o "StrictHostKeyChecking no" admin@172.27.252.$OB:ob$OB-as-built.backup OB$OB-Initial-Configuration-Backup.backup
echo
echo "Removing temporary IP addresses"
ifdown $INT --force
echo "Complete"
echo "Exiting"

