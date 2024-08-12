all: build-rpi4 build-pc

# Generic targets

.PHONY: version
version:
	./build.sh version

.PHONY: prepare
prepare:
	./build.sh prepare

.PHONY: bundler
bundler:
	./build.sh bundler

.PHONY: clean
clean:
	./build.sh clean

# RPI4 targets

.PHONY: menuconfig-rpi4-boot
menuconfig-rpi4-boot:
	./build.sh menuconfig rpi4 boot

.PHONY: menuconfig-rpi4-root
menuconfig-rpi4-root:
	./build.sh menuconfig rpi4 root

.PHONY: menuconfig-rpi4-linux
menuconfig-rpi4-linux:
	./build.sh menuconfig rpi4 linux

.PHONY: menuconfig-rpi4-busybox
menuconfig-rpi4-busybox:
	./build.sh menuconfig rpi4 busybox

.PHONY: build-rpi4
build-rpi4:
	./build.sh build rpi4

.PHONY: push-rpi4
push-rpi4:
	./build.sh push rpi4

.PHONY: bundle-rpi4
bundle-rpi4:
	./build.sh bundle rpi4

# PC targets

.PHONY: menuconfig-pc-boot
menuconfig-pc-boot:
	./build.sh menuconfig pc boot

.PHONY: menuconfig-pc-root
menuconfig-pc-root:
	./build.sh menuconfig pc root

.PHONY: menuconfig-pc-linux
menuconfig-pc-linux:
	./build.sh menuconfig pc linux

.PHONY: menuconfig-pc-busybox
menuconfig-pc-busybox:
	./build.sh menuconfig pc busybox

.PHONY: build-pc
build-pc:
	./build.sh build pc

.PHONY: push-pc
push-pc:
	./build.sh push pc

.PHONY: bundle-pc
bundle-pc:
	./build.sh bundle pc

.PHONY: qemu
qemu:
	./build.sh qemu
