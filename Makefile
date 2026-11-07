include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mqtt-manager
# 版本序列规则:
#   PKG_VERSION  语义版本, 功能/修复迭代时递增 (1.1.9 -> 1.1.10 -> 1.1.11 ...)
#   PKG_RELEASE  编译日期(北京时间 YYYYMMDD), 每次编译自动带上, 不再手工 bump
#   最终包名      luci-app-mqtt-manager-<PKG_VERSION>-r<PKG_RELEASE>.apk/.ipk
#   可用 BUILD_DATE=20261107 覆盖(CI 里统一注入,保证三个版本包名一致)
PKG_VERSION:=1.1.10
PKG_RELEASE:=$(if $(BUILD_DATE),$(BUILD_DATE),$(shell TZ=Asia/Shanghai date +%Y%m%d))

LUCI_TITLE:=MQTT Manager - Mosquitto Broker Management
LUCI_DESCRIPTION:=A LuCI panel to manage, inspect and configure the Mosquitto MQTT broker (status, users, firewall, TLS, components).
LUCI_DEPENDS:=+mosquitto +mosquitto-ssl
LUCI_PKGARCH:=all
LUCI_MAINTAINER:=zk6685 <zk6685@qq.com>

PKG_LICENSE:=MIT

# 强制 backend 脚本可执行（打包后权限 0755，避免 Permission denied）
PKG_FILE_PERMISSIONS := /usr/bin/mqtt-manager.sh 0755 root:root

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
