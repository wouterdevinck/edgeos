#!/bin/sh
set -e

# Wait for the SSD or SD card to be available by searching for
# the AUTOBOOT label on the first FAT partition.
for i in $(seq 20); do
  AUTOBOOTDEV="$(findfs LABEL=AUTOBOOT 2> /dev/null || true)"
  if [ -b "$AUTOBOOTDEV" ]; then
    break
  fi
  sleep 1
done

# Deduce the name of the boot device, e.g. /dev/sda for
# an SSD, or /dev/mmcblk0(p) for an SD card.
PREFIX=$(echo $AUTOBOOTDEV | sed 's/.$//')
DEV=$(echo $PREFIX | sed 's/p$//')

# Find out from the EEPROM bootloader whether we are booted
# from BOOT_A (FAT partition 2) or from BOOT_B (FAT partition 3).
DT_BOOTLOADER_PARTITION=/proc/device-tree/chosen/bootloader/partition
BOOTPART=$(printf "%d" "0x$(od "${DT_BOOTLOADER_PARTITION}" -v -An -t x1 | tr -d ' ' )")
SLOT=$((BOOTPART-1))

# Check & repair file systems.
fsck -p $AUTOBOOTDEV > /dev/null 2>&1 || true

# Mount the AUTOBOOT FAT file system. We need to write to this during upgrade.
if ! mount $AUTOBOOTDEV /mnt/boot/autoboot; then
  echo "Failed to mount AUTOBOOT"
  exit 2
fi
