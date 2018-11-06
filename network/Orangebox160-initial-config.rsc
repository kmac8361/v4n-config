/interface bridge
remove 0
add name=vlan1
add name=vlan2
add name=vlan-laptop_wireless
/interface wireless
set [ find default-name=wlan1 ] disabled=no mode=ap-bridge name=wlan3
/interface ethernet
set master-port=none 1,22,24
set [ find default-name=ether1 ] name=ether1-master-local
set [ find default-name=ether2 ] name=ether2-master-local
set [ find default-name=ether23 ] name=ether23-master-local
set [ find default-name=ether24 ] master-port=ether23-master-local name=ether24-slave-local
set [ find default-name=ether3 ] master-port=ether2-master-local name=node1-eth0
set [ find default-name=ether4 ] master-port=ether2-master-local name=node1-usb0
set [ find default-name=ether5 ] master-port=ether2-master-local name=node2-eth0
set [ find default-name=ether6 ] master-port=ether2-master-local name=node2-usb0
set [ find default-name=ether7 ] master-port=ether2-master-local name=node3-eth0
set [ find default-name=ether8 ] master-port=ether2-master-local name=node3-usb0
set [ find default-name=ether9 ] master-port=ether2-master-local name=node4-eth0
set [ find default-name=ether10 ] master-port=ether2-master-local name=node4-usb0
set [ find default-name=ether11 ] master-port=ether2-master-local name=node5-eth0
set [ find default-name=ether12 ] master-port=ether2-master-local name=node5-usb0
set [ find default-name=ether13 ] master-port=ether2-master-local name=node6-eth0
set [ find default-name=ether14 ] master-port=ether2-master-local name=node6-usb0
set [ find default-name=ether15 ] master-port=ether2-master-local name=node7-eth0
set [ find default-name=ether16 ] master-port=ether2-master-local name=node7-usb0
set [ find default-name=ether17 ] master-port=ether2-master-local name=node8-eth0
set [ find default-name=ether18 ] master-port=ether2-master-local name=node8-usb0
set [ find default-name=ether19 ] master-port=ether2-master-local name=node9-eth0
set [ find default-name=ether20 ] master-port=ether2-master-local name=node9-usb0
set [ find default-name=ether21 ] master-port=ether2-master-local name=node10-eth0
set [ find default-name=ether22 ] master-port=ether2-master-local name=node10-usb0
set [ find default-name=sfp1 ] name=sfp1-master-local
/ip neighbor discovery
set ether1-master-local discover=no
/interface wireless
add disabled=no mac-address=E6:8D:8C:B3:4B:43 master-interface=wlan3 name=wlan2 ssid=Canonical wds-default-bridge=vlan-laptop_wireless
set ssid=OrangeBox160 1
disable 0,1
/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa-psk,wpa2-psk mode=dynamic-keys supplicant-identity=MikroTik wpa-pre-shared-key=adroitreliable wpa2-pre-shared-key=adroitreliable
/ip ipsec proposal
set [ find default=yes ] enc-algorithms=aes-128-cbc
/ip pool
add name=vlan3-pool ranges=172.27.254.101-172.27.255.254
/ip dhcp-server
add address-pool=vlan3-pool disabled=no interface=vlan-laptop_wireless lease-time=12h name=dhcpserver-vlan3
/routing ospf instance
set [ find default=yes ] metric-bgp=75 metric-connected=50 redistribute-bgp=as-type-1 redistribute-connected=as-type-1 router-id=172.27.252.160
/interface bridge port
remove 0,1
add bridge=vlan1 interface=ether2-master-local
add bridge=vlan2 interface=ether1-master-local
add bridge=vlan-laptop_wireless interface=ether23-master-local
add bridge=vlan-laptop_wireless interface=wlan3
/ip settings
set accept-redirects=yes
/interface ethernet switch vlan
add learn=no ports=ether2-master-local,node1-usb0,node2-usb0,node3-usb0,node4-usb0,node5-usb0,node6-usb0,node7-usb0,node8-usb0,node9-usb0,node10-usb0,switch1-cpu vlan-id=2
add learn=no ports=ether23-master-local,ether24-slave-local,switch1-cpu vlan-id=3
add learn=no ports=sfp1-master-local,switch1-cpu vlan-id=4
add learn=no ports=ether1-master-local,node1-eth0,node2-eth0,node3-eth0,node4-eth0,node5-eth0,node6-eth0,node7-eth0,node8-eth0,node9-eth0,node10-eth0,switch1-cpu vlan-id=1
/ip address
add address=172.27.161.254/23 interface=vlan1 network=172.27.160.0
add address=172.27.163.254/23 interface=vlan2 network=172.27.162.0
add address=172.27.252.160/22 interface=vlan-laptop_wireless network=172.27.252.0
/ip dhcp-client
add default-route-distance=0 dhcp-options=hostname,clientid disabled=no interface=sfp1-master-local
/ip dhcp-server network
add address=172.27.252.0/22 dns-server=172.27.252.160 gateway=172.27.252.160 netmask=22
/ip dns
set allow-remote-requests=yes servers=8.8.8.8
/ip dns static
add address=172.27.1.254 name=router
/ip firewall filter
/ip firewall nat
add action=dst-nat chain=dstnat dst-port=2222 protocol=tcp to-addresses=172.27.160.1 to-ports=22
add action=masquerade chain=srcnat comment="default configuration" out-interface=sfp1-master-local
/interface bridge port add bridge=vlan-laptop_wireless interface=wlan2
/routing ospf interface
add authentication=md5 authentication-key=protectorangebox authentication-key-id=2 cost=20 interface=sfp1-master-local network-type=broadcast priority=160
add interface=vlan1 passive=yes
add interface=vlan2 passive=yes
add interface=vlan-laptop_wireless passive=yes
/routing ospf network
add area=backbone network=172.27.0.0/16
add area=backbone network=192.168.0.0/16
/system identity
set name=OrangeBox160
/system ntp client
set enabled=yes primary-ntp=91.189.89.199 secondary-ntp=216.228.192.51
/system backup save name=ob160-as-built
