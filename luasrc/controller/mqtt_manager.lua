module("luci.controller.mqtt_manager", package.seeall)

function index()
    entry({"admin", "services", "mqtt_manager"},
        firstchild(),
        _("MQTT Manager"), 60)
    entry({"admin", "services", "mqtt_manager", "status"},
        template("mqtt_manager/status"),
        _("状态"), 10)
    entry({"admin", "services", "mqtt_manager", "users"},
        template("mqtt_manager/users"),
        _("用户管理"), 20)
    entry({"admin", "services", "mqtt_manager", "firewall"},
        template("mqtt_manager/firewall"),
        _("防火墙 & TLS"), 30)
    entry({"admin", "services", "mqtt_manager", "components"},
        template("mqtt_manager/components"),
        _("组件管理"), 40)

    -- API 路由（独立，不可见菜单）
    entry({"admin", "services", "mqtt_manager", "api", "status"},
        call("api_status"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "restart"},
        call("api_restart"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "get_config"},
        call("api_get_config"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "save_config"},
        call("api_save_config"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "list_users"},
        call("api_list_users"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "add_user"},
        call("api_add_user"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "del_user"},
        call("api_del_user"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "inspect"},
        call("api_inspect"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "fw_list"},
        call("api_fw_list"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "fw_add"},
        call("api_fw_add"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "check_components"},
        call("api_check_components"), nil).leaf = true
    entry({"admin", "services", "mqtt_manager", "api", "install_component"},
        call("api_install_component"), nil).leaf = true
end

local function run_sh(args)
    local fd = io.popen("/usr/bin/mqtt-manager.sh " .. args .. " 2>&1")
    if not fd then return "internal error" end
    local out = fd:read("*a")
    fd:close()
    return out
end

local function json_out(data)
    luci.http.prepare_content("application/json; charset=utf-8")
    luci.http.write_json(data)
end

function api_status()
    json_out({ status = run_sh("status"):gsub("%s+$", "") })
end

function api_restart()
    json_out({ msg = run_sh("restart") })
end

function api_get_config()
    local out = run_sh("get_config")
    local cfg = {}
    for line in out:gmatch("[^\n]+") do
        local k, v = line:match("^([^=]+)=(.*)$")
        if k then cfg[k] = v end
    end
    json_out(cfg)
end

function api_save_config()
    local port   = luci.http.formvalue("port") or "1883"
    local anon   = luci.http.formvalue("anon") or "0"
    local sysint = luci.http.formvalue("sysint") or "2"
    local maxconn= luci.http.formvalue("maxconn") or "500"
    json_out({ msg = run_sh(string.format("save_config %q %q %q %q", port, anon, sysint, maxconn)) })
end

function api_list_users()
    local out = run_sh("list_users")
    local users = {}
    for u in out:gmatch("[^\n]+") do
        table.insert(users, u)
    end
    json_out(users)
end

function api_add_user()
    local user = luci.http.formvalue("username") or ""
    local pass = luci.http.formvalue("password") or ""
    json_out({ msg = run_sh(string.format("add_user %q %q", user, pass)) })
end

function api_del_user()
    local user = luci.http.formvalue("username") or ""
    json_out({ msg = run_sh(string.format("del_user %q", user)) })
end

function api_inspect()
    luci.http.prepare_content("text/plain; charset=utf-8")
    luci.http.write(run_sh("inspect"))
end

function api_fw_list()
    local out = run_sh("fw_list")
    local list = {}
    for line in out:gmatch("[^\n]+") do
        local name, port = line:match("^(.-)|(.-)$")
        if name then table.insert(list, { name = name, port = port }) end
    end
    json_out(list)
end

function api_fw_add()
    local port = luci.http.formvalue("port") or "1883"
    local family = luci.http.formvalue("family") or "ipv4"
    json_out({ msg = run_sh(string.format("fw_add %q %q", port, family)) })
end

function api_check_components()
    local out = run_sh("check_components")
    local list = {}
    for line in out:gmatch("[^\n]+") do
        local name, status, ver = line:match("^(.-)|(.-)|(.-)$")
        if name then table.insert(list, { name = name, status = status, version = ver }) end
    end
    json_out(list)
end

function api_install_component()
    local pkg = luci.http.formvalue("pkg") or ""
    json_out({ msg = run_sh(string.format("install_component %q", pkg)) })
end
