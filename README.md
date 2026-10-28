# luci-app-mqtt-manager

LuCI 面板插件，用于在 **OpenWrt / ImmortalWrt / PonWrt** 上一站式管理、配置并巡检 **Mosquitto MQTT Broker**。

菜单路径：**服务 → MQTT Manager**

---

## 页面总览

插件分四个页签：**状态** / **基础配置** / **用户管理** / **组件管理**。

### 1. 状态页（一键巡检）

- 实时显示 Mosquitto 服务运行状态（运行中 / 已停止徽标）与监听端口（IPv4 + IPv6 双栈 1883）
- **巡检信息可保存**：测试账号、密码、外网域名、端口填一次后点「保存巡检信息」即存入配置，下次打开自动回填，无需重复输入
- 操作按钮：启动 / 停止 / 重启服务 / 一键巡检 / 保存巡检信息 / 防火墙放行 IPv4 / 防火墙放行 IPv6 / 清空输出

**一键巡检报告共 12 项：**

| # | 检查项 | 说明 |
|---|--------|------|
| 1 | 服务状态 | Mosquitto 是否运行 |
| 2 | 进程信息 | 进程号与启动命令 |
| 3 | 监听端口 | IPv4 / IPv6 的 1883 LISTEN 状态 |
| 4 | 生效配置 | allow_anonymous / password_file 等实际生效项 |
| 5 | 密码文件权限 | `/etc/mosquitto/passwd` 是否存在、属主、权限（应为 root:root 644） |
| 6 | 本地连通测试 | `mosquitto_pub` 127.0.0.1 认证发布 |
| 7 | LAN 连通测试 | 从 LAN IP 认证发布 |
| 8 | 外网域名连通测试 | 填了域名+端口才测（如 `zk6685.top:1883`），留空自动跳过 |
| 9 | 防火墙检测 | IPv4 / IPv6 是否已放行 1883 |
| 10 | TLS 证书检测 | 8883 证书是否就绪 |
| 11 | 在线客户端统计 | 当前已连接客户端数量 |
| 12 | 最近连接日志 | 最近的连接 / 认证记录 |

### 2. 基础配置页

- **配置模式切换**：UCI 模式（`/etc/config/mosquitto`，推荐）/ 文件模式（直接改 `mosquitto.conf`）
- **读取配置**：一键读出当前全部生效配置
- **检测配置完整性 + 一键修复**：自动检测 6 类常见故障并可一键修复：
  1. 配置模式 `use_uci` 是否为 1（防止误入文件模式导致 crash loop）
  2. 监听端口是否设置
  3. `password_file` 是否缺失（缺失会导致所有用户认证失败）
  4. 密码文件属主 / 权限（root:root + 644）
  5. 是否存在重复 listener 段（Address in use 的根因）
  6. 服务运行状态
- **关键配置项**：监听端口、允许匿名、密码文件、持久化、日志输出，保存即重启生效
- **完整配置可编辑**：直接编辑原始配置并保存
- **TLS 证书上传**：上传 `cert.pem` / `privkey.pem` 启用 8883

### 3. 用户管理页

- 列出 `/etc/mosquitto/passwd` 中的所有 MQTT 账号
- 添加新用户（自动 `mosquitto_passwd` 写入）/ 删除用户

### 4. 组件管理页

- 检测并一键安装 / 卸载依赖组件：`mosquitto`、`mosquitto-client`、`mosquitto-ssl`、`openssl-util`、`ca-bundle`
- 自动识别设备使用的包管理器（apk / opkg）

---

## 设计上解决的典型坑

本插件针对 Mosquitto 2.0.x 在 OpenWrt 上的常见问题做了兜底：

- **crash loop**：启动时强制 `use_uci=1`，避免走文件模式生成失败配置
- **全员 not authorised**：自动补写 `password_file` 并修正属主权限
- **Address in use**：检测并清理重复 listener 段
- **保存假成功**：巡检信息保存后回读校验，区分真写入与失败

---

## 依赖

- `mosquitto`（MQTT broker）
- `mosquitto-ssl` / `mosquitto-client`（客户端工具，用于连通性测试）
- LuCI（`luci-base`）

---

## 安装

### 方式一：直接安装 Release 包

在 [Releases](https://github.com/zk6685/luci-app-mqtt-manager/releases) 下载对应版本：

```sh
# PonWrt / Alpine (apk)
apk add --force-overwrite --allow-untrusted /tmp/25.12-luci-app-mqtt-manager-aarch64.apk

# OpenWrt / ImmortalWrt (ipk)
opkg install /tmp/luci-app-mqtt-manager_*.ipk

# 清缓存并重启 uhttpd
rm -rf /tmp/luci-indexcache.* /tmp/luci-modulecache/
/etc/init.d/uhttpd restart
```

### 方式二：源码编译

```sh
# 1. 将本目录放入 OpenWrt 源码树 package/
git clone https://github.com/zk6685/luci-app-mqtt-manager.git package/luci-app-mqtt-manager

# 2. 编译
make package/luci-app-mqtt-manager/compile V=s
```

编译产物通过 GitHub Actions 自动发布，矩阵支持：
- OpenWrt 25.12 → `.apk`
- OpenWrt 24.10 → `.ipk`
- OpenWrt 23.05 → `.ipk`

---

## 文件结构

```
luci-app-mqtt-manager/
├── Makefile
├── .github/workflows/build-apk.yml    # 三版本自动编译发布
├── luasrc/
│   ├── controller/mqtt_manager.lua    # LuCI 控制器 + 全部 API 转发
│   └── view/mqtt_manager/
│       ├── status.htm                 # 状态 + 巡检 + 保存
│       ├── config.htm                 # 基础配置 + 完整性检测/修复 + TLS
│       ├── users.htm                 # 用户管理
│       └── components.htm            # 组件管理
├── root/
│   └── usr/bin/mqtt-manager.sh       # 后端业务脚本（巡检/配置/用户/组件）
└── po/                                # 翻译
```

---

## 分支说明

- **main**：Lua 稳定版（v1.1.x），生产可用
- **v2-js-dev**：现代 JS 重构版（v2.0.x）存档分支，仍在调试

---

## License

MIT
