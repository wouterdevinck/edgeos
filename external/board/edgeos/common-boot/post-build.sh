#!/bin/sh

set -u
set -e

# Version number
install -D -m 0644 edgeos-version ${BINARIES_DIR}/edgeos-version   # On FAT partition, see genimage
install -D -m 0644 edgeos-version ${TARGET_DIR}/etc/edgeos-version # In CPIO initramfs file

# Create archive of kernel modules, to later be added to the rootfs
if [ -d "${TARGET_DIR}/lib/modules" ]; then
    tar -czvf ${BINARIES_DIR}/modules.tar.gz -C ${TARGET_DIR}/lib/modules . > /dev/null 2>&1
fi