#!/bin/bash -e

#mkdir -p /srv/data

# Keep Two Different Image Formats for At Least On Release: QCOW to be used with KVM/QEMU and RAW to be used with LXD!
folder=/srv/data
URLS="http://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img \
http://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-root.tar.gz \
http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img \
http://mirror.catn.com/pub/catn/images/qcow2/centos6.4-x86_64-gold-master.img \
http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img "

for URL in $URLS
do
FILENAME=${URL##*/}
if [ -f $folder/$FILENAME ];
then
    echo "$FILENAME already downloaded." 
else
    wget -q -O  $folder/$FILENAME $URL
fi
done

