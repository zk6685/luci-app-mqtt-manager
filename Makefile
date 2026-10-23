include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mqtt-manager
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

LUCI_TITLE:=MQTT Manager - Mosquitto Broker Management
LUCI_DESCRIPTION:=A LuCI panel to manage Mosquitto MQTT broker (status, config, users, components). Modern JS approach.
LUCI_DEPENDS:=+mosquitto +mosquitto-ssl
LUCI_PKGARCH:=all
LUCI_MAINTAINER:=zk6685 <zk6685@qq.com>

PKG_LICENSE:=MIT

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
