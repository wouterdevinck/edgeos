#!/bin/bash
set -e

BR_VERSION=2022.08.1

CONFIG_RPI4_BOOT=edgeos_rpi4_boot_defconfig
CONFIG_RPI4_ROOT=edgeos_rpi4_root_defconfig

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
WORKDIR="$SCRIPT_DIR/buildroot"
EXTDIR="$SCRIPT_DIR/external"
PATCHDIR="$SCRIPT_DIR/patches"
OUTDIR="$SCRIPT_DIR/output"

CONFPATH_RPI4_BOOT="$EXTDIR/configs/$CONFIG_RPI4_BOOT"
CONFPATH_RPI4_ROOT="$EXTDIR/configs/$CONFIG_RPI4_ROOT"

OUTDIR_RPI4_BOOT="$OUTDIR/rpi4-boot"
OUTDIR_RPI4_ROOT="$OUTDIR/rpi4-root"

case $1 in

"prepare")

  # Create directory for Buildroot
  rm -rf $WORKDIR
  mkdir -p $WORKDIR

  # Download and unpack Buildroot
  wget "https://buildroot.org/downloads/buildroot-$BR_VERSION.tar.gz"
  tar -xzf buildroot-$BR_VERSION.tar.gz -C $WORKDIR --strip-components 1
  rm buildroot-$BR_VERSION.tar.gz

  # Apply pathes to Buildroot
  for patch in $PATCHDIR/*; do
    patch -d $WORKDIR -p0 < $patch
  done

  ;;

"build"|"menuconfig-rpi4-boot"|"menuconfig-rpi4-root")
  if [ ! -d "$WORKDIR" ]; then
    printf "\nPlease run prepare first.\n\n"
    exit 2
  fi
  cd $WORKDIR
  ;;&

"menuconfig-rpi4-boot")
  make O=$OUTDIR_RPI4_BOOT BR2_DEFCONFIG=$CONFPATH_RPI4_BOOT defconfig
  make O=$OUTDIR_RPI4_BOOT BR2_EXTERNAL=$EXTDIR menuconfig
  make O=$OUTDIR_RPI4_BOOT BR2_DEFCONFIG=$CONFPATH_RPI4_BOOT savedefconfig
  ;;

"menuconfig-rpi4-root")
  make O=$OUTDIR_RPI4_ROOT BR2_DEFCONFIG=$CONFPATH_RPI4_ROOT defconfig
  make O=$OUTDIR_RPI4_ROOT BR2_EXTERNAL=$EXTDIR menuconfig
  make O=$OUTDIR_RPI4_ROOT BR2_DEFCONFIG=$CONFPATH_RPI4_ROOT savedefconfig
  ;;

"build")

  # Build FAT boot partition - containing firmware (& config), kernel and initramfs
  make O=$OUTDIR_RPI4_BOOT BR2_EXTERNAL=$EXTDIR $CONFIG_RPI4_BOOT
  make O=$OUTDIR_RPI4_BOOT

  # Build rootfs
  make O=$OUTDIR_RPI4_ROOT BR2_EXTERNAL=$EXTDIR $CONFIG_RPI4_ROOT
  make O=$OUTDIR_RPI4_ROOT

  # Copy artifacts
  cp $OUTDIR_RPI4_BOOT/images/autoboot.vfat $OUTDIR
  cp $OUTDIR_RPI4_BOOT/images/boot.vfat $OUTDIR
  cp $OUTDIR_RPI4_ROOT/images/rootfs.ext4 $OUTDIR
  cd $OUTDIR

  # Tar artifacts
  tar -czvf edgeos.tar.gz autoboot.vfat boot.vfat rootfs.ext4

  # Build SD card image
  PATH=$PATH:$OUTDIR_RPI4_ROOT/host/bin BUILD_DIR=$OUTDIR fakeroot $WORKDIR/support/scripts/genimage.sh -c $EXTDIR/board/edgeos/rpi4-sdcard-genimage.cfg

  ;;

"clean")
  rm -rf $WORKDIR $OUTDIR
  ;;

*)
  echo "Unknown command"
  ;;

esac
