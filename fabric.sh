#!/bin/bash

ob_number=`hostname | cut -c 10- -`

vlanid=$(maas admin vlans read 2 |grep id |grep -v vid | awk -F, '{print $1}'|awk '{print $2}')
sub_net="172.27.`expr ${ob_number} + 2`.0/23"
#configure eth1 for fabric-1 and proper subnet
for nodenum in {01..10}
do
     system_id=$(maas admin nodes read hostname=node${nodenum}ob${ob_number} |grep system_id | cut -d'"' -f4)
     echo $system_id
     interface=$(maas admin nodes read hostname=node${nodenum}ob${ob_number} |grep enx |cut -d'"' -f4)
     echo $interface
     maas admin interface update $system_id $interface vlan=$vlanid
     maas admin interface link-subnet $system_id $interface mode=auto subnet="$sub_net"
done
