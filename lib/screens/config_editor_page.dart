import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/form_fields.dart';

// 锄大地奖励项标签（索引对应 rewards 数组）
const _rewardLabels = ['漫游签证', '派遣', '邮件', '每日实训', '无名勋礼', '巡星之礼', '兑换码'];

class ConfigEditorPage extends StatefulWidget {
  final String configName;
  const ConfigEditorPage({super.key, required this.configName});

  @override
  State<ConfigEditorPage> createState() => _ConfigEditorPageState();
}

class _ConfigEditorPageState extends State<ConfigEditorPage> {
  Map<String, dynamic>? _model;
  List<dynamic> _taskDefs = []; // 副本定义
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // 凭据独立管理（不进 model，留空保留已有）
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<TaskProvider>().api;
    final results = await Future.wait([
      api.getConfig(widget.configName),
      api.getTaskDefinitions(),
    ]);
    if (!mounted) return;
    final raw = results[0] as Map<String, dynamic>?;
    setState(() {
      _model = raw == null ? null : _buildModel(raw);
      _taskDefs = results[1] as List<dynamic>;
      _loading = false;
    });
  }

  // 用默认值补全模型（参考 createConfigModel）
  Map<String, dynamic> _buildModel(Map<String, dynamic> raw) {
    Map<String, dynamic> sec(String key, Map<String, dynamic> defaults) {
      final src = raw[key] is Map ? Map<String, dynamic>.from(raw[key] as Map) : <String, dynamic>{};
      return {...defaults, ...src};
    }

    final model = <String, dynamic>{
      'name': raw['name']?.toString() ?? widget.configName,
      'startGame': sec('startGame', {
        'enabled': true, 'game.channel': 0, 'game.path': '',
        'game.useGlobalPath': true, 'autologin': true, 'relogin': true,
      }),
      'trailblazePower': sec('trailblazePower', {
        'enabled': false, 'replenish.enabled': false, 'replenish.times': 0,
        'replenish.way': 0, 'useAssistant': false, 'useBuildTarget': false,
        'tasklist': [], 'activity.enabled': false,
        'activity.gardenOfPlenty.level1': 0, 'activity.gardenOfPlenty.level2': 0,
        'activity.planarFissure.level': 0, 'activity.realmOfTheStrange.level': 0,
      }),
      'receiveRewards': sec('receiveRewards', {
        'enabled': false, 'redeemCodes': '',
        'rewards': [true, true, true, true, true, true, false],
      }),
      'cosmicStrife': sec('cosmicStrife', {
        'enabled': false, 'pointRewards.enabled': false,
        'divergentUniverse.enabled': false, 'divergentUniverse.mode': 0,
        'divergentUniverse.runtimes': 1, 'divergentUniverse.useTechnique': false,
        'currencyWars.enabled': false, 'currencyWars.mode': 0,
        'currencyWars.difficulty': 0, 'currencyWars.reroll.bossAffixes': '',
        'currencyWars.reroll.bossNames': '', 'currencyWars.reroll.investEnvironments': '',
        'currencyWars.reroll.investStrategies': '', 'currencyWars.runtimes': 1,
        'currencyWars.strategy': 'template', 'currencyWars.strategyIndex': 0,
        'currencyWars.username': '',
      }),
      'missionAccomplished': sec('missionAccomplished', {
        'enabled': false, 'exitApp': false, 'exitGame': false,
        'logout': false, 'shutdown': false, 'sleep': false,
      }),
      'version': raw['version'] ?? 4,
    };
    // 凭据剥离
    (model['startGame'] as Map).remove('username');
    (model['startGame'] as Map).remove('password');
    // 规整 rewards 长度 7
    final rw = model['receiveRewards']['rewards'];
    final list = rw is List ? rw : [];
    model['receiveRewards']['rewards'] =
        List.generate(7, (i) => i < list.length ? list[i] == true : false);
    return model;
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    final body = jsonDecode(jsonEncode(_model)) as Map<String, dynamic>;
    // 注入凭据：仅非空才写入
    final sg = body['startGame'] as Map;
    sg.remove('username');
    sg.remove('password');
    if (_usernameCtrl.text.trim().isNotEmpty) sg['username'] = _usernameCtrl.text.trim();
    if (_passwordCtrl.text.isNotEmpty) sg['password'] = _passwordCtrl.text;

    final ok = await context.read<TaskProvider>().api.saveConfig(widget.configName, body);
    if (!mounted) return;
    setState(() { _saving = false; _error = ok ? null : '保存失败'; });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存'), duration: Duration(seconds: 2)));
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(widget.configName, style: TextStyle(color: onSurface)),
        leading: BackButton(color: onSurface),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中...' : '保存配置', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _model == null
              ? Center(child: Text('加载失败', style: TextStyle(color: onSurface)))
              : DefaultTabController(
                  length: 5,
                  child: Column(
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_error!, style: const TextStyle(color: Color(0xFFFF3366))),
                        ),
                      TabBar(
                        isScrollable: true,
                        labelColor: kPrimary,
                        unselectedLabelColor: onSurface.withOpacity(0.5),
                        indicatorColor: kPrimary,
                        tabAlignment: TabAlignment.start,
                        tabs: const [
                          Tab(text: '启动游戏'),
                          Tab(text: '清体力'),
                          Tab(text: '领取奖励'),
                          Tab(text: '旷宇纷争'),
                          Tab(text: '完成后'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _startGameTab(),
                            _powerTab(),
                            _rewardsTab(),
                            _cosmicTab(),
                            _finishTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ── 工具：读写嵌套 section 字段 ──
  dynamic _get(String section, String key) => (_model![section] as Map)[key];
  void _set(String section, String key, dynamic value) {
    setState(() => (_model![section] as Map)[key] = value);
  }

  Widget _tabBody(List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: children,
    );
  }

  // ── 1. 启动游戏 ──
  Widget _startGameTab() {
    final useGlobal = _get('startGame', 'game.useGlobalPath') == true;
    return _tabBody([
      GlassPanel(
        child: Column(
          children: [
            SectionHeader(
              title: '启动游戏',
              subtitle: '配置渠道、路径与登录行为。',
              enabled: _get('startGame', 'enabled') == true,
              onEnabledChanged: (v) => _set('startGame', 'enabled', v),
            ),
            const Divider(height: 24),
            SelectField<int>(
              label: '渠道',
              value: (_get('startGame', 'game.channel') as num).toInt(),
              items: const [
                DropdownMenuItem(value: 0, child: Text('官服')),
                DropdownMenuItem(value: 1, child: Text('B服')),
                DropdownMenuItem(value: 2, child: Text('国际服')),
              ],
              onChanged: (v) => _set('startGame', 'game.channel', v ?? 0),
            ),
            TextFieldRow(
              label: '游戏路径',
              controller: TextEditingController(text: _get('startGame', 'game.path')?.toString() ?? ''),
              hint: '使用全局路径时会忽略此项',
              enabled: !useGlobal,
              onChangedSync: (v) => (_model!['startGame'] as Map)['game.path'] = v,
            ),
            SwitchField(
              label: '路径来源',
              value: useGlobal,
              activeText: '使用全局路径',
              inactiveText: '单独配置',
              onChanged: (v) => _set('startGame', 'game.useGlobalPath', v),
            ),
            SwitchField(
              label: '自动登录',
              value: _get('startGame', 'autologin') == true,
              onChanged: (v) => _set('startGame', 'autologin', v),
            ),
            SwitchField(
              label: '重新登录',
              value: _get('startGame', 'relogin') == true,
              activeText: '总是重新登录',
              inactiveText: '保持现状',
              onChanged: (v) => _set('startGame', 'relogin', v),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('账号凭据', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('留空则保留已保存的账号密码',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
            TextFieldRow(label: '账号', controller: _usernameCtrl, hint: '留空则保留已保存账号'),
            TextFieldRow(label: '密码', controller: _passwordCtrl, hint: '留空则保留已保存密码', obscure: true),
          ],
        ),
      ),
    ]);
  }

  // ── 2. 清体力 ──
  Widget _powerTab() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final tasklist = (_get('trailblazePower', 'tasklist') as List?) ?? [];
    return _tabBody([
      GlassPanel(
        child: SectionHeader(
          title: '清体力',
          subtitle: '任务清单来自 SRA 内部设置项，避免手填 ID 出错。',
          enabled: _get('trailblazePower', 'enabled') == true,
          onEnabledChanged: (v) => _set('trailblazePower', 'enabled', v),
        ),
      ),
      const SizedBox(height: 12),
      // 任务清单
      GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('任务清单', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${tasklist.length} 个任务', style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            if (tasklist.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('还没有任务。点击下方添加。',
                    style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 13)),
              )
            else
              ...tasklist.asMap().entries.map((e) => _powerRow(e.key, e.value as Map)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _taskDefs.isEmpty ? null : _showAddTaskSheet,
                icon: const Icon(Icons.add, color: kPrimary, size: 20),
                label: Text(_taskDefs.isEmpty ? '等待副本定义...' : '添加任务',
                    style: const TextStyle(color: kPrimary)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      // 通用设置
      GlassPanel(
        child: Column(
          children: [
            SwitchField(
              label: '补充体力',
              value: _get('trailblazePower', 'replenish.enabled') == true,
              onChanged: (v) => _set('trailblazePower', 'replenish.enabled', v),
            ),
            SelectField<int>(
              label: '补充方式',
              value: (_get('trailblazePower', 'replenish.way') as num).toInt(),
              items: const [
                DropdownMenuItem(value: 0, child: Text('后备开拓力')),
                DropdownMenuItem(value: 1, child: Text('燃料')),
                DropdownMenuItem(value: 2, child: Text('星琼')),
              ],
              onChanged: (v) => _set('trailblazePower', 'replenish.way', v ?? 0),
            ),
            NumberField(
              label: '补充次数',
              value: (_get('trailblazePower', 'replenish.times') as num),
              min: 0, max: 99,
              onChanged: (v) => _set('trailblazePower', 'replenish.times', v.toInt()),
            ),
            SwitchField(
              label: '支援角色',
              value: _get('trailblazePower', 'useAssistant') == true,
              activeText: '使用', inactiveText: '不使用',
              onChanged: (v) => _set('trailblazePower', 'useAssistant', v),
            ),
            SwitchField(
              label: '培养目标',
              value: _get('trailblazePower', 'useBuildTarget') == true,
              activeText: '优先完成', inactiveText: '关闭',
              onChanged: (v) => _set('trailblazePower', 'useBuildTarget', v),
            ),
            SwitchField(
              label: '多倍活动检测',
              value: _get('trailblazePower', 'activity.enabled') == true,
              onChanged: (v) => _set('trailblazePower', 'activity.enabled', v),
            ),
            _levelSelect('花萼繁生：金', 'activity.gardenOfPlenty.level1', 1),
            _levelSelect('花萼繁生：赤', 'activity.gardenOfPlenty.level2', 2),
            _levelSelect('侵蚀隧洞', 'activity.realmOfTheStrange.level', 4),
            _levelSelect('饰品提取', 'activity.planarFissure.level', 0),
          ],
        ),
      ),
    ]);
  }

  // 活动关卡下拉（按副本 index 取 levels）
  Widget _levelSelect(String label, String key, int taskIndex) {
    final levels = _levelsForTask(taskIndex);
    final current = (_get('trailblazePower', key) as num?)?.toInt() ?? 0;
    return SelectField<int>(
      label: label,
      value: current,
      items: levels.map((lv) {
        final idx = (lv['index'] as num?)?.toInt() ?? 0;
        return DropdownMenuItem(value: idx, child: Text(lv['name']?.toString() ?? '$idx'));
      }).toList(),
      onChanged: (v) => _set('trailblazePower', key, v ?? 0),
    );
  }

  List<Map> _levelsForTask(int taskIndex) {
    final def = _taskDefs.cast<Map?>().firstWhere(
      (d) => (d?['index'] as num?)?.toInt() == taskIndex,
      orElse: () => null,
    );
    if (def == null) return [{'index': 0, 'name': '默认'}];
    final levels = (def['levels'] as List?) ?? [];
    if (levels.isEmpty) return [{'index': 0, 'name': '默认'}];
    return levels.cast<Map>();
  }

  Widget _powerRow(int index, Map item) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name']?.toString() ?? '未命名',
                    style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
                Text('${item['levelName'] ?? ''} · 单次${item['count'] ?? 1} · 运行${item['runtimes'] ?? 0}',
                    style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3366), size: 20),
            onPressed: () => setState(() {
              (_get('trailblazePower', 'tasklist') as List).removeAt(index);
            }),
          ),
        ],
      ),
    );
  }

  void _showAddTaskSheet() {
    int taskIndex = (_taskDefs.first as Map)['index'] as int? ?? 0;
    int levelIndex = 0;
    int count = 1;
    int runtimes = 0;
    bool autoDetect = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final onSurface = Theme.of(ctx).colorScheme.onSurface;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final levels = _levelsForTask(taskIndex);
            // 确保 levelIndex 有效
            if (!levels.any((l) => (l['index'] as num?)?.toInt() == levelIndex)) {
              levelIndex = (levels.first['index'] as num?)?.toInt() ?? 0;
            }
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('添加任务', style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                  SelectField<int>(
                    label: '副本类型',
                    value: taskIndex,
                    items: _taskDefs.map((d) {
                      final m = d as Map;
                      return DropdownMenuItem(
                        value: (m['index'] as num).toInt(),
                        child: Text(m['name']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (v) => setSheet(() { taskIndex = v ?? 0; levelIndex = 0; }),
                  ),
                  SelectField<int>(
                    label: '关卡',
                    value: levelIndex,
                    items: levels.map((lv) {
                      final idx = (lv['index'] as num?)?.toInt() ?? 0;
                      return DropdownMenuItem(value: idx, child: Text(lv['name']?.toString() ?? '$idx'));
                    }).toList(),
                    onChanged: (v) => setSheet(() => levelIndex = v ?? 0),
                  ),
                  NumberField(label: '单次次数', value: count, min: 1, max: 9999,
                      onChanged: (v) => setSheet(() => count = v.toInt())),
                  NumberField(label: '运行次数', value: runtimes, min: 0, max: 99999,
                      onChanged: (v) => setSheet(() => runtimes = v.toInt())),
                  SwitchField(label: '自动检测', value: autoDetect,
                      onChanged: (v) => setSheet(() => autoDetect = v)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                      onPressed: () {
                        final def = _taskDefs.cast<Map>().firstWhere(
                          (d) => (d['index'] as num).toInt() == taskIndex);
                        final levels = _levelsForTask(taskIndex);
                        final lv = levels.firstWhere(
                          (l) => (l['index'] as num?)?.toInt() == levelIndex,
                          orElse: () => levels.first);
                        setState(() {
                          (_get('trailblazePower', 'tasklist') as List).add({
                            'name': def['name'] ?? '',
                            'id': def['id'] ?? '',
                            'level': levelIndex,
                            'levelName': lv['name'] ?? '',
                            'count': count,
                            'runtimes': runtimes,
                            'autoDetect': autoDetect,
                          });
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('加入清单'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 3. 领取奖励 ──
  Widget _rewardsTab() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final rewards = (_get('receiveRewards', 'rewards') as List);
    return _tabBody([
      GlassPanel(
        child: SectionHeader(
          title: '领取奖励',
          subtitle: '勾选要领取的奖励项目，兑换码支持空格或换行。',
          enabled: _get('receiveRewards', 'enabled') == true,
          onEnabledChanged: (v) => _set('receiveRewards', 'enabled', v),
        ),
      ),
      const SizedBox(height: 12),
      GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('奖励项目', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: List.generate(7, (i) => CheckboxChip(
                label: _rewardLabels[i],
                value: i < rewards.length ? rewards[i] == true : false,
                onChanged: (v) => setState(() => rewards[i] = v),
              )),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GlassPanel(
        child: TextFieldRow(
          label: '兑换码',
          controller: TextEditingController(text: _get('receiveRewards', 'redeemCodes')?.toString() ?? ''),
          hint: '兑换码 兑换码 兑换码',
          maxLines: 4,
          onChangedSync: (v) => (_model!['receiveRewards'] as Map)['redeemCodes'] = v,
        ),
      ),
    ]);
  }

  // ── 4. 旷宇纷争 ──
  Widget _cosmicTab() {
    return _tabBody([
      GlassPanel(
        child: SectionHeader(
          title: '旷宇纷争',
          subtitle: '管理差分宇宙、货币战争和积分奖励。',
          enabled: _get('cosmicStrife', 'enabled') == true,
          onEnabledChanged: (v) => _set('cosmicStrife', 'enabled', v),
        ),
      ),
      const SizedBox(height: 12),
      // 差分宇宙
      GlassPanel(
        child: Column(
          children: [
            SwitchField(
              label: '差分宇宙',
              value: _get('cosmicStrife', 'divergentUniverse.enabled') == true,
              activeText: '启用', inactiveText: '关闭',
              onChanged: (v) => _set('cosmicStrife', 'divergentUniverse.enabled', v),
            ),
            const Divider(height: 16),
            SelectField<int>(
              label: '模式',
              value: (_get('cosmicStrife', 'divergentUniverse.mode') as num).toInt(),
              items: const [DropdownMenuItem(value: 0, child: Text('刷第一关'))],
              onChanged: (v) => _set('cosmicStrife', 'divergentUniverse.mode', v ?? 0),
            ),
            NumberField(
              label: '运行次数',
              value: _get('cosmicStrife', 'divergentUniverse.runtimes') as num,
              min: 1, max: 99999,
              onChanged: (v) => _set('cosmicStrife', 'divergentUniverse.runtimes', v.toInt()),
            ),
            SwitchField(
              label: '秘技速刷',
              value: _get('cosmicStrife', 'divergentUniverse.useTechnique') == true,
              onChanged: (v) => _set('cosmicStrife', 'divergentUniverse.useTechnique', v),
            ),
            SwitchField(
              label: '积分奖励',
              value: _get('cosmicStrife', 'pointRewards.enabled') == true,
              onChanged: (v) => _set('cosmicStrife', 'pointRewards.enabled', v),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      // 货币战争
      GlassPanel(
        child: Column(
          children: [
            SwitchField(
              label: '货币战争',
              value: _get('cosmicStrife', 'currencyWars.enabled') == true,
              activeText: '启用', inactiveText: '关闭',
              onChanged: (v) => _set('cosmicStrife', 'currencyWars.enabled', v),
            ),
            const Divider(height: 16),
            TextFieldRow(
              label: '开拓者名称',
              controller: TextEditingController(text: _get('cosmicStrife', 'currencyWars.username')?.toString() ?? ''),
              hint: '角色名',
              onChangedSync: (v) => (_model!['cosmicStrife'] as Map)['currencyWars.username'] = v,
            ),
            SelectField<int>(
              label: '类型',
              value: (_get('cosmicStrife', 'currencyWars.mode') as num).toInt(),
              items: const [
                DropdownMenuItem(value: 0, child: Text('标准博弈')),
                DropdownMenuItem(value: 1, child: Text('超频博弈')),
                DropdownMenuItem(value: 2, child: Text('刷开局')),
              ],
              onChanged: (v) => _set('cosmicStrife', 'currencyWars.mode', v ?? 0),
            ),
            SelectField<int>(
              label: '难度',
              value: (_get('cosmicStrife', 'currencyWars.difficulty') as num).toInt(),
              items: const [
                DropdownMenuItem(value: 0, child: Text('最低难度')),
                DropdownMenuItem(value: 1, child: Text('最高难度')),
                DropdownMenuItem(value: 2, child: Text('当前难度')),
              ],
              onChanged: (v) => _set('cosmicStrife', 'currencyWars.difficulty', v ?? 0),
            ),
            NumberField(
              label: '运行次数',
              value: _get('cosmicStrife', 'currencyWars.runtimes') as num,
              min: 1, max: 99999,
              onChanged: (v) => _set('cosmicStrife', 'currencyWars.runtimes', v.toInt()),
            ),
            TextFieldRow(
              label: '攻略名称',
              controller: TextEditingController(text: _get('cosmicStrife', 'currencyWars.strategy')?.toString() ?? ''),
              hint: 'template',
              onChangedSync: (v) => (_model!['cosmicStrife'] as Map)['currencyWars.strategy'] = v,
            ),
            NumberField(
              label: '攻略索引',
              value: _get('cosmicStrife', 'currencyWars.strategyIndex') as num,
              min: 0, max: 9999,
              onChanged: (v) => _set('cosmicStrife', 'currencyWars.strategyIndex', v.toInt()),
            ),
            const Divider(height: 16),
            _rerollField('Boss 名称', 'currencyWars.reroll.bossNames'),
            _rerollField('Boss 词条', 'currencyWars.reroll.bossAffixes'),
            _rerollField('投资环境', 'currencyWars.reroll.investEnvironments'),
            _rerollField('投资策略', 'currencyWars.reroll.investStrategies'),
          ],
        ),
      ),
    ]);
  }

  Widget _rerollField(String label, String key) {
    return TextFieldRow(
      label: label,
      controller: TextEditingController(text: _get('cosmicStrife', key)?.toString() ?? ''),
      onChangedSync: (v) => (_model!['cosmicStrife'] as Map)[key] = v,
    );
  }

  // ── 5. 任务完成后 ──
  Widget _finishTab() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final shutdown = _get('missionAccomplished', 'shutdown') == true;
    final sleep = _get('missionAccomplished', 'sleep') == true;
    final powerAction = shutdown ? 'shutdown' : (sleep ? 'sleep' : 'none');
    return _tabBody([
      GlassPanel(
        child: SectionHeader(
          title: '任务完成后',
          subtitle: '设置全部任务完成后的账号、游戏和电脑动作。',
          enabled: _get('missionAccomplished', 'enabled') == true,
          onEnabledChanged: (v) => _set('missionAccomplished', 'enabled', v),
        ),
      ),
      const SizedBox(height: 12),
      GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('账号与程序', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                CheckboxChip(label: '登出当前账号', value: _get('missionAccomplished', 'logout') == true,
                    onChanged: (v) => _set('missionAccomplished', 'logout', v)),
                CheckboxChip(label: '退出游戏', value: _get('missionAccomplished', 'exitGame') == true,
                    onChanged: (v) => _set('missionAccomplished', 'exitGame', v)),
                CheckboxChip(label: '关闭程序', value: _get('missionAccomplished', 'exitApp') == true,
                    onChanged: (v) => _set('missionAccomplished', 'exitApp', v)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('电源动作', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('关机与休眠互斥', style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _powerRadio('无动作', 'none', powerAction),
                _powerRadio('关机', 'shutdown', powerAction),
                _powerRadio('休眠', 'sleep', powerAction),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _powerRadio(String label, String value, String current) {
    final selected = value == current;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () => setState(() {
        (_model!['missionAccomplished'] as Map)['shutdown'] = value == 'shutdown';
        (_model!['missionAccomplished'] as Map)['sleep'] = value == 'sleep';
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? kPrimary : onSurface.withOpacity(0.2)),
        ),
        child: Text(label, style: TextStyle(color: selected ? kPrimary : onSurface, fontSize: 13)),
      ),
    );
  }
}
