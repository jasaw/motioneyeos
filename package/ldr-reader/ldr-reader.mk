#############################################################
#
# ldr-reader
#
#############################################################

LDR_READER_VERSION=7137b62d01e1a03f899405f54ce549b551e00d28
LDR_READER_SITE = https://github.com/jasaw/ldr-reader.git
LDR_READER_SITE_METHOD = git
LDR_READER_INSTALL_TARGET:=YES

define LDR_READER_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" -C $(@D) all
endef

define LDR_READER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/ldr-reader $(TARGET_DIR)/usr/sbin
endef

$(eval $(generic-package))
