#!/bin/bash
# script to configure apache
#
set -e
set -x


# If user is not root then exit
#
if [ "$(id -u)" != "0" ]; then
  echo "Must be run with sudo or by root"
  exit 77
fi

# This sets up Apache so that when going to the OB IP address of Node0, the user is automatically put
# into the MAAS login/interface and they don't have to place /MAAS at the end of the system-name or IP address
#
setup_apache() {
        mkdir -p /srv/mirrors/archive.ubuntu.com
        echo '<meta http-equiv="refresh" content="0; url=MAAS/">' > /srv/mirrors/archive.ubuntu.com/index.html
        invoke-rc.d apache2 stop || true
        invoke-rc.d apache2 start
}

setup_apache
