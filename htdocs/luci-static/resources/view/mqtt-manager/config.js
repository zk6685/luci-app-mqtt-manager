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

function sh(args) {
    return callRpc(JSON.stringify(args)).then(function(res) {
        return (res && res.result !== undefined) ? res.result : '';
    });
}

return view.extend({
    load: function() {
        return Promise.all([
            sh(['conf_read']),
            sh(['tls_status'])
        ]);
    },

    render: function(data) {
        var confOut = data[0];
        var tlsOut = data[1];

        var outputBox = E('pre', {
            id: 'cfg-output',
            style: 'background:#111827;color:#34d399;padding:1rem;border-radius:8px;white-space:pre-wrap;font-family:monospace;font-size:13px;min-height:100px;margin-top:10px;'
        }, '');

        function out(msg) { outputBox.textContent += msg + '\n'; }

        function applyKey() {
            var port = document.getElementById('cfg-port').value;
            var anon = document.getElementById('cfg-anon').value;
            var passfile = document.getElementById('cfg-passfile').value;
            var persist = document.getElementById('cfg-persist').value;
            var logdest = document.getElementById('cfg-logdest').value;

            out('>>> 保存关键配置...');
            sh(['conf_set', 'listener', port]).then(function() {
                return sh(['conf_set', 'allow_anonymous', anon]);
            }).then(function() {
                return sh(['conf_set', 'password_file', passfile]);
            }).then(function() {
                return sh(['conf_set', 'persistence', persist]);
            }).then(function() {
                return sh(['conf_set', 'log_dest', logdest]);
            }).then(function() {
                out('>>> 应用并重启...');
                return sh(['conf_apply']);
            }).then(function(res) {
                out(res);
            });
        }

        function uploadTls() {
            var certFile = document.getElementById('tls-cert').files[0];
            var keyFile = document.getElementById('tls-key').files[0];
            if (!certFile && !keyFile) { ui.addNotification(null, E('p', {}, '请先选择文件')); return; }

            out('>>> 上传证书...');
            var p = Promise.resolve();
            if (certFile) {
                p = p.then(function() {
                    return certFile.text().then(function(txt) {
                        return sh(['tls_save', 'cert.pem', txt]);
                    });
                });
            }
            if (keyFile) {
                p = p.then(function() {
                    return keyFile.text().then(function(txt) {
                        return sh(['tls_save', 'privkey.pem', txt]);
                    });
                });
            }
            p.then(function() { out('>>> 证书上传完成'); });
        }

        return E('div', { 'class': 'cbi-map' }, [
            E('h2', {}, 'MQTT Manager - 基础配置'),
            E('div', { style: 'background:#fff;border:1px solid #e5e7eb;border-radius:8px;padding:1.25rem;margin-bottom:1rem;' }, [
                E('h3', {}, '配置文件'),
                E('p', { style: 'color:#666;font-size:13px;white-space:pre-wrap;' }, confOut),
                E('button', {
                    class: 'cbi-button cbi-button-apply',
                    click: function() { out('>>> 重新读取配置...'); sh(['conf_read']).then(function(res) { outputBox.textContent = res; }); }
                }, '读取配置')
            ]),
            E('div', { style: 'background:#fff;border:1px solid #e5e7eb;border-radius:8px;padding:1.25rem;margin-bottom:1rem;' }, [
                E('h3', {}, '关键配置项'),
                E('div', { style: 'margin:8px 0;' }, [
                    E('label', { style: 'display:inline-block;width:130px;' }, '监听端口: '),
                    E('input', { id: 'cfg-port', placeholder: '1883', style: 'padding:6px 10px;border:1px solid #d1d5db;border-radius:6px;width:260px;' })
                ]),
                E('div', { style: 'margin:8px 0;' }, [
                    E('label', { style: 'display:inline-block;width:130px;' }, '允许匿名: '),
                    E('select', { id: 'cfg-anon', style: 'padding:6px 10px;border:1px solid #d1d5db;border-radius:6px;width:260px;' }, [
                        E('option', { value: 'false' }, 'false - 禁止匿名'),
                        E('option', { value: 'true' }, 'true - 允许匿名')
                    ])
                ]),
                E('div', { style: 'margin:8px 0;' }, [
                    E('label', { style: 'display:inline-block;width:130px;' }, '密码文件: '),
                    E('input', { id: 'cfg-passfile', placeholder: '/etc/mosquitto/passwd', style: 'padding:6px 10px;border:1px solid #d1d5db;border-radius:6px;width:260px;' })
                ]),
                E('div', { style: 'margin:8px 0;' }, [
                    E('label', { style: 'display:inline-block;width:130px;' }, '持久化: '),
                    E('select', { id: 'cfg-persist', style: 'padding:6px 10px;border:1px solid #d1d5db;border-radius:6px;width:260px;' }, [
                        E('option', { value: 'false' }, 'false - 关闭'),
                        E('option', { value: 'true' }, 'true - 开启')
                    ])
                ]),
                E('div', { style: 'margin:8px 0;' }, [
                    E('label', { style: 'display:inline-block;width:130px;' }, '日志输出: '),
                    E('select', { id: 'cfg-logdest', style: 'padding:6px 10px;border:1px solid #d1d5db;border-radius:6px;width:260px;' }, [
                        E('option', { value: 'syslog' }, '系统日志'),
                        E('option', { value: 'stdout' }, '标准输出')
                    ])
                ]),
                E('button', {
                    class: 'cbi-button cbi-button-apply',
                    style: 'margin-top:8px;',
                    click: applyKey
                }, '保存关键配置'),
                outputBox
            ]),
            E('div', { style: 'background:#fff;border:1px solid #e5e7eb;border-radius:8px;padding:1.25rem;margin-bottom:1rem;' }, [
                E('h3', {}, 'TLS 证书（8883端口）'),
                E('p', { style: 'color:#666;font-size:13px;' }, '证书目录: /etc/mosquitto/cert/'),
                E('p', { style: 'color:#d97706;' }, tlsOut),
                E('div', { style: 'margin-top:12px;padding:12px;background:#f9fafb;border-radius:6px;' }, [
                    E('p', { style: 'margin:0 0 8px;font-size:13px;color:#374151;' }, '上传证书文件（PEM 格式）:'),
                    E('label', { style: 'font-size:13px;color:#374151;' }, 'cert.pem: '),
                    E('input', { id: 'tls-cert', type: 'file', accept: '.pem,.crt,.cer', style: 'font-size:12px;' }),
                    E('br', {}), E('br', {}),
                    E('label', { style: 'font-size:13px;color:#374151;' }, 'privkey.pem: '),
                    E('input', { id: 'tls-key', type: 'file', accept: '.pem,.key', style: 'font-size:12px;' }),
                    E('br', {}), E('br', {}),
                    E('button', {
                        class: 'cbi-button cbi-button-apply',
                        click: uploadTls
                    }, '上传证书')
                ])
            ])
        ]);
    }
});
