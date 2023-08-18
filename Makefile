all: build

.PHONY: version
version:
	./build.sh version

.PHONY: prepare
prepare:
	./build.sh prepare

.PHONY: menuconfig-rpi4-toolchain
menuconfig-rpi4-toolchain:
	./build.sh menuconfig-rpi4-toolchain

.PHONY: menuconfig-rpi4-boot
menuconfig-rpi4-boot:
	./build.sh menuconfig-rpi4-boot

.PHONY: menuconfig-rpi4-root
menuconfig-rpi4-root:
	./build.sh menuconfig-rpi4-root

.PHONY: menuconfig-rpi4-linux
menuconfig-rpi4-linux:
	./build.sh menuconfig-rpi4-linux

.PHONY: menuconfig-rpi4-busybox
menuconfig-rpi4-busybox:
	./build.sh menuconfig-rpi4-busybox

.PHONY: toolchain
toolchain:
	./build.sh toolchain

.PHONY: build
build:
	./build.sh build

.PHONY: bundler
bundler:
	./build.sh bundler

.PHONY: bundle
bundle:
	./build.sh bundle

.PHONY: push
push:
	./build.sh push

.PHONY: clean
clean:
	./build.sh clean