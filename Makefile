include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mqtt-manager
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

LUCI_TITLE:=MQTT Manager - Mosquitto Broker Management
LUCI_DESCRIPTION:=A LuCI panel to manage, inspect and configure the Mosquitto MQTT broker (status, users, firewall, TLS, components).
LUCI_DEPENDS:=+mosquitto +mosquitto-ssl
LUCI_PKGARCH:=all
LUCI_MAINTAINER:=zk6685 <zk6685@qq.com>

PKG_LICENSE:=MIT

# 同时输出 ipk (opkg) 和 apk (PonWrt/ImmortalWrt apk 分支)
PKG_TARGETS := ipkg apk

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
