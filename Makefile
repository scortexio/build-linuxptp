ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
LINUXPTP_VERSION := $(shell \
  sed -n '/LINUXPTP_VERSION\s*=\s*/s///p' \
  buildroot/package/linuxptp/linuxptp.mk \
)

#
# Common targets
#

.PHONY: all
all: package container

.PHONY: source
source: build_armhf/.config build_x86_64/.config
	$(MAKE) -C build_armhf source
	$(MAKE) -C build_x86_64 source

#
# Targets for building the ARM package
#

PTP4L = build_armhf/target/usr/sbin/ptp4l
OPKG_BUILD = build_armhf/host/bin/opkg-build
FAKEROOT = build_armhf/host/bin/fakeroot
PACKAGE = linuxptp_$(LINUXPTP_VERSION)_armhf.ipk

build_armhf/.config: defconfig_armhf .gitmodules
	$(MAKE) -C buildroot O=$(ROOT_DIR)/build_armhf BR2_DL_DIR=$(ROOT_DIR)/dl allnoconfig
	$(MAKE) -C build_armhf BR2_DEFCONFIG=$(ROOT_DIR)/defconfig_armhf defconfig
	
$(PTP4L) $(OPKG_BUILD): build_armhf/.config
	$(MAKE) -C build_armhf

package/usr/sbin/ptp4l: $(PTP4L)
	install -D $< $@

package/CONTROL/control: control
	mkdir -p $(dir $@)
	sed s/LINUXPTP_VERSION/$(LINUXPTP_VERSION)/ $< >$@

.PHONY: package
package: $(PACKAGE)
$(PACKAGE): package/CONTROL/control package/usr/sbin/ptp4l
	$(FAKEROOT) -- sh -c ' \
	chown 0.0 package && \
	$(OPKG_BUILD) package \
	'

#
# Targets for building the x86 Docker container
#

build_x86_64/.config: defconfig_x86_64 .gitmodules
	$(MAKE) -C buildroot O=$(ROOT_DIR)/build_x86_64 BR2_DL_DIR=$(ROOT_DIR)/dl allnoconfig
	$(MAKE) -C build_x86_64 BR2_DEFCONFIG=$(ROOT_DIR)/defconfig_x86_64 defconfig

build_x86_64/images/rootfs.tar.gz: build_x86_64/.config
	$(MAKE) -C build_x86_64

CONTAINER_NAME = scortex.azurecr.io/linuxptp:$(LINUXPTP_VERSION)
.PHONY: container
container: .container.stamp
.container.stamp: build_x86_64/images/rootfs.tar.gz
	docker import $< $(CONTAINER_NAME)
	touch $@

.PHONY: push
push: .container.stamp
	docker push $(CONTAINER_NAME)
