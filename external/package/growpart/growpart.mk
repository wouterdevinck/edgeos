GROWPART_VERSION = 0.33
GROWPART_SITE = $(call github,canonical,cloud-utils,$(GROWPART_VERSION))
GROWPART_LICENSE = GPL-3
GROWPART_LICENSE_FILES = LICENSE

define GROWPART_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 $(@D)/bin/growpart $(TARGET_DIR)/usr/bin/growpart
endef

$(eval $(generic-package))