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
        return sh(['list_users']);
    },

    render: function(usersOut) {
        var outputBox = E('pre', {
            id: 'user-output',
            style: 'background:#111827;color:#34d399;padding:1rem;border-radius:8px;white-space:pre-wrap;font-family:monospace;font-size:12px;min-height:60px;margin-top:10px;'
        }, '');

        function out(msg) { outputBox.textContent += msg + '\n'; }

        function addUser() {
            var u = document.getElementById('new-username').value.trim();
            var p = document.getElementById('new-password').value;
            if (!u || !p) { ui.addNotification(null, E('p', {}, '用户名和密码不能为空')); return; }
            out('>>> 添加用户 ' + u + ' ...');
            sh(['add_user', u, p]).then(function(res) {
                out(res);
                setTimeout(function() { location.reload(); }, 1000);
            });
        }

        function delUser(u) {
            if (!confirm('确认删除用户 ' + u + '？')) return;
            out('>>> 删除用户 ' + u + ' ...');
            sh(['del_user', u]).then(function(res) {
                out(res);
                setTimeout(function() { location.reload(); }, 1000);
            });
        }

        var userRows = usersOut.split('\n').filter(function(u) { return u.trim(); }).map(function(u) {
            return E('tr', {}, [
                E('td', {}, u),
                E('td', {}, E('button', {
                    class: 'cbi-button cbi-button-remove',
                    click: function() { delUser(u); }
                }, '删除'))
            ]);
        });

        return E('div', { 'class': 'cbi-map' }, [
            E('h2', {}, 'MQTT Manager - 用户管理'),
            E('div', { style: 'background:#fff;border:1px solid #e5e7eb;border-radius:8px;padding:1.25rem;margin-bottom:1rem;' }, [
                E('h3', {}, '用户列表'),
                E('table', { style: 'width:100%;border-collapse:collapse;margin:10px 0;' }, [
                    E('thead', {}, E('tr', {}, [
                        E('th', { style: 'border:1px solid #e5e7eb;padding:8px;text-align:left;background:#f9fafb;' }, '用户名'),
                        E('th', { style: 'border:1px solid #e5e7eb;padding:8px;text-align:left;' }, '操作')
                    ])),
                    E('tbody', {}, userRows.length ? userRows : [E('tr', {}, E('td', { colspan: '2', style: 'text-align:center;color:#999;' }, '暂无用户'))])
                ]),
                E('div', { style: 'margin-top:12px;padding:12px;background:#f9fafb;border-radius:6px;' }, [
                    E('h4', {}, '添加用户'),
                    E('input', { id: 'new-username', placeholder: '用户名', style: 'padding:6px 10px;border:1px solid #d1d5db;border-radius:6px;margin-right:8px;' }),
                    E('input', { id: 'new-password', type: 'password', placeholder: '密码', style: 'padding:6px 10px;border:1px solid #d1d5db;border-radius:6px;margin-right:8px;' }),
                    E('button', { class: 'cbi-button cbi-button-apply', click: addUser }, '添加')
                ]),
                outputBox
            ])
        ]);
    }
});
