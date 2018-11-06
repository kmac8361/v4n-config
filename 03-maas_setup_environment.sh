#!/bin/bash
#
set -ax
# If user is not root then exit
if [ "$(id -u)" != "0" ]; then
  echo "Must be run with sudo or by root"
  exit 77
fi

#Get ob number
ob_number=`hostname | cut -c 10- -`

# Set the MAAS URL and CLUSTER_UUID for the admin login setup
MAAS_URL=http://172.27.${ob_number}.1/MAAS
CLUSTER_UUID=`grep cluster_uuid /etc/maas/rackd.conf |awk '{print $2}'`

#Set ip's for MAAS configuration
dhcp_low=172.27.`expr ${ob_number} + 1`.1
dhcp_high=172.27.`expr ${ob_number} + 1`.20
dns_ip=172.27.`expr ${ob_number} + 1`.254
sub_net="172.27.${ob_number}.0/23"
gateway_ip="172.27.${ob_number}.1"
dns_servers="172.27.${ob_number}.1"

#Create the MAAS credentials
if [[ $(maas-region apikey --username admin 1>/dev/null 2>&1;echo $?) -eq 1 ]]
then
	maas-region createadmin --username admin --email maas-admin@example.com --password="admin" || true
fi

#get apikey variable
apikey=`maas-region apikey --username admin | tail -n1`

#login to MAAS
maas login admin $MAAS_URL $apikey

#Add ssh key to MAAS
maas admin sshkeys create key="$(cat /home/ubuntu/.ssh/id_rsa.pub)" || true

#update VLAN info to switch on DHCP
maas admin ipranges create type=dynamic start_ip=${dhcp_low} end_ip=${dhcp_high}
maas admin subnets read|grep "\"id\""|awk '{print $2}'|sed 's/,//'|egrep -x '.{1,2}'|while read subnet_id
do
	maas admin subnet read $subnet_id|grep "\"cidr\": \"${sub_net}\"" 1>/dev/null
	if [[ $? -eq 0 ]]
	then
       		maas_fabric=$(maas admin subnet read ${subnet_id}|grep fabric|awk '{print $2}'|sed 's/,//'|sed 's/\"//g')
		maas admin vlan update ${maas_fabric} untagged dhcp_on=True primary_rack="OrangeBox${ob_number}"
	fi
done
maas admin subnet update ${sub_net} gateway_ip=${gateway_ip} dns_servers=${dns_servers}

#update http conf
cat >/var/www/html/index.html <<EOF
<meta http-equiv="refresh" content="0; url=/MAAS">
EOF

#update DNS info
maas admin maas set-config name=upstream_dns value=$dns_ip
maas admin maas set-config name=dnssec_validation value=no
maas admin maas set-config name=kernel_opts value="net.ifnames=0"
sed -e 's/dnssec-validation  auto;/dnssec-enable no;dnssec-validation no;/g' -i /etc/bind/named.conf.options
pkill -HUP named

#Import boot images
maas admin boot-source-selections create 1 os="ubuntu" release="xenial" arches="amd64" subarches="*" labels="*" || true
maas admin boot-source-selections create 1 os="ubuntu" release="trusty" arches="amd64" subarches="*" labels="*" || true
maas admin boot-resources import
while [ $(maas admin boot-resources read name=$CLUSTER_UUID | wc -l) -lt 10 ]; do
echo " Waiting for images to download"
   sleep 10
done
sleep 5

#Add zones to MAAS for NUC's
maas admin zone read zone1 || maas admin zones create name=zone1 description="Physical machines 1-5"
maas admin zone read zone2 || maas admin zones create name=zone2 description="Physical machines 6-10"
