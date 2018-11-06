#!/bin/bash

set -e
set -x

#Get ob number
ob_number=`hostname | cut -c 10- -`

router_ip=172.27.${ob_number}.1
#set apikey variable
apikey=`sudo maas-region apikey --username admin | tail -n1`

setup_juju() {
        mkdir -p /home/ubuntu/.juju
        cat >/home/ubuntu/.juju/environments.yaml <<EOF
default: maas
environments:
    maas:
        type: maas
        maas-server: 'http://${router_ip}/MAAS/'
        maas-oauth: '$apikey'
        default-series: trusty
        #enable-os-upgrade: false
        authorized-keys-path: /home/ubuntu/.ssh/id_rsa.pub
        admin-secret: 'admin'
        logging-config: '<root>=DEBUG'
        lxc-clone: true
EOF
        rm -rf /home/ubuntu/.juju-plugins
        git clone https://github.com/juju/plugins /home/ubuntu/.juju-plugins

        # Change ownership recusrively of specified directory
#        sudo chown -R ubuntu:ubuntu /home/ubuntu/

        echo "PATH=\$PATH:/home/ubuntu/.juju-plugins:/home/ubuntu/Examples/bin" >> /home/ubuntu/.bashrc
        echo "export JUJU_DEV_FEATURE_FLAGS=maas2" >> /home/ubuntu/.bashrc
}

setup_landscape() {
        # The master node will be managed by Landscape
        if which landscape-config; then
                case "$(hostname)" in
                        OrangeBox*|orangebox*)
                                sudo landscape-config -a cpe-sa -t "$(hostname)__$(dmidecode -s baseboard-serial-number)" --script-users=ALL --silent --include-manager-plugins=ScriptExecution || true
                        ;;
                esac
        fi
}

setup_desktop() {
        # connect running session bus if any
        dbus_session_bus_address=$(pgrep -u "$USER" -af 'dbus-daemon --fork --session' | grep -o 'unix:.*' || true)
        if [ -n "$dbus_session_bus_address" ]; then
            env DBUS_SESSION_BUS_ADDRESS="$dbus_session_bus_address" \
                dconf load / < template/dconf.txt
        else
            dbus-launch dconf load / < template/dconf.txt
        fi

        # Disable Ubuntu crash reporter
        echo "enabled=0" |sudo tee /etc/default/apport

        # Stop Ubuntu crash reporter
        sudo invoke-rc.d apport stop || true
}

setup_remmina() {
        if [[ -d /home/ubuntu/.remmina ]]
	then
		echo "Remmina already setup"
	else
		echo "Setting up Remmina..."
		mkdir /home/ubuntu/.remmina
        	for nodenum in {1..10}
        	do
             		cat >/home/ubuntu/.remmina/node${nodenum}.remmina <<EOF
[remmina]
keymap=
ssh_auth=0
quality=0
disableencryption=0
ssh_charset=
ssh_privatekey=
server=172.27.${ob_number}.`expr ${nodenum} + 10`
hscale=0
group=
password=Ubuntu1+
name=node${nodenum}
ssh_loopback=0
viewonly=0
ssh_username=
ssh_server=
window_maximize=0
aspectscale=0
protocol=VNC
window_height=825
window_width=963
vscale=0
ssh_enabled=0
username=admin
showcursor=0
disableserverinput=0
colordepth=8
disableclipboard=0
viewmode=1             
EOF
		done
		chown -R ubuntu:ubuntu /home/ubuntu/.remmina
	fi
}

setup_juju
setup_landscape
setup_desktop
setup_remmina
/srv/obinstall/import_SA_keys.sh
if [[ -d /srv/sademos-15.10 ]]
then
	cd /srv/sademos-15.10; bzr pull
else
	bzr branch lp:sademos /srv/sademos-15.10
fi
if [[ -d /srv/sademos-16.04 ]]
then
	cd /srv/sademos-16.04; bzr pull
else
	bzr branch lp:sademos/16.04 /srv/sademos-16.04
fi
ln -s /srv/sademos-16.04 /home/ubuntu/sademos-juju2
ln -s /srv/sademos-15.10 /home/ubuntu/sademos-juju1.25
