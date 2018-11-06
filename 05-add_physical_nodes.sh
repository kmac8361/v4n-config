#!/bin/bash
set -aux

# If user is not root then exit
if [ "$(id -u)" != "0" ]; then
  echo "Must be run with sudo or by root"
  exit 77
fi

# Get ob number
#
ob_number=`hostname | cut -c 10- -`

# Ensure the MAAS URL and CLUSTER UUID are set correctly
MAAS_URL=http://172.27.${ob_number}.1/MAAS

# set apikey variable
apikey=`maas-region apikey --username admin | tail -n1`

# login to MAAS
maas login admin $MAAS_URL $apikey

# Add nodes to MAAS by accessing their amt interfaces
for amtnum in {11..20}
do
ping -c 2 172.27.${ob_number}.${amtnum}

# Get mac address for the corresponding amt ip address
mac=`arp -n | grep 172.27.${ob_number}.$amtnum |awk '{print $3}'`
echo "$mac belongs to v4n-node${amtnum}ob${ob_number} with ip 172.27.${ob_number}.${amtnum}"

# Get the node number for the name out of the amt ip address
nodenum=`expr ${amtnum} - 10`
if [ ${nodenum} -lt 10 ]; then
     nodenum="0${nodenum}"
fi
echo "The name of the node is v4n-node${nodenum}ob${ob_number}"

# Add each node to MAAS and commission it
maas admin machines create architecture=amd64 power_type=amt power_parameters_power_address=172.27.${ob_number}.${amtnum} power_parameters_power_pass=Password1+ mac_addresses=${mac} hostname=v4n-node${nodenum}ob${ob_number}

#Add tags to MAAS if not already there
maas admin tags create name=physical || true
maas admin tags create name=use-fastpath-installer || true

#Get the system id of each node
system_id=$(maas admin nodes read mac_address=$mac | grep system_id | head -n 1 | cut -d'"' -f4)
echo $system_id

#Assign tags to each node
maas admin tag update-nodes "physical" add=$system_id
maas admin tag update-nodes "use-fastpath-installer" add=$system_id

#Determine which zone a node will be in
if [ ${nodenum} -lt 6 ]; then
                zone="zone1"
        else
                zone="zone2"
fi
zone="V4N-Zone"
echo "Node v4n-node${nodenum}ob${ob_number} is in $zone"

#Add the nodes to their respective zone
maas admin nodes set-zone zone=$zone nodes=$system_id

done
