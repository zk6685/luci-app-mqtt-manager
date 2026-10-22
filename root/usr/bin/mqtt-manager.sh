#!/bin/sh
# ============================================================
#  MQTT Manager backend - Mosquitto broker management script
#  Target: OpenWrt / ImmortalWrt / PonWrt (apk package manager)
# ============================================================

ACTION="$1"
PASSWD_FILE="/etc/mosquitto/passwd"
CERT_DIR="/etc/mosquitto/cert"
CONF_FILE="/tmp/mosquitto.generated.conf"

# ---------- helper ----------
pm_installed() {
    # apk (Alpine/PonWrt) or opkg (OpenWrt) both supported
    if command -v apk >/dev/null 2>&1; then
        apk list --installed 2>/dev/null | grep -q "^$1-"
    elif command -v opkg >/dev/null 2>&1; then
        opkg list-installed 2>/dev/null | grep -q "^$1 "
    else
        return 1
    fi
}

pm_install() {
    if command -v apk >/dev/null 2>&1; then
        apk add "$1" >/dev/null 2>&1
    elif command -v opkg >/dev/null 2>&1; then
        opkg update >/dev/null 2>&1
        opkg install "$1" >/dev/null 2>&1
    fi
}

# ---------- status ----------
case "$ACTION" in
    status)
        if pidof mosquitto >/dev/null 2>&1; then
            echo "running"
        else
            echo "stopped"
        fi
        ;;

    restart)
        /etc/init.d/mosquitto restart >/dev/null 2>&1
        echo "重启指令已发送"
        ;;

    # ---------- config ----------
    get_config)
        PORT=$(uci -q get mosquitto.@mosquitto[0].port 2>/dev/null || echo "1883")
        ANON=$(uci -q get mosquitto.@mosquitto[0].allow_anonymous 2>/dev/null || echo "0")
        SYSINT=$(uci -q get mosquitto.@mosquitto[0].sys_interval 2>/dev/null || echo "2")
        MAXCONN=$(uci -q get mosquitto.@mosquitto[0].max_connections 2>/dev/null || echo "500")
        echo "PORT=$PORT"
        echo "ANON=$ANON"
        echo "SYSINT=$SYSINT"
        echo "MAXCONN=$MAXCONN"
        ;;

    save_config)
        PORT="$2"; ANON="$3"; SYSINT="$4"; MAXCONN="$5"
        uci set mosquitto.@mosquitto[0].port="${PORT}"
        uci set mosquitto.@mosquitto[0].allow_anonymous="${ANON}"
        uci set mosquitto.@mosquitto[0].sys_interval="${SYSINT}"
        uci set mosquitto.@mosquitto[0].max_connections="${MAXCONN}"
        uci commit mosquitto
        /etc/init.d/mosquitto restart >/dev/null 2>&1
        echo "配置已保存并重启"
        ;;

    # ---------- users ----------
    list_users)
        [ -f "$PASSWD_FILE" ] && cut -d: -f1 "$PASSWD_FILE"
        ;;

    add_user)
        NEWUSER="$2"; NEWPASS="$3"
        [ -z "$NEWUSER" ] || [ -z "$NEWPASS" ] && { echo "错误: 用户名密码不能为空"; exit 1; }
        touch "$PASSWD_FILE"
        mosquitto_passwd -b "$PASSWD_FILE" "$NEWUSER" "$NEWPASS" 2>/dev/null
        chmod 600 "$PASSWD_FILE"
        chown mosquitto:mosquitto "$PASSWD_FILE" 2>/dev/null
        echo "用户 $NEWUSER 添加成功"
        ;;

    del_user)
        DELUSER="$2"
        [ -z "$DELUSER" ] && exit 1
        sed -i "/^${DELUSER}:/d" "$PASSWD_FILE"
        echo "用户 $DELUSER 已删除"
        ;;

    # ---------- inspect ----------
    inspect)
        TIME=$(date "+%Y-%m-%d %H:%M:%S")
        PASS=$(uci -q get mqtt_manager.@general[0].password 2>/dev/null || echo "")
        TESTUSER=$(cut -d: -f1 "$PASSWD_FILE" 2>/dev/null | head -1)
        LANIP=$(uci -q get network.lan.ipaddr 2>/dev/null || echo "")

        echo "===== MQTT Manager 巡检报告 ====="
        echo "时间: $TIME"
        echo ""
        echo "[1] 服务状态:"
        if pidof mosquitto >/dev/null 2>&1; then
            echo " ✅ 服务运行中"
        else
            echo " ❌ 服务停止"
        fi
        echo ""
        echo "[2] 进程信息:"
        ps | grep mosquitto | grep -v grep
        echo ""
        echo "[3] 监听端口 (IPv4+IPv6):"
        netstat -tulnp 2>/dev/null | grep -E "1883|8883"
        echo ""
        echo "[4] 生效配置:"
        grep -E "allow_anonymous|password_file|listener" "$CONF_FILE" 2>/dev/null
        echo ""
        echo "[5] 密码文件权限:"
        ls -l "$PASSWD_FILE" 2>/dev/null
        echo ""
        echo "[6] 本地连通测试:"
        if command -v mosquitto_pub >/dev/null 2>&1 && [ -n "$PASS" ] && [ -n "$TESTUSER" ]; then
            mosquitto_pub -h 127.0.0.1 -p 1883 -u "$TESTUSER" -P "$PASS" -t /test/inspect -m "ok" >/dev/null 2>&1
            [ $? -eq 0 ] && echo " ✅ 本地MQTT发布成功" || echo " ❌ 本地MQTT发布失败"
        else
            echo " ⚠️ 缺少 mosquitto-clients 或未配置密码"
        fi
        echo ""
        echo "[7] LAN连通测试:"
        if command -v mosquitto_pub >/dev/null 2>&1 && [ -n "$LANIP" ] && [ -n "$PASS" ] && [ -n "$TESTUSER" ]; then
            mosquitto_pub -h "$LANIP" -p 1883 -u "$TESTUSER" -P "$PASS" -t /test/inspect -m "ok" >/dev/null 2>&1
            [ $? -eq 0 ] && echo " ✅ LAN MQTT发布成功" || echo " ❌ LAN MQTT发布失败"
        else
            echo " ⚠️ LAN IP或密码未配置"
        fi
        echo ""
        echo "[8] 防火墙1883检测:"
        FW_V4=$(uci show firewall 2>/dev/null | grep -i "name='MQTT-1883'" | grep -v IPv6 | wc -l)
        FW_V6=$(uci show firewall 2>/dev/null | grep -i "name='MQTT-1883-IPv6'" | wc -l)
        [ "$FW_V4" -gt 0 ] && echo " ✅ IPv4防火墙已放行1883" || echo " ⚠️ IPv4防火墙未放行1883"
        [ "$FW_V6" -gt 0 ] && echo " ✅ IPv6防火墙已放行1883" || echo " ⚠️ IPv6防火墙未放行1883"
        echo ""
        echo "[9] TLS证书检测:"
        if [ -f "$CERT_DIR/cert.pem" ] && [ -f "$CERT_DIR/privkey.pem" ]; then
            if command -v openssl >/dev/null 2>&1; then
                CERT_EXP=$(openssl x509 -in "$CERT_DIR/cert.pem" -noout -enddate 2>/dev/null | cut -d= -f2)
                echo " ✅ TLS证书存在，到期: $CERT_EXP"
            else
                echo " ✅ TLS证书存在"
            fi
        else
            echo " ⚠️ TLS证书不存在，8883未启用"
        fi
        echo ""
        echo "[10] 在线客户端统计:"
        if command -v mosquitto_sub >/dev/null 2>&1 && [ -n "$PASS" ] && [ -n "$TESTUSER" ]; then
            ONLINE=$(mosquitto_sub -h 127.0.0.1 -p 1883 -u "$TESTUSER" -P "$PASS" -t '$SYS/broker/clients/connected' -C 1 -W 4 2>/dev/null)
            ONLINE=$(echo "$ONLINE" | awk '{print int($1)}')
            [ -n "$ONLINE" ] && [ "$ONLINE" -ge 0 ] && echo " ✅ 当前在线客户端: $ONLINE 台" || echo " ⚠️ 获取在线数量超时"
        else
            echo " ⚠️ 缺少 mosquitto-clients 或未配置密码"
        fi
        echo ""
        echo "[11] 最近连接日志:"
        logread 2>/dev/null | grep -i mosquitto | tail -10
        ;;

    # ---------- firewall ----------
    fw_list)
        uci show firewall 2>/dev/null | grep -i mqtt | while read line; do
            name=$(echo "$line" | grep -o "name='[^']*'" | cut -d"'" -f2)
            port=$(echo "$line" | grep -o "dest_port='[^']*'" | cut -d"'" -f2)
            [ -n "$name" ] && [ -n "$port" ] && echo "$name|$port"
        done
        ;;

    fw_add)
        PORT="$2"; FAMILY="$3"
        NAME="MQTT-${PORT}"
        [ "$FAMILY" = "ipv6" ] && NAME="MQTT-${PORT}-IPv6"
        EXIST=$(uci show firewall 2>/dev/null | grep "name='${NAME}'" | wc -l)
        [ "$EXIST" -gt 0 ] && { echo "规则 $NAME 已存在"; exit 0; }
        uci add firewall rule >/dev/null
        uci set firewall.@rule[-1].name="${NAME}"
        uci set firewall.@rule[-1].src='wan'
        uci set firewall.@rule[-1].proto='tcp'
        uci set firewall.@rule[-1].dest_port="${PORT}"
        uci set firewall.@rule[-1].target='ACCEPT'
        uci set firewall.@rule[-1].family="${FAMILY}"
        uci commit firewall
        /etc/init.d/firewall reload >/dev/null 2>&1
        echo "规则 $NAME 添加成功"
        ;;

    # ---------- components ----------
    check_components)
        for pkg in mosquitto mosquitto-client openssl-util; do
            if pm_installed "$pkg"; then
                echo "$pkg|installed"
            else
                echo "$pkg|not_installed"
            fi
        done
        ;;

    install_component)
        PKG="$2"
        pm_install "$PKG" &
        echo "正在后台安装 $PKG"
        ;;

    # ---------- password ----------
    save_password)
        PASS="$2"
        uci get mqtt_manager.@general[0] >/dev/null 2>&1 || uci add mqtt_manager general
        uci set mqtt_manager.@general[0].password="${PASS}"
        uci commit mqtt_manager
        echo "密码已保存"
        ;;

    get_password)
        uci -q get mqtt_manager.@general[0].password 2>/dev/null || echo ""
        ;;

    *)
        echo "用法: $0 {status|restart|get_config|save_config|list_users|add_user|del_user|inspect|fw_list|fw_add|check_components|install_component|save_password|get_password}"
        ;;
esac
