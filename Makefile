# Copyright 2025 OneNAS.space, Jackie264 (jackie.han@gmail.com).

include $(TOPDIR)/rules.mk

PKG_NAME:=ipv6-monitor
PKG_VERSION:=1.0.2
PKG_RELEASE:=2

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/ipv6-monitor
  SECTION:=net
  CATEGORY:=Network
  TITLE:=IPv6 PD Monitor for WAN6
  DEPENDS:=
  PKGARCH:=all
endef

define Package/ipv6-monitor/description
 A small daemon to monitor IPv6-PD on WAN6 and auto-recover when prefix is lost.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
	# nothing to compile, shell scripts only
endef

define Package/ipv6-monitor/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/ipv6-monitor $(1)/etc/init.d/ipv6-monitor

	$(INSTALL_DIR) $(1)/etc/netwatch
	$(INSTALL_BIN) ./files/etc/netwatch/ipv6_pd_monitor.sh $(1)/etc/netwatch/ipv6_pd_monitor.sh

	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/99-wan6-trigger $(1)/etc/hotplug.d/iface/99-wan6-trigger

	$(INSTALL_DIR) $(1)/root
	$(INSTALL_BIN) ./files/root/sysinfo.sh $(1)/root/sysinfo.sh
endef

define Package/ipv6-monitor/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] || /etc/init.d/ipv6-monitor enable
exit 0
endef

define Package/ipv6-monitor/prerm
#!/bin/sh
[ -z "$${IPKG_INSTROOT}" ] || /etc/init.d/ipv6-monitor disable
exit 0
endef

$(eval $(call BuildPackage,ipv6-monitor))
