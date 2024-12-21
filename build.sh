#!/bin/bash
set -e

BR_VERSION=2024.02

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
WORKDIR="$SCRIPT_DIR/buildroot"
EXTDIR="$SCRIPT_DIR/external"
PATCHDIR="$SCRIPT_DIR/patches"
OUTDIR="$SCRIPT_DIR/output"
EXAMPLEDIR="$SCRIPT_DIR/bundler/example"
ARTDIR="$OUTDIR/artifacts"
TOOLSDIR="$OUTDIR/tools"

export EDGEOS_VERSION=$(git describe --tags --dirty)

DOCKERFILE_OS="$SCRIPT_DIR/docker/Dockerfile-edgeos"
DOCKERFILE_BUNDLER="$SCRIPT_DIR/docker/Dockerfile-bundler"

DOCKER_NAME_OS="wouterdevinck/edgeos"
DOCKER_TAG_BUNDLER="wouterdevinck/edgeos-bundler:$EDGEOS_VERSION"

EXAMPLE_RAW_PC_IMAGE="Example-pc-1.0.0.img"

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

"build")

  # Check parameter count
  if [ $# -ne 2 ]; then 
    printf "\nUsage: $0 build [rpi4|pc].\n\n"
    exit 2
  fi
  
  ;;&
  
"menuconfig")

  # Check parameter count
  if [ $# -ne 3 ]; then 
    printf "\nUsage: $0 menuconfig [rpi4|pc] [boot|root|linux|busybox].\n\n"
    exit 2
  fi

  # Check type of menuconfig
  if ! [[ $3 = @(boot|root|linux|busybox) ]]; then
    printf "\nUsage: $0 menuconfig [rpi4|pc] [boot|root|linux|busybox].\n\n"
    exit 2
  fi
  
  ;;&

"build"|"menuconfig")

  # Check if prepare has been run
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

"build"|"menuconfig"|"bundle"|"push")

  # Check build configuration
  if ! [[ $2 = @(rpi4|pc) ]]; then
    printf "\nUnknown build configuration.\n\n"
    exit 2
  fi

  # Build configuration
  EDGEOS_CONFIGURATION=$2
  CONFIG_BOOT="edgeos_${EDGEOS_CONFIGURATION}_boot_defconfig"
  CONFIG_ROOT="edgeos_${EDGEOS_CONFIGURATION}_root_defconfig"
  OUTDIR_BOOT="$OUTDIR/${EDGEOS_CONFIGURATION}-boot"
  OUTDIR_ROOT="$OUTDIR/${EDGEOS_CONFIGURATION}-root"
  CONFPATH_BOOT="$EXTDIR/configs/$CONFIG_BOOT"
  CONFPATH_ROOT="$EXTDIR/configs/$CONFIG_ROOT"
  DOCKER_TAG_OS="$DOCKER_NAME_OS-$EDGEOS_CONFIGURATION:$EDGEOS_VERSION"

  ;;&

"menuconfig")

  # Menuconfig
  case $3 in
    "boot")
      menuconfig $OUTDIR_BOOT $CONFPATH_BOOT
      ;;
    "root")
      menuconfig $OUTDIR_ROOT $CONFPATH_ROOT
      ;;
    "linux")
      menuconfiglinux $OUTDIR_BOOT
      ;;
    "busybox")
      menuconfigbusybox $OUTDIR_ROOT
      ;;
  esac
  ;;

"build")

  echo "Building EdgeOS version $EDGEOS_VERSION"

  # Write version number to file
  echo "$EDGEOS_VERSION" > $WORKDIR/edgeos-version

  # Build FAT boot partition - containing firmware (& config), kernel and initramfs
  build $OUTDIR_BOOT $CONFIG_BOOT

  # Build rootfs
  build $OUTDIR_ROOT $CONFIG_ROOT

  # Copy tools
  rm -rf $TOOLSDIR
  mkdir $TOOLSDIR
  cp $OUTDIR_BOOT/host/lib/libconfuse.so.2.1.0 $TOOLSDIR
  cp $OUTDIR_BOOT/host/bin/genimage $TOOLSDIR

  # Copy artifacts
  rm -rf $ARTDIR
  mkdir $ARTDIR
  cp $OUTDIR_BOOT/images/*.vfat $ARTDIR
  cp $OUTDIR_ROOT/images/rootfs.squashfs $ARTDIR
  cd $ARTDIR

  # Tar artifacts
  tar -czf edgeos-$EDGEOS_CONFIGURATION.tar.gz *.vfat rootfs.squashfs

  # Build Docker images
  docker buildx build --load -t $DOCKER_TAG_OS -f $DOCKERFILE_OS $ARTDIR --build-arg EDGEOS_CONFIGURATION=$EDGEOS_CONFIGURATION

  ;;&

"build"|"bundler")

  # Build bundler Docker image
  docker buildx build --load -t $DOCKER_TAG_BUNDLER -f $DOCKERFILE_BUNDLER --build-arg BUNDLER_VERSION=$EDGEOS_VERSION $SCRIPT_DIR

  ;;

"bundle")

  # Run bundler on example

  BUNDLER_ARGS="-v $EXAMPLEDIR:/workdir -v /var/run/docker.sock:/var/run/docker.sock -u $(id -u $USER):$(getent group docker | cut -d: -f3)"
  BUNDLER="docker run --rm $BUNDLER_ARGS $DOCKER_TAG_BUNDLER"

  IMG_ARGS=""
  if [ "$EDGEOS_CONFIGURATION" = "pc" ]; then 
    IMG_ARGS="-raw"
  fi

  $BUNDLER create-upgrade 
  $BUNDLER create-image $EDGEOS_CONFIGURATION $IMG_ARGS

  ;;

"push")
  docker push $DOCKER_TAG_OS
  docker push $DOCKER_TAG_BUNDLER
  ;;

"clean")
  rm -rf $WORKDIR $OUTDIR
  ;;

"qemu")

  # Disk image to run
  DISK=$EXAMPLEDIR/$EXAMPLE_RAW_PC_IMAGE

  # Check in PC build available to run in QEMU
  if [ ! -e "$DISK" ]; then
    printf "\nPlease first build and bundle for PC platform.\n\n"
    exit 2
  fi

  # Make the disk image bigger
  dd if=/dev/zero of=$DISK seek=10GB obs=1MB count=0

  # If no EFI NVRAM file, copy the default one
  if [ ! -e OVMF_VARS.fd ]; then
    cp /usr/share/OVMF/OVMF_VARS.fd .
  fi

  # Run PC variant in QEMU with EFI
  qemu-system-x86_64 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=OVMF_VARS.fd \
    -drive file=$DISK,format=raw \
    -m 4G \
    -nographic
  ;;

*)
  echo "Unknown command"
  ;;

esac
