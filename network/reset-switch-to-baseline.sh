#!/bin/bash

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

#Restore baseline backup
echo "Restoring baseline backup for OrangeBox$OB...switch will reboot..."
#
ssh -o "StrictHostKeyChecking no" admin@172.27.$PLUS1.254 /system backup load name=ob$OB-as-built.backup password=\n

echo "Trying to reconnect to OrangeBox$OB..."
echo
until ping -c 1 172.27.$PLUS1.254; do
    echo "Cannot reach 172.27.$PLUS1.254, testing again in 5 seconds..."
    sleep 5
done

echo "Complete, exiting..."
