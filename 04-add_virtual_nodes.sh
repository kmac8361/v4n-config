#!/bin/bash
trap 'echo Error at about $LINENO' ERR

# Source file to get OB number variable
. /etc/orange-box.conf

# Set network variables
internal_ip="172.27.${orangebox_number}.1"

# If user is not root then exit
if [ "$(id -u)" != "0" ]; then
  echo "Must be run with sudo or by root"
  exit 77
fi

set -e
set -aux

virsh net-info default && virsh net-destroy default && virsh net-undefine default

# If directory exist then change ownership
[ -d /var/lib/maas ] || install -d /var/lib/maas --owner maas --group maas

# Create the /srv/obvms directory for storing the virtual machines files
[ -d /srv/obvms ] || mkdir /srv/obvms
chown libvirt-qemu:kvm /srv/obvms
touch /srv/obvms/junk.img
rm /srv/obvms/*.img

# Change login shell to Bash for MAAS user
chsh maas -s /bin/bash

# If directory exist then make directory and change ownership
[ -d /var/lib/maas/.ssh ] || mkdir /var/lib/maas/.ssh && chown maas:maas /var/lib/maas/.ssh

# If file exist then echo 3 returns but do not output trailing newlines. Create SSH key for MAAS user with no passphrase of type RSA v2 at the specified location
[ -f /var/lib/maas/.ssh/id_rsa ] || echo -e "\n\n\n" | sudo -u maas ssh-keygen -N "" -t rsa -f /var/lib/maas/.ssh/id_rsa

# If file exist then gather known host keys of MAAS user for OB and append to the end of specified file while discarding output
[ -f /var/lib/maas/.ssh/known_hosts ] || sudo -u maas ssh-keyscan 172.27.${orangebox_number}.1 |sudo -u maas tee -a /var/lib/maas/.ssh/known_hosts > /dev/null

# Always add host keys .. not an issue if files grows
sudo -u maas ssh-keyscan 172.27.${orangebox_number}.1 |sudo -u maas  tee -a /var/lib/maas/.ssh/known_hosts > /dev/null

# if very first install ubuntu user might not have authorized keys set.
if [ ! -f /home/ubuntu/.ssh/authorized_keys ]; then
    mkdir -p /home/ubuntu/.ssh/
    cat /var/lib/maas/.ssh/id_rsa.pub | tee -a /home/ubuntu/.ssh/authorized_keys
    chown -R ubuntu /home/ubuntu/.ssh/
    chmod 700  /home/ubuntu/.ssh/
fi

sudo -u maas virsh -c qemu+ssh://ubuntu@172.27.${orangebox_number}.1/system list > /dev/null || sed -i '/ maas@/d' /home/ubuntu/.ssh/authorized_keys

# If there is no key /new install or just removed add it"
# echo -e "\n\n\n" | sudo -u maas ssh-keygen -N "" -t rsa -f /var/lib/maas/.ssh/id_rsa
grep 'maas@' /home/ubuntu/.ssh/authorized_keys || cat /var/lib/maas/.ssh/id_rsa.pub | tee -a /home/ubuntu/.ssh/authorized_keys
printf "%s,%s %s %s\n" "node0.maas" "$internal_ip" $(awk '{print $1 " " $2}' /etc/ssh/ssh_host_ecdsa_key.pub) | tee -a /var/lib/maas/.ssh/known_hosts

#Change ownership of specified directory
chown -R ubuntu:ubuntu /home/ubuntu

# Add virtual node tags in MAAS
maas admin tags create name=virtual || true

# Mark all nodes to be fast path installed
# Support MAAS 1.5, and 1.6
maas_ver=$(dpkg -l maas | tail -n1 | awk '{print $3}')
if dpkg --compare-versions $maas_ver lt 1.6; then
	maas admin tags create name='use-fastpath-installer' comment='fp' "definition=true()" || true
else
	maas admin tags create name='use-fastpath-installer' comment='fp' || true
fi

#Create zone0 for virtual nodes
maas admin zone read zone0 || maas admin zones create name=zone0 description="Virtual machines on node0"

for i in {0..2}; do
	hostname="node00vm${i}ob${orangebox_number}.maas"
	virsh destroy $hostname || true
	virsh undefine $hostname || true

        # Force remove of image files. This was necessary on recreate. Commenting out until more testing on this....
        #rm -f /srv/obvms/${hostname}-*.img

	echo "INFO: Installing virtual machine"
        if [ $i = 0 ]; then
	virt-install --debug --name $hostname --ram 8192 --disk=path=/srv/obvms/${hostname}-1.img,size=20 --disk=path=/srv/obvms/${hostname}-2.img,size=2 --vcpus=2 --os-type=linux --pxe --network=bridge=br0 --network=bridge=br1 --boot network --video=cirrus --graphics vnc|| true
        else
	virt-install --debug --name $hostname --ram 8192 --disk=path=/srv/obvms/${hostname}-1.img,size=20 --disk=path=/srv/obvms/${hostname}-2.img,size=2 --vcpus=2 --os-type=linux --pxe --network=bridge=br0 --network=bridge=br1 --boot network --video=cirrus --graphics vnc|| true
        fi
	virsh console $hostname || true
	virsh autostart $hostname
	mac=$(virsh dumpxml $hostname | python -c 'import sys, lxml.etree; print list(lxml.etree.parse(sys.stdin).iter("mac"))[0].get("address")')
	system_id=$(maas admin nodes read mac_address=$mac | grep system_id | cut -d'"' -f4 | sed -n 2p)

	if [ -n "$system_id" ]; then
		maas admin machine update $system_id hostname=$hostname power_type=virsh power_parameters_power_address=qemu+ssh://ubuntu@${internal_ip}/system power_parameters_power_id=$hostname
		maas admin tag update-nodes "virtual" add=$system_id
		maas admin machine commission $system_id || true
		maas admin nodes set-zone zone=zone0 nodes=$system_id
	else
		echo "ERROR: Could not find virtual machine in MAAS" 1>&2
		exit 1
	fi
done
