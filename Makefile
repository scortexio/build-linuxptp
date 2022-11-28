ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PACKAGE = ptp4l_3.1.1_armhf.ipk
BUILDROOT_SRC_DIR = $(ROOT_DIR)/buildroot
BUILDROOT_BUILD_DIR = $(ROOT_DIR)/build
BUILDROOT_DL_DIR = $(ROOT_DIR)/build
BUILDROOT_CONFIG = $(BUILDROOT_BUILD_DIR)/.config
BUILDROOT_DEFCONFIG = $(ROOT_DIR)/defconfig
BUILDROOT_MAKE = $(MAKE) -C $(BUILDROOT_BUILD_DIR)
PTP4L = $(BUILDROOT_BUILD_DIR)/target/usr/sbin/ptp4l
OPKG_BUILD = $(BUILDROOT_BUILD_DIR)/host/bin/opkg-build

.PHONY: all
all: $(PACKAGE)
	
$(BUILDROOT_CONFIG): .gitmodules $(BUILDROOT_DEFCONFIG)
	$(MAKE) -C $(BUILDROOT_SRC_DIR) O=$(BUILDROOT_BUILD_DIR) BR2_DL_DIR=$(BUILDROOT_DL_DIR) allnoconfig
	$(MAKE) -C $(BUILDROOT_BUILD_DIR) BR2_DEFCONFIG=$(BUILDROOT_DEFCONFIG) defconfig

.PHONY: source
source: $(BUILDROOT_CONFIG)
	$(MAKE) -C $(BUILDROOT_BUILD_DIR) source

$(PTP4L) $(OPKG_BUILD): $(BUILDROOT_CONFIG)
	$(MAKE) -C $(BUILDROOT_BUILD_DIR)

package/bin/ptp4l: $(PTP4L)
	install -D $< $@

package/CONTROL/control: control
	install -D $< $@

$(PACKAGE): package/CONTROL/control package/bin/ptp4l
	$(OPKG_BUILD) package
