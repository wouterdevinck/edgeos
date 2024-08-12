#!/bin/sh
set -e

# Boot drive
PREFIX="/dev/sda"
DEV="$PREFIX"

# Enable efibootmgr
mount -t efivarfs efivarfs /sys/firmware/efi/efivars

# Check if both EdgeOS EFI boot entries are present
if [ $(efibootmgr | grep edgeos- | wc -l) -ne 2 ]; then

  # Delete all boot entries
  for i in $(efibootmgr | grep -E 'Boot[0-9]+' | grep -o -E 'Boot[0-9]+' | cut -c 5-); do
      efibootmgr -b $i -B -q
  done

  # Add both EdgeOS boot entries
  efibootmgr -q -C -b 1 -d "$DEV" -L "edgeos-a" -p 1 -l '\efi\boot\bootx64.efi'
  efibootmgr -q -C -b 2 -d "$DEV" -L "edgeos-b" -p 2 -l '\efi\boot\bootx64.efi'
  
  # Set the boot order
  efibootmgr -q -o 1,2

  # Set timeout to zero
  efibootmgr -q -t 0 

fi

# Currently booted from
BOOTPART=$(expr $(efibootmgr | grep BootCurrent | grep -o -E '[0-9]+') + 0)
SLOT=$BOOTPART
