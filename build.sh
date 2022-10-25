#!/bin/bash
set -e

CONFIG=edgeos_defconfig
BR_VERSION=2022.08.1

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
WORKDIR="$SCRIPT_DIR/buildroot"
EXTDIR="$SCRIPT_DIR/external"
OUTDIR="$SCRIPT_DIR/output"

CONFPATH="$EXTDIR/configs/$CONFIG"
IMGPATH="$OUTDIR/images/sdcard.img"

function printUsage {
  echo "Usage: $0 prepare|menuconfig|build|flash|clean"
  echo ""
  echo "   prepare    - Download buildroot and unpack into working directory."
  echo "   menuconfig - Run the menuconfig utility."
  echo "   build      - Build the image."
  echo "   flash      - Write the image to the SD card."
  echo "   clean      - Clean up."
  echo ""
}

case $1 in

"prepare")
  rm -rf $WORKDIR
  mkdir -p $WORKDIR
  wget "https://buildroot.org/downloads/buildroot-$BR_VERSION.tar.gz"
  tar -xzf buildroot-$BR_VERSION.tar.gz -C $WORKDIR --strip-components 1
  rm buildroot-$BR_VERSION.tar.gz
  ;;

"build"|"menuconfig")
  if [ ! -d "$WORKDIR" ]; then
    printf "\nPlease run prepare first.\n\n"
    exit 2
  fi
  cd $WORKDIR
  ;;&

"menuconfig")
  make O=$OUTDIR BR2_DEFCONFIG=$CONFPATH  defconfig
  make O=$OUTDIR BR2_EXTERNAL=$EXTDIR     menuconfig
  make O=$OUTDIR BR2_DEFCONFIG=$CONFPATH  savedefconfig
  ;;

"build")
  make O=$OUTDIR BR2_EXTERNAL=$EXTDIR $CONFIG
  make O=$OUTDIR
  ls -lh $IMGPATH
  ;;

"flash")
  dd if=$IMGPATH of=/dev/mmcblk0 bs=1024 status=progress
  sync
  ;;

"clean")
  rm -rf $WORKDIR $OUTDIR
  ;;

*)
  printUsage
  ;;

esac
