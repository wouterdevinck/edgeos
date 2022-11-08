#!/bin/sh

set -u
set -e

# Additional files
install -D -m 0644 ${BR2_EXTERNAL_EDGEOS_PATH}/board/edgeos/rpi4-boot/autoboot.txt ${BINARIES_DIR}/autoboot.txt
install -D -m 0644 ${BR2_EXTERNAL_EDGEOS_PATH}/board/edgeos/rpi4-boot/config.txt ${BINARIES_DIR}/config.txt
install -D -m 0644 ${BR2_EXTERNAL_EDGEOS_PATH}/board/edgeos/rpi4-boot/cmdline.txt ${BINARIES_DIR}/cmdline.txt

# Reduce size of initramfs
rm -rf ${TARGET_DIR}/lib/modules

# Remove unused overlays
find ${BINARIES_DIR}/rpi-firmware/overlays -type f -not -name 'miniuart-bt.dtbo' -delete