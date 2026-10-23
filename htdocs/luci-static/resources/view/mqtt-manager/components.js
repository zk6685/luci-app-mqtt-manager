'use strict';
'require dom';
'require ui';
'require rpc';
'require view';

var callRpc = rpc.declare({
    object: 'mqtt-manager',
    method: 'exec',
    params: ['args']
});

function sh(args) { return callRpc(JSON.stringify(args)); }

return view.extend({
    load: function() {
        return sh(['check_components']);
    },

    render: function(compOut) {
        var outputBox = E('pre', {
            id: 'comp-output',
            style: 'background:#111827;color:#34d399;padding:1rem;border-radius:8px;white-space:pre-wrap;font-family:monospace;font-size:12px;min-height:60px;margin-top:10px;'
        }, '');

        function out(msg) { outputBox.textContent += msg + '\n'; }

        function installPkg(pkg) {
            if (!confirm('确认安装 ' + pkg + '？')) return;
            out('>>> 开始安装 ' + pkg + ' ...');
            sh(['install_component', pkg]).then(function(res) {
                out(res);
                setTimeout(function() { location.reload(); }, 3000);
            });
        }

        function uninstallPkg(pkg) {
            if (!confirm('确认卸载 ' + pkg + '？')) return;
            out('>>> 开始卸载 ' + pkg + ' ...');
            sh(['uninstall_component', pkg]).then(function(res) {
                out(res);
                setTimeout(function() { location.reload(); }, 2000);
            });
        }

        // Parse components: "pkg|status|version" lines
        var rows = compOut.split('\n').filter(function(l) { return l.indexOf('|') >= 0; }).map(function(line) {
            var parts = line.split('|');
            var name = parts[0];
            var status = parts[1];
            var ver = parts[2] || '';

            var statusHtml = status === 'installed'
                ? E('span', { style: 'color:#16a34a;font-weight:bold;' }, '✅ 已安装' + (ver ? ' v' + ver : ''))
                : E('span', { style: 'color:#dc2626;font-weight:bold;' }, '❌ 未安装');

            var btn;
            if (status === 'installed') {
                btn = E('button', {
                    class: 'cbi-button cbi-button-remove',
                    click: function() { uninstallPkg(name); }
                }, '卸载');
                if (name === 'mosquitto') {
                    btn = E('span', {}, [btn, E('span', { style: 'color:#dc2626;font-size:12px;margin-left:6px;' }, '⚠️ 卸载将停止Broker')]);
                }
            } else {
                btn = E('button', {
                    class: 'cbi-button cbi-button-apply',
                    click: function() { installPkg(name); }
                }, '安装');
            }

            return E('tr', {}, [
                E('td', { style: 'border:1px solid #e5e7eb;padding:8px;' }, name),
                E('td', { style: 'border:1px solid #e5e7eb;padding:8px;' }, statusHtml),
                E('td', { style: 'border:1px solid #e5e7eb;padding:8px;' }, btn)
            ]);
        });

        return E('div', { 'class': 'cbi-map' }, [
            E('h2', {}, 'MQTT Manager - 组件管理'),
            E('div', { style: 'background:#fff;border:1px solid #e5e7eb;border-radius:8px;padding:1.25rem;margin-bottom:1rem;' }, [
                E('h3', {}, '组件安装状态'),
                E('table', { style: 'width:100%;border-collapse:collapse;margin:10px 0;' }, [
                    E('thead', {}, E('tr', {}, [
                        E('th', { style: 'border:1px solid #e5e7eb;padding:8px;text-align:left;background:#f9fafb;' }, '组件'),
                        E('th', { style: 'border:1px solid #e5e7eb;padding:8px;text-align:left;' }, '状态'),
                        E('th', { style: 'border:1px solid #e5e7eb;padding:8px;text-align:left;' }, '操作')
                    ])),
                    E('tbody', {}, rows.length ? rows : [E('tr', {}, E('td', { colspan: '3', style: 'text-align:center;color:#999;' }, '无数据'))])
                ]),
                E('p', { style: 'color:#666;font-size:13px;' }, '注: 组件安装使用系统包管理器 (apk/opkg)'),
                outputBox
            ])
        ]);
    }
});
