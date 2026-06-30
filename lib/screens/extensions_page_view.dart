import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/task_provider.dart';
import '../widgets/form_fields.dart';

/// 拓展页：自动对话 + 抽卡资源预测
class ExtensionsPageView extends StatefulWidget {
  const ExtensionsPageView({super.key});
  @override
  State<ExtensionsPageView> createState() => _ExtensionsPageViewState();
}

class _ExtensionsPageViewState extends State<ExtensionsPageView> {
  // 自动对话本地状态
  bool _autoPlotEnabled = false;
  bool _skipPlot = false;
  bool _applyingPlot = false;

  // 抽卡预测：来自 settings.warpForecast
  Map<String, dynamic>? _warp;
  bool _loading = true;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await context.read<TaskProvider>().api.getSettings();
    if (!mounted) return;
    setState(() {
      final wf = raw?['warpForecast'];
      _warp = wf is Map ? _buildWarp(Map<String, dynamic>.from(wf)) : _buildWarp({});
      _loading = false;
    });
  }

  Map<String, dynamic> _buildWarp(Map<String, dynamic> src) {
    return {
      'version.startDate': '', 'version.days': 42, 'monthlyCard.enabled': false,
      'version.compensationJade': 600, 'scan.bag': true, 'scan.eventGuide': true,
      'manual.currentJade': 0, 'manual.specialPass': 0, 'manual.normalPass': 0,
      'endgame.refreshCountOverride': -1, 'weekly.countOverride': -1,
      ...src,
    };
  }

  Future<void> _applyAutoPlot() async {
    setState(() => _applyingPlot = true);
    final ok = await context.read<TaskProvider>().api.saveAutoPlot(_autoPlotEnabled, _skipPlot);
    if (!mounted) return;
    setState(() => _applyingPlot = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '自动对话设置已应用' : '应用失败'), duration: const Duration(seconds: 2)));
  }

  Future<void> _runForecast() async {
    setState(() => _running = true);
    final api = context.read<TaskProvider>().api;
    // 先保存当前 warpForecast，再运行
    final current = await api.getSettings();
    if (current != null) {
      current['warpForecast'] = jsonDecode(jsonEncode(_warp));
      await api.saveSettings(current);
    }
    final ok = await api.runWarpForecast();
    if (!mounted) return;
    setState(() => _running = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '抽卡资源预测已启动' : '启动失败'), duration: const Duration(seconds: 2)));
  }

  void _setWarp(String key, dynamic value) => setState(() => _warp![key] = value);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Text('SRA 拓展', style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('围绕常用拓展做成可直达的控制区。',
            style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 16),

        // 卡片一：自动对话
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.forum_outlined, color: kPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text('自动对话', style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text('通过 SRA-cli trigger 控制。适合临时开启剧情自动处理，改动会直接写入后端设置。',
                  style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
              const SizedBox(height: 8),
              SwitchField(
                label: '自动对话',
                value: _autoPlotEnabled,
                activeText: '启用', inactiveText: '关闭',
                onChanged: (v) => setState(() => _autoPlotEnabled = v),
              ),
              SwitchField(
                label: '跳过剧情',
                value: _skipPlot,
                activeText: '跳过', inactiveText: '保留',
                onChanged: (v) => setState(() => _skipPlot = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                  onPressed: _applyingPlot ? null : _applyAutoPlot,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(_applyingPlot ? '应用中...' : '应用自动对话'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 卡片二：猫猫糕友人帐
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pets_outlined, color: kPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text('猫猫糕友人帐', style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text('查询对应猫猫糕 UID。',
                  style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    side: const BorderSide(color: kPrimary),
                  ),
                  onPressed: () => launchUrl(
                    Uri.parse('https://catcake.hoshimi.io/'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('寻找猫猫糕'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 卡片三：抽卡资源预测
        if (_loading)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: kPrimary)))
        else if (_warp != null)
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined, color: kPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text('抽卡资源预测', style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('配置预测参数并可直接运行。',
                    style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
                const Divider(height: 24),

                _subTitle('版本'),
                TextFieldRow(
                  label: '版本起始日期',
                  controller: TextEditingController(text: _warp!['version.startDate']?.toString() ?? ''),
                  hint: 'YYYY-MM-DD',
                  onChangedSync: (v) => _warp!['version.startDate'] = v,
                ),
                NumberField(label: '版本天数', value: _warp!['version.days'] as num, min: 1, max: 999,
                    onChanged: (v) => _setWarp('version.days', v.toInt())),
                NumberField(label: '版本补偿星琼', value: _warp!['version.compensationJade'] as num, min: 0, max: 99999,
                    onChanged: (v) => _setWarp('version.compensationJade', v.toInt())),

                const SizedBox(height: 8),
                _subTitle('扫描'),
                SwitchField(label: '小月卡', value: _warp!['monthlyCard.enabled'] == true,
                    activeText: '持有', inactiveText: '未持有',
                    onChanged: (v) => _setWarp('monthlyCard.enabled', v)),
                SwitchField(label: '背包扫描', value: _warp!['scan.bag'] == true,
                    onChanged: (v) => _setWarp('scan.bag', v)),
                SwitchField(label: '奖励指南扫描', value: _warp!['scan.eventGuide'] == true,
                    onChanged: (v) => _setWarp('scan.eventGuide', v)),

                const SizedBox(height: 8),
                _subTitle('手动数量与覆写'),
                NumberField(label: '当前星琼', value: _warp!['manual.currentJade'] as num, min: 0, max: 999999,
                    onChanged: (v) => _setWarp('manual.currentJade', v.toInt())),
                NumberField(label: '星轨专票', value: _warp!['manual.specialPass'] as num, min: 0, max: 99999,
                    onChanged: (v) => _setWarp('manual.specialPass', v.toInt())),
                NumberField(label: '星轨通票', value: _warp!['manual.normalPass'] as num, min: 0, max: 99999,
                    onChanged: (v) => _setWarp('manual.normalPass', v.toInt())),
                NumberField(label: '深渊刷新次数覆写', value: _warp!['endgame.refreshCountOverride'] as num, min: -1, max: 99,
                    onChanged: (v) => _setWarp('endgame.refreshCountOverride', v.toInt())),
                NumberField(label: '周常次数覆写', value: _warp!['weekly.countOverride'] as num, min: -1, max: 99,
                    onChanged: (v) => _setWarp('weekly.countOverride', v.toInt())),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                    onPressed: _running ? null : _runForecast,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(_running ? '运行中...' : '运行预测'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _subTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Text(text, style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}
