'use strict';
'require dom';
'require ui';
'require rpc';
'require view';
'require fs';

var callRpc = rpc.declare({
    object: 'mqtt-manager',
    method: 'exec',
    params: ['args']
});

function sh(args) {
    return callRpc(JSON.stringify(args)).then(function(res) {
        return (res && res.result !== undefined) ? res.result : '';
    });
}

return view.extend({
    load: function() {
        return Promise.all([
            sh(['status']),
            sh(['list_users'])
        ]);
    },

    render: function(data) {
        var statusOut = data[0];
        var usersOut = data[1];

        var isRunning = statusOut.indexOf('running') >= 0 || statusOut.indexOf('16908') >= 0;

        var outputBox = E('pre', {
            id: 'mqtt-output',
            style: 'background:#111827;color:#34d399;padding:1rem;border-radius:8px;white-space:pre-wrap;font-family:monospace;font-size:13px;min-height:200px;margin-top:10px;'
        }, '');

        function out(msg) {
            outputBox.textContent += msg + '\n';
        }

        function svcAction(act, label) {
            if (act !== 'start' && !confirm('确认' + label + ' Mosquitto？')) return;
            out('>>> ' + label + ' Mosquitto...');
            sh([act]).then(function(res) {
                out(res);
                out('>>> 刷新状态...');
                setTimeout(function() {
                    sh(['status']).then(function(s) {
                        out(s.indexOf('running') >= 0 ? '结果: 服务运行中' : '结果: 服务已停止');
                    });
                }, 2000);
            });
        }

        function runInspect() {
            var u = document.getElementById('inspect-user').value;
            var p = document.getElementById('inspect-pass').value;
            out('正在巡检...');
            sh(['inspect', u, p]).then(function(res) {
                outputBox.textContent = res;
            });
        }

        function fwAdd(family) {
            var label = family === 'ipv4' ? 'IPv4' : 'IPv6';
            if (!confirm('确认添加WAN口放行TCP 1883 (' + label + ')？')) return;
            out('>>> 添加防火墙 ' + label + ' 放行 1883 ...');
            sh(['fw_add', '1883', family]).then(function(res) {
                out(res);
            });
        }

        var badge = E('span', {
            style: 'display:inline-block;padding:6px 16px;border-radius:20px;font-size:15px;font-weight:bold;' +
                (isRunning ? 'background:#dcfce7;color:#16a34a;' : 'background:#fee2e2;color:#dc2626;')
        }, isRunning ? '运行中' : '已停止');

        return E('div', { 'class': 'cbi-map' }, [
            E('h2', {}, 'MQTT Manager - 状态'),
            E('div', { style: 'background:#fff;border:1px solid #e5e7eb;border-radius:8px;padding:1.25rem;margin-bottom:1rem;' }, [
                E('h3', {}, '服务状态'),
                E('p', {}, [
                    'Mosquitto 服务: ', badge
                ]),
                E('p', {}, '监听端口: 1883 (IPv4+IPv6双栈)'),
                E('div', { style: 'margin:10px 0;padding:10px;background:#f9fafb;border-radius:6px;' }, [
                    E('label', { style: 'font-size:13px;color:#374151;margin-right:8px;' }, '巡检测试账号: '),
                    E('input', { id: 'inspect-user', value: 'zk6685', style: 'padding:4px 8px;border:1px solid #d1d5db;border-radius:4px;width:140px;' }),
                    E('input', { id: 'inspect-pass', type: 'password', placeholder: '密码', style: 'padding:4px 8px;border:1px solid #d1d5db;border-radius:4px;width:140px;margin-left:6px;' }),
                    E('span', { style: 'font-size:12px;color:#6b7280;margin-left:6px;' }, '留空则自动取密码文件首个用户')
                ]),
                E('p', { style: 'margin-top:12px;' }, [
                    E('button', {
                        class: 'cbi-button',
                        style: 'background:#16a34a;color:#fff;margin-right:4px;',
                        click: function() { svcAction('start', '启动'); }
                    }, '启动'),
                    E('button', {
                        class: 'cbi-button',
                        style: 'background:#dc2626;color:#fff;margin-right:4px;',
                        click: function() { svcAction('stop', '停止'); }
                    }, '停止'),
                    E('button', {
                        class: 'cbi-button cbi-button-apply',
                        style: 'margin-right:4px;',
                        click: function() { svcAction('restart', '重启'); }
                    }, '重启服务'),
                    E('button', {
                        class: 'cbi-button cbi-button-apply',
                        style: 'margin-right:4px;',
                        click: runInspect
                    }, '一键巡检'),
                    E('button', {
                        class: 'cbi-button',
                        style: 'background:#d97706;color:#fff;margin-right:4px;',
                        click: function() { fwAdd('ipv4'); }
                    }, '防火墙放行IPv4'),
                    E('button', {
                        class: 'cbi-button',
                        style: 'background:#d97706;color:#fff;margin-right:4px;',
                        click: function() { fwAdd('ipv6'); }
                    }, '防火墙放行IPv6'),
                    E('button', {
                        class: 'cbi-button cbi-button-reset',
                        click: function() { outputBox.textContent = ''; }
                    }, '清空输出')
                ]),
                outputBox
            ])
        ]);
    }
});
