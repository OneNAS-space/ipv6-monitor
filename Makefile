# Copyright 2025 OneNAS.space, Jackie264 (jackie.han@gmail.com).

include $(TOPDIR)/rules.mk

PKG_NAME:=ipv6-monitor
PKG_VERSION:=1.0.4
PKG_RELEASE:=3

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/ipv6-monitor
  SECTION:=net
  CATEGORY:=Network
  TITLE:=IPv6 PD Monitor on LAN
  DEPENDS:=+jsonfilter
  PKGARCH:=all
endef

define Package/ipv6-monitor/description
  An event-driven script to monitor IPv6-PD assignment on LAN and automatically 
  trigger wan6 interface recovery when the prefix is lost or missing.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
	# nothing to compile, shell scripts only
endef

define Package/ipv6-monitor/install
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/90-ipv6-pd-monitor $(1)/etc/hotplug.d/iface/90-ipv6-pd-monitor
endef

$(eval $(call BuildPackage,ipv6-monitor))
