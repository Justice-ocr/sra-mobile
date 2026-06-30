import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/app_notification_service.dart';
import '../widgets/form_fields.dart';

/// 系统设置页：启动与识图 / 远程连接 / 通知 三个分区
class SettingsPageView extends StatefulWidget {
  const SettingsPageView({super.key});
  @override
  State<SettingsPageView> createState() => _SettingsPageViewState();
}

class _SettingsPageViewState extends State<SettingsPageView> {
  Map<String, dynamic>? _model;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // SMTP 授权码独立 draft（留空不修改）
  final _smtpAuthCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await context.read<TaskProvider>().api.getSettings();
    if (!mounted) return;
    setState(() {
      _model = raw == null ? null : _buildModel(raw);
      _loading = false;
    });
  }

  Map<String, dynamic> _buildModel(Map<String, dynamic> raw) {
    Map<String, dynamic> sec(String key, Map<String, dynamic> defaults) {
      final src = raw[key] is Map ? Map<String, dynamic>.from(raw[key] as Map) : <String, dynamic>{};
      return {...defaults, ...src};
    }

    return {
      ...raw,
      'general': sec('general', {
        'gamePath.index': 0, 'gamePath.uris': [], 'gamePath.autoDetect': true,
        'gameArgs.enabled': false, 'gameArgs.fullScreenMode': '窗口化',
        'gameArgs.windowSize': '1920x1080', 'gameArgs.popupWindow': false,
        'gameArgs.useCmd': false, 'keybindings.stop': 'F9',
        'ocrMatchConfidence': 0.7, 'templateMatchConfidence': 0.9,
      }),
      'advanced': sec('advanced', {
        'backend.launchArgs': '--inline', 'backend.remote.enabled': false,
        'backend.remote.baseUrl': 'http://localhost:5000',
        'webui.remote.enabled': false, 'webui.remote.autostart': false,
        'webui.remote.token': 'starrailassistant',
      }),
      'notification': sec('notification', {
        'enabled': false, 'system.enabled': false,
        'webhook.enabled': false, 'webhook.url': '',
        'bark.enabled': false, 'bark.ciphertext': '', 'bark.serverUrl': 'https://api.day.app',
        'bark.deviceKey': '', 'bark.group': 'StarRailAssistant', 'bark.icon': '',
        'bark.level': '', 'bark.sound': '',
        'dingTalk.enabled': false, 'dingTalk.secret': '', 'dingTalk.webhookUrl': '',
        'discord.enabled': false, 'discord.sendImage': false, 'discord.webhookUrl': '',
        'feishu.enabled': false, 'feishu.appId': '', 'feishu.appSecret': '',
        'feishu.receiveId': '', 'feishu.receiveIdType': '', 'feishu.webhookUrl': '',
        'oneBot.enabled': false, 'oneBot.sendImage': false, 'oneBot.groupId': '',
        'oneBot.token': '', 'oneBot.url': '', 'oneBot.userId': '',
        'serverChan.enabled': false, 'serverChan.sendKey': '',
        'telegram.enabled': false, 'telegram.proxyEnabled': false, 'telegram.sendImage': false,
        'telegram.apiBaseUrl': 'https://api.telegram.org', 'telegram.botToken': '',
        'telegram.chatId': '', 'telegram.proxyUrl': 'http://127.0.0.1:7890',
        'weCom.enabled': false, 'weCom.sendImage': false, 'weCom.webhookUrl': '',
        'xxtui.enabled': false, 'xxtui.apiKey': '', 'xxtui.channel': '', 'xxtui.source': '',
        'email.enabled': false, 'email.smtpServer': '', 'email.smtpPort': 465,
        'email.smtpSender': '', 'email.smtpReceiver': '',
      }),
    };
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    final body = jsonDecode(jsonEncode(_model)) as Map<String, dynamic>;
    // SMTP 授权码仅非空才写入
    if (_smtpAuthCtrl.text.isNotEmpty) {
      (body['notification'] as Map)['email.smtpAuthCode'] = _smtpAuthCtrl.text;
    }
    final ok = await context.read<TaskProvider>().api.saveSettings(body);
    if (!mounted) return;
    setState(() { _saving = false; _error = ok ? null : '保存失败'; });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存'), duration: Duration(seconds: 2)));
    }
  }

  @override
  void dispose() {
    _smtpAuthCtrl.dispose();
    super.dispose();
  }

  dynamic _get(String section, String key) => (_model![section] as Map)[key];
  void _set(String section, String key, dynamic value) {
    setState(() => (_model![section] as Map)[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (_loading) return const Center(child: CircularProgressIndicator(color: kPrimary));
    if (_model == null) return Center(child: Text('加载失败', style: TextStyle(color: onSurface)));

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
            child: Row(
              children: [
                Text('系统设置', style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFFF3366), fontSize: 12)),
                IconButton(onPressed: _load, icon: Icon(Icons.refresh, color: onSurface.withOpacity(0.5), size: 20)),
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '保存中...' : '保存', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          TabBar(
            labelColor: kPrimary,
            unselectedLabelColor: onSurface.withOpacity(0.5),
            indicatorColor: kPrimary,
            tabs: const [
              Tab(text: '启动与识图'),
              Tab(text: '远程连接'),
              Tab(text: '通知'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _generalTab(),
                _remoteTab(),
                _notificationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBody(List<Widget> children) =>
      ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: children);

  // ── 启动与识图 ──
  Widget _generalTab() {
    return _tabBody([
      GlassPanel(
        child: Column(
          children: [
            SwitchField(
              label: '自动检测游戏路径',
              value: _get('general', 'gamePath.autoDetect') == true,
              activeText: '开启', inactiveText: '关闭',
              onChanged: (v) => _set('general', 'gamePath.autoDetect', v),
            ),
            SwitchField(
              label: '启用启动参数',
              value: _get('general', 'gameArgs.enabled') == true,
              activeText: '开启', inactiveText: '关闭',
              onChanged: (v) => _set('general', 'gameArgs.enabled', v),
            ),
            TextFieldRow(
              label: '游戏路径列表（一行一个）',
              controller: TextEditingController(
                text: ((_get('general', 'gamePath.uris') as List?) ?? []).join('\n')),
              maxLines: 4,
              onChangedSync: (v) => (_model!['general'] as Map)['gamePath.uris'] =
                  v.split('\n').where((s) => s.trim().isNotEmpty).toList(),
            ),
            NumberField(
              label: '当前路径索引',
              value: (_get('general', 'gamePath.index') as num),
              min: 0, max: 99,
              onChanged: (v) => _set('general', 'gamePath.index', v.toInt()),
            ),
            SelectField<String>(
              label: '显示模式',
              value: _get('general', 'gameArgs.fullScreenMode')?.toString() ?? '窗口化',
              items: const [
                DropdownMenuItem(value: '窗口化', child: Text('窗口化')),
                DropdownMenuItem(value: '全屏', child: Text('全屏')),
              ],
              onChanged: (v) => _set('general', 'gameArgs.fullScreenMode', v ?? '窗口化'),
            ),
            TextFieldRow(
              label: '窗口大小',
              controller: TextEditingController(text: _get('general', 'gameArgs.windowSize')?.toString() ?? ''),
              hint: '1920x1080',
              onChangedSync: (v) => (_model!['general'] as Map)['gameArgs.windowSize'] = v,
            ),
            SwitchField(
              label: '无边框窗口',
              value: _get('general', 'gameArgs.popupWindow') == true,
              activeText: '开启', inactiveText: '关闭',
              onChanged: (v) => _set('general', 'gameArgs.popupWindow', v),
            ),
            SwitchField(
              label: '使用命令行启动',
              value: _get('general', 'gameArgs.useCmd') == true,
              activeText: '开启', inactiveText: '关闭',
              onChanged: (v) => _set('general', 'gameArgs.useCmd', v),
            ),
            SliderField(
              label: 'OCR 置信度',
              value: (_get('general', 'ocrMatchConfidence') as num).toDouble(),
              onChanged: (v) => _set('general', 'ocrMatchConfidence', double.parse(v.toStringAsFixed(2))),
            ),
            SliderField(
              label: '模板匹配置信度',
              value: (_get('general', 'templateMatchConfidence') as num).toDouble(),
              onChanged: (v) => _set('general', 'templateMatchConfidence', double.parse(v.toStringAsFixed(2))),
            ),
            TextFieldRow(
              label: '停止热键',
              controller: TextEditingController(text: _get('general', 'keybindings.stop')?.toString() ?? 'F9'),
              onChangedSync: (v) => (_model!['general'] as Map)['keybindings.stop'] = v,
            ),
          ],
        ),
      ),
    ]);
  }

  // ── 远程连接 ──
  Widget _remoteTab() {
    return _tabBody([
      GlassPanel(
        child: Column(
          children: [
            TextFieldRow(
              label: 'WebUI 访问令牌',
              controller: TextEditingController(text: _get('advanced', 'webui.remote.token')?.toString() ?? ''),
              hint: 'starrailassistant',
              obscure: true,
              onChangedSync: (v) => (_model!['advanced'] as Map)['webui.remote.token'] = v,
            ),
            SwitchField(
              label: 'WebUI 服务状态记录',
              value: _get('advanced', 'webui.remote.enabled') == true,
              activeText: '开启', inactiveText: '关闭',
              onChanged: (v) => _set('advanced', 'webui.remote.enabled', v),
            ),
            SwitchField(
              label: 'WebUI 自启动记录',
              value: _get('advanced', 'webui.remote.autostart') == true,
              activeText: '开启', inactiveText: '关闭',
              onChanged: (v) => _set('advanced', 'webui.remote.autostart', v),
            ),
            SwitchField(
              label: '外部 SRA 后端',
              value: _get('advanced', 'backend.remote.enabled') == true,
              activeText: '使用', inactiveText: '本机',
              onChanged: (v) => _set('advanced', 'backend.remote.enabled', v),
            ),
            TextFieldRow(
              label: '外部 SRA 后端地址',
              controller: TextEditingController(text: _get('advanced', 'backend.remote.baseUrl')?.toString() ?? ''),
              hint: 'http://localhost:5000',
              onChangedSync: (v) => (_model!['advanced'] as Map)['backend.remote.baseUrl'] = v,
            ),
            TextFieldRow(
              label: '后端启动参数',
              controller: TextEditingController(text: _get('advanced', 'backend.launchArgs')?.toString() ?? ''),
              hint: '--inline',
              onChangedSync: (v) => (_model!['advanced'] as Map)['backend.launchArgs'] = v,
            ),
          ],
        ),
      ),
    ]);
  }

  // ── 通知 ──
  Widget _notificationTab() {
    return _tabBody([
      // App 本地通知（纯 app 端，不依赖 SRA 本体）
      GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_android, color: kPrimary, size: 18),
                const SizedBox(width: 8),
                Text('App 应用通知',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 2),
            Text('任务完成时在手机弹出系统通知（仅本机，不修改 SRA 设置）。',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
            SwitchField(
              label: '启用 App 通知',
              value: AppNotificationService.instance.enabled,
              activeText: '开启', inactiveText: '关闭',
              onChanged: (v) async {
                await AppNotificationService.instance.setEnabled(v);
                setState(() {});
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side: const BorderSide(color: kPrimary),
                ),
                onPressed: () async {
                  await AppNotificationService.instance.showTest();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已发送测试通知'), duration: Duration(seconds: 2)));
                  }
                },
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: const Text('发送测试通知'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      GlassPanel(
        child: Column(
          children: [
            SwitchField(
              label: '启用通知',
              value: _get('notification', 'enabled') == true,
              activeText: '开启', inactiveText: '关闭',
              onChanged: (v) => _set('notification', 'enabled', v),
            ),
            SwitchField(
              label: '系统通知',
              value: _get('notification', 'system.enabled') == true,
              activeText: '开启', inactiveText: '关闭',
              onChanged: (v) => _set('notification', 'system.enabled', v),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      _channelTile('Webhook', 'webhook.enabled', [
        _txt('Webhook URL', 'webhook.url'),
      ]),
      _channelTile('Bark', 'bark.enabled', [
        _txt('Server URL', 'bark.serverUrl'),
        _txt('Device Key', 'bark.deviceKey', sensitive: true),
        _txt('分组', 'bark.group'),
        _txt('铃声', 'bark.sound'),
        _txt('等级', 'bark.level'),
        _txt('图标 URL', 'bark.icon'),
        _txt('密文', 'bark.ciphertext', sensitive: true),
      ]),
      _channelTile('钉钉', 'dingTalk.enabled', [
        _txt('Webhook URL', 'dingTalk.webhookUrl'),
        _txt('Secret', 'dingTalk.secret', sensitive: true),
      ]),
      _channelTile('Discord', 'discord.enabled', [
        _sw('发送图片', 'discord.sendImage'),
        _txt('Webhook URL', 'discord.webhookUrl'),
      ]),
      _channelTile('飞书', 'feishu.enabled', [
        _txt('Webhook URL', 'feishu.webhookUrl'),
        _txt('App ID', 'feishu.appId'),
        _txt('App Secret', 'feishu.appSecret', sensitive: true),
        _txt('Receive ID', 'feishu.receiveId'),
        _txt('Receive ID Type', 'feishu.receiveIdType'),
      ]),
      _channelTile('OneBot', 'oneBot.enabled', [
        _sw('发送图片', 'oneBot.sendImage'),
        _txt('服务地址', 'oneBot.url'),
        _txt('Token', 'oneBot.token', sensitive: true),
        _txt('用户 ID', 'oneBot.userId'),
        _txt('群 ID', 'oneBot.groupId'),
      ]),
      _channelTile('Server 酱', 'serverChan.enabled', [
        _txt('SendKey', 'serverChan.sendKey', sensitive: true),
      ]),
      _channelTile('Telegram', 'telegram.enabled', [
        _sw('发送图片', 'telegram.sendImage'),
        _sw('使用代理', 'telegram.proxyEnabled'),
        _txt('API Base URL', 'telegram.apiBaseUrl'),
        _txt('Bot Token', 'telegram.botToken', sensitive: true),
        _txt('Chat ID', 'telegram.chatId'),
        _txt('代理地址', 'telegram.proxyUrl'),
      ]),
      _channelTile('企业微信', 'weCom.enabled', [
        _sw('发送图片', 'weCom.sendImage'),
        _txt('Webhook URL', 'weCom.webhookUrl'),
      ]),
      _channelTile('息息推', 'xxtui.enabled', [
        _txt('API Key', 'xxtui.apiKey', sensitive: true),
        _txt('频道', 'xxtui.channel'),
        _txt('来源', 'xxtui.source'),
      ]),
      _channelTile('邮件', 'email.enabled', [
        _txt('SMTP 服务器', 'email.smtpServer'),
        NumberField(
          label: 'SMTP 端口',
          value: (_get('notification', 'email.smtpPort') as num),
          min: 1, max: 65535,
          onChanged: (v) => _set('notification', 'email.smtpPort', v.toInt()),
        ),
        _txt('发件人', 'email.smtpSender'),
        _txt('收件人', 'email.smtpReceiver'),
        TextFieldRow(label: 'SMTP 授权码', controller: _smtpAuthCtrl,
            hint: '留空则不修改已有授权码', obscure: true),
      ]),
    ]);
  }

  // 通知渠道折叠项
  Widget _channelTile(String title, String enableKey, List<Widget> children) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final enabled = _get('notification', enableKey) == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: enabled ? const Color(0xFF10B981) : onSurface.withOpacity(0.25),
                  ),
                ),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            children: [
              SwitchField(
                label: title,
                value: enabled,
                activeText: '开启', inactiveText: '关闭',
                onChanged: (v) => _set('notification', enableKey, v),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _txt(String label, String key, {bool sensitive = false}) {
    return TextFieldRow(
      label: label,
      controller: TextEditingController(text: _get('notification', key)?.toString() ?? ''),
      obscure: sensitive,
      onChangedSync: (v) => (_model!['notification'] as Map)[key] = v,
    );
  }

  Widget _sw(String label, String key) {
    return SwitchField(
      label: label,
      value: _get('notification', key) == true,
      activeText: '开启', inactiveText: '关闭',
      onChanged: (v) => _set('notification', key, v),
    );
  }
}
