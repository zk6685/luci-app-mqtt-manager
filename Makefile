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

# 脚本执行位由 git mode 100755 控制（见 root/usr/bin/mqtt-manager.sh）

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
