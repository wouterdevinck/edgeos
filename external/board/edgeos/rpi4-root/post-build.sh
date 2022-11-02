#!/bin/sh

set -u
set -e

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
fi

# Mount FAT partitions
if [ -e ${TARGET_DIR}/etc/fstab ]; then
    mkdir -p ${TARGET_DIR}/boot/autoboot
    grep -qE '/dev/mmcblk0p1' ${TARGET_DIR}/etc/fstab || echo "/dev/mmcblk0p1 /boot/autoboot vfat defaults,noatime 0 0" >> ${TARGET_DIR}/etc/fstab
    mkdir -p ${TARGET_DIR}/boot/boot_a
    grep -qE '/dev/mmcblk0p2' ${TARGET_DIR}/etc/fstab || echo "/dev/mmcblk0p2 /boot/boot_a vfat defaults,noatime 0 0" >> ${TARGET_DIR}/etc/fstab
    mkdir -p ${TARGET_DIR}/boot/boot_b
    grep -qE '/dev/mmcblk0p3' ${TARGET_DIR}/etc/fstab || echo "/dev/mmcblk0p3 /boot/boot_b vfat defaults,noatime 0 0" >> ${TARGET_DIR}/etc/fstab
fi