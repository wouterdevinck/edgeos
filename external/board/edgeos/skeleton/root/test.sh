#/bin/sh

A_PART="mmcblk0p5"
B_PART="mmcblk0p6"

BOOTPART=$(eval $(lsblk -o MOUNTPOINT,NAME -P | grep 'MOUNTPOINT="/"'); echo $NAME)

if [ $BOOTPART = $A_PART ]
then
  echo "Booted from A"
elif [ $BOOTPART = $B_PART ]
then
  echo "Booted from B"
else
  echo "ERROR"
fi