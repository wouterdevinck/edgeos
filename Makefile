all: build

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

.PHONY: toolchain
toolchain:
	./build.sh toolchain

.PHONY: build
build:
	./build.sh build

.PHONY: clean
clean:
	./build.sh clean