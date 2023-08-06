#!/bin/sh

set -u
set -e

# Version number
install -D -m 0644 edgeos-version ${TARGET_DIR}/etc/edgeos-version

# Add kernel modules
BOOT_BINARIES_DIR=$(echo $BINARIES_DIR | sed 's/rpi4-root/rpi4-boot/g')
mkdir -p ${TARGET_DIR}/lib/modules
tar -xf ${BOOT_BINARIES_DIR}/modules.tar.gz -C ${TARGET_DIR}/lib/modules