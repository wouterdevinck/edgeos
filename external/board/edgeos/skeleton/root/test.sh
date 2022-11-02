#/bin/sh

A_PART="mmcblk0p5"
B_PART="mmcblk0p6"

ROOTFSPART=$(eval $(lsblk -o MOUNTPOINT,NAME -P | grep 'MOUNTPOINT="/"'); echo $NAME)

if [ $ROOTFSPART = $A_PART ]
then
  echo "Booted from A"
elif [ $ROOTFSPART = $B_PART ]
then
  echo "Booted from B"
else
  echo "ERROR"
fi

DT_BOOTLOADER_TRYBOOT=/proc/device-tree/chosen/bootloader/tryboot
DT_BOOTLOADER_PARTITION=/proc/device-tree/chosen/bootloader/partition

TRYBOOT=$(printf "%d" "0x$(od "${DT_BOOTLOADER_TRYBOOT}" -v -An -t x1 | tr -d ' ' )")
BOOTPART=$(printf "%d" "0x$(od "${DT_BOOTLOADER_PARTITION}" -v -An -t x1 | tr -d ' ' )")

echo "TRYBOOT = $TRYBOOT, BOOTPART = $BOOTPART, ROOTFSPART = $ROOTFSPART"