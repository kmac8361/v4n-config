#!/bin/bash
#
set -e
set -x

usage()
{
cat << EOF
usage: $0 options

This script to select desired repository and install packages

OPTIONS:
   -h      Show this message
   -p      Manually enter in ppa's name (as in ppa:/juju/stable)
EOF
}

# If user is not root then exit
if [ "$(id -u)" != "0" ]; then
  echo "Must be run with sudo or by root"
  exit 77
fi

get_orangebox_number() {
obnum=`hostname | cut -c 10- -`
echo $obnum
echo "orangebox_number=$obnum" > /etc/orange-box.conf
}


# Install the extra packages needed for the desktop and configuration of the OrangeBox
#
install_packages (){
    packages=
    while read package; do
        package=${package%%#*}
        packages="$packages $package"
    done < PACKAGES.list
    apt install -y $packages
}

# Setup the ppa's for what respositories will be used to install the correct packages with respect to MAAS and Juju
#
set_up_ppas(){
apt-get update -y
apt-get dist-upgrade -y
apt-get install run-one -y
install_packages
sleep 5
reboot
}

if (($# == 0)); then
  set_up_ppas default
fi

# Section to decide which options to use
#
while getopts “hp” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         p)
             set_up_ppas ppaset
             ;;
         ?)
             usage
             exit
             ;;
        \?)
             echo "Invalid option: -$OPTARG" >&2
             ;;
     esac
done
