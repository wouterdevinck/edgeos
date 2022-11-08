#!/bin/bash
set -e

BR_VERSION=2022.08.1

CONFIG_RPI4_TOOLCHAIN=edgeos_rpi4_toolchain_defconfig
CONFIG_RPI4_BOOT=edgeos_rpi4_boot_defconfig
CONFIG_RPI4_ROOT=edgeos_rpi4_root_defconfig

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
WORKDIR="$SCRIPT_DIR/buildroot"
EXTDIR="$SCRIPT_DIR/external"
PATCHDIR="$SCRIPT_DIR/patches"
OUTDIR="$SCRIPT_DIR/output"

CONFPATH_RPI4_TOOLCHAIN="$EXTDIR/configs/$CONFIG_RPI4_TOOLCHAIN"
CONFPATH_RPI4_BOOT="$EXTDIR/configs/$CONFIG_RPI4_BOOT"
CONFPATH_RPI4_ROOT="$EXTDIR/configs/$CONFIG_RPI4_ROOT"

OUTDIR_RPI4_TOOLCHAIN="$OUTDIR/rpi4-toolchain"
OUTDIR_RPI4_BOOT="$OUTDIR/rpi4-boot"
OUTDIR_RPI4_ROOT="$OUTDIR/rpi4-root"

menuconfig () {
  make O=$1 BR2_DEFCONFIG=$2 defconfig
  make O=$1 BR2_EXTERNAL=$EXTDIR menuconfig
  make O=$1 BR2_DEFCONFIG=$2 savedefconfig
}

build () {
  make O=$1 BR2_EXTERNAL=$EXTDIR $2
  make O=$1 $3
}

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

"build"|"toolchain"|"menuconfig-rpi4-toolchain"|"menuconfig-rpi4-boot"|"menuconfig-rpi4-root")
  if [ ! -d "$WORKDIR" ]; then
    printf "\nPlease run prepare first.\n\n"
    exit 2
  fi
  cd $WORKDIR
  ;;&

"menuconfig-rpi4-toolchain")
  menuconfig $OUTDIR_RPI4_TOOLCHAIN $CONFPATH_RPI4_TOOLCHAIN
  ;;

"menuconfig-rpi4-boot")
  menuconfig $OUTDIR_RPI4_BOOT $CONFPATH_RPI4_BOOT
  ;;

"menuconfig-rpi4-root")
  menuconfig $OUTDIR_RPI4_ROOT $CONFPATH_RPI4_ROOT
  ;;

"toolchain")
  build $OUTDIR_RPI4_TOOLCHAIN $CONFPATH_RPI4_TOOLCHAIN sdk
  ;;

"build")

  # Build FAT boot partition - containing firmware (& config), kernel and initramfs
  build $OUTDIR_RPI4_BOOT $CONFIG_RPI4_BOOT

  # Build rootfs
  build $OUTDIR_RPI4_ROOT $CONFIG_RPI4_ROOT

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
