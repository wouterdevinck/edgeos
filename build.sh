#!/bin/bash
set -e

BR_VERSION=2024.02

CONFIG_RPI4_TOOLCHAIN=edgeos_rpi4_toolchain_defconfig
CONFIG_RPI4_BOOT=edgeos_rpi4_boot_defconfig
CONFIG_RPI4_ROOT=edgeos_rpi4_root_defconfig

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
WORKDIR="$SCRIPT_DIR/buildroot"
EXTDIR="$SCRIPT_DIR/external"
PATCHDIR="$SCRIPT_DIR/patches"
OUTDIR="$SCRIPT_DIR/output"
EXAMPLEDIR="$SCRIPT_DIR/bundler/example"
ARTDIR="$OUTDIR/artifacts"

export EDGEOS_VERSION=$(git describe --tags --dirty)

DOCKERFILE_OS="$SCRIPT_DIR/docker/Dockerfile-edgeos"
DOCKERFILE_BUNDLER="$SCRIPT_DIR/docker/Dockerfile-bundler"

DOCKER_TAG_OS="wouterdevinck/edgeos:$EDGEOS_VERSION"
DOCKER_TAG_BUNDLER="wouterdevinck/edgeos-bundler:$EDGEOS_VERSION"

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

menuconfiglinux () {
  make O=$1 BR2_EXTERNAL=$EXTDIR linux-menuconfig
}

menuconfigbusybox () {
  make O=$1 BR2_EXTERNAL=$EXTDIR busybox-menuconfig
}

build () {
  make O=$1 BR2_EXTERNAL=$EXTDIR $2
  GOWORK=off make O=$1 $3
}

case $1 in

"version")
  echo $EDGEOS_VERSION
  ;;

"prepare")

  # Create directory for Buildroot
  rm -rf $WORKDIR
  mkdir -p $WORKDIR

  # Download and unpack Buildroot
  wget "https://buildroot.org/downloads/buildroot-$BR_VERSION.tar.gz"
  tar -xzf buildroot-$BR_VERSION.tar.gz -C $WORKDIR --strip-components 1
  rm buildroot-$BR_VERSION.tar.gz

  # Apply patches to Buildroot
  if [ "$(ls $PATCHDIR)" ]; then
    for patch in $PATCHDIR/*.patch; do
      patch -d $WORKDIR -p0 < $patch
    done
  fi

  ;;

"build"|"toolchain"|"menuconfig-rpi4-toolchain"|"menuconfig-rpi4-boot"|"menuconfig-rpi4-root"|"menuconfig-rpi4-linux"|"menuconfig-rpi4-busybox")
  if [ ! -d "$WORKDIR" ]; then
    printf "\nPlease run prepare first.\n\n"
    exit 2
  fi
  cd $WORKDIR
  
  # If running under WSL, locally fix the path. Buildroot doesn't like spaces on the path.
  if [[ $(grep -i Microsoft /proc/version) ]]; then 
    PATH=$(echo $PATH | tr ':' '\n' | grep -v /mnt/ | tr '\n' ':' | head -c -1)
  fi
  
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

"menuconfig-rpi4-linux")
  menuconfiglinux $OUTDIR_RPI4_BOOT
  ;;
  
"menuconfig-rpi4-busybox")
  menuconfigbusybox $OUTDIR_RPI4_ROOT
  ;;

"toolchain")
  build $OUTDIR_RPI4_TOOLCHAIN $CONFIG_RPI4_TOOLCHAIN sdk
  ;;

"build")

  echo "Building EdgeOS version $EDGEOS_VERSION"

  # Write version number to file
  echo "$EDGEOS_VERSION" > $WORKDIR/edgeos-version

  # Build FAT boot partition - containing firmware (& config), kernel and initramfs
  build $OUTDIR_RPI4_BOOT $CONFIG_RPI4_BOOT

  # Build rootfs
  build $OUTDIR_RPI4_ROOT $CONFIG_RPI4_ROOT

  # Copy artifacts
  rm -rf $ARTDIR
  mkdir $ARTDIR
  cp $OUTDIR_RPI4_BOOT/images/autoboot.vfat $ARTDIR
  cp $OUTDIR_RPI4_BOOT/images/boot.vfat $ARTDIR
  cp $OUTDIR_RPI4_ROOT/images/rootfs.squashfs $ARTDIR
  cd $ARTDIR

  # Tar artifacts
  tar -czf edgeos.tar.gz autoboot.vfat boot.vfat rootfs.squashfs

  # Build Docker images
  docker buildx build --load -t $DOCKER_TAG_OS -f $DOCKERFILE_OS $ARTDIR

  ;;&

"build"|"bundler")

  # Build bundler Docker image
  docker buildx build --load -t $DOCKER_TAG_BUNDLER -f $DOCKERFILE_BUNDLER --build-arg BUNDLER_VERSION=$EDGEOS_VERSION $SCRIPT_DIR

  ;;

"bundle")

  # Run bundler on example

  BUNDLER_ARGS="-v $EXAMPLEDIR:/workdir -v /var/run/docker.sock:/var/run/docker.sock -u $(id -u $USER):$(getent group docker | cut -d: -f3)"
  BUNDLER="docker run --rm $BUNDLER_ARGS $DOCKER_TAG_BUNDLER"

  $BUNDLER create-upgrade
  $BUNDLER create-image

  ;;

"push")
  docker push $DOCKER_TAG_OS
  docker push $DOCKER_TAG_BUNDLER
  ;;

"clean")
  rm -rf $WORKDIR $OUTDIR
  ;;

*)
  echo "Unknown command"
  ;;

esac
