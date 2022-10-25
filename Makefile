all: build

.PHONY: prepare
prepare:
	./build.sh prepare

.PHONY: menuconfig
menuconfig:
	./build.sh menuconfig

.PHONY: build
build:
	./build.sh build

.PHONY: flash
flash:
	./build.sh flash

.PHONY: clean
clean:
	./build.sh clean