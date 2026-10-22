# luci-app-mqtt-manager

LuCI 面板插件，用于在 OpenWrt / ImmortalWrt / PonWrt 上管理并巡检 **Mosquitto MQTT Broker**。

## 功能

- **状态**：服务运行状态、监听端口、一键巡检（服务/进程/端口/配置/密码文件/连通测试/防火墙/TLS/在线客户端/日志）、重启服务
- **用户管理**：查看 / 添加 / 删除 MQTT 账号（基于 `/etc/mosquitto/passwd`）
- **防火墙 & TLS**：查看 / 添加 WAN 口放行 1883 规则（IPv4 + IPv6）、TLS 证书目录提示
- **组件管理**：检测并一键安装 `mosquitto`、`mosquitto-client`、`openssl-util`（自动识别 apk / opkg 包管理器）

## 依赖

- `mosquitto`（MQTT broker）
- `mosquitto-ssl` / `mosquitto-client`（客户端工具，用于连通性测试）
- LuCI（`luci-base`）

## 安装

在 OpenWrt 源码树中：

```sh
# 1. 将本目录放入 package/ 或 feed
git clone https://github.com/zk6685/luci-app-mqtt-manager.git package/luci-app-mqtt-manager

# 2. 编译
make package/luci-app-mqtt-manager/compile V=s

# 3. 将生成的 .ipk 上传到路由器安装
opkg install luci-app-mqtt-manager_*.ipk
# 或 (PonWrt/Alpine apk)
apk add --allow-untrusted luci-app-mqtt-manager_*.apk
```

安装后 LuCI 菜单路径：**服务 → MQTT Manager**

## 文件结构

```
luci-app-mqtt-manager/
├── Makefile
├── luasrc/
│   ├── controller/mqtt_manager.lua     # LuCI 控制器 + API 转发
│   └── view/mqtt_manager/              # 页面模板 (status/users/firewall/components)
├── root/
│   ├── etc/luci/menu.d/                # 菜单注册
│   └── usr/bin/mqtt-manager.sh         # 后端业务脚本
└── po/                                 # 翻译
```

## License

MIT
