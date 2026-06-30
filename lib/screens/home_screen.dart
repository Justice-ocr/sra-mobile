import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  int _heroSlide = 0;
  Timer? _heroTimer;
  late AnimationController _waveCtrl;
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();
  double _sheetProgress = 0.0; // 0=55% 1=100%

  static const _pageTitles = ['任务控制', '配置管理', '运行日志', '拓展', '系统设置'];
  static const _pageDescs = [
    '远程启动停止任务，实时查看运行状态',
    '管理多套配置方案，按需快速切换',
    '查看实时日志流，掌握任务执行详情',
    '脚本仓库与拓展功能管理',
    '查看并修改 SRA 全局设置',
  ];
  static const _bgImages = [
    'assets/images/bg-tasks.jpg',
    'assets/images/bg-settings.jpg',
    'assets/images/bg-logs.jpg',
    'assets/images/bg-extensions.jpg',
    'assets/images/bg-settings.jpg',
  ];
  static const _heroSlides = [
    'assets/images/hero-banner.jpg',
    'assets/images/bg-tasks.jpg',
    'assets/images/bg-settings.jpg',
    'assets/images/bg-extensions.jpg',
    'assets/images/bg-logs.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _heroTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() => _heroSlide = (_heroSlide + 1) % _heroSlides.length);
    });
    _sheetCtrl.addListener(() {
      if (!mounted) return;
      // minChildSize=0.55, maxChildSize=1.0, so progress = (size-0.55)/0.45
      final p = ((_sheetCtrl.size - 0.55) / 0.45).clamp(0.0, 1.0);
      if ((p - _sheetProgress).abs() > 0.005) setState(() => _sheetProgress = p);
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _waveCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final panelColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      bottomNavigationBar: _buildBottomNav(isDark),
      body: Stack(
        children: [
          // 全屏背景图
          ..._bgImages.asMap().entries.map((e) => AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _currentPage == e.key ? 1.0 : 0.0,
                child: Image.asset(e.value,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF050816))),
              )),
          // 遮罩
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.40), Colors.black.withOpacity(0.70)],
              ),
            ),
          ),
          // hero 内容（顶栏 + 标题）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: _buildHeroContent(),
          ),
          // 幕布面板
          DraggableScrollableSheet(
            controller: _sheetCtrl,
            initialChildSize: 0.55,
            minChildSize: 0.55,
            maxChildSize: 1.0,
            snap: true,
            snapSizes: const [0.55, 1.0],
            builder: (_, ctrl) {
              return AnimatedBuilder(
                animation: _waveCtrl,
                builder: (_, __) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 波浪贴在面板顶部上方（随覆盖进度渐隐）
                    Positioned(
                      top: -44,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: (1.0 - _sheetProgress).clamp(0.0, 1.0),
                        child: CustomPaint(
                          size: Size(MediaQuery.of(context).size.width, 50),
                          painter: _WavePainter(_waveCtrl.value, panelColor, 1.0 - _sheetProgress),
                        ),
                      ),
                    ),
                    PrimaryScrollController(
                      controller: ctrl,
                      child: Container(
                        decoration: BoxDecoration(
                          color: panelColor,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -4))],
                        ),
                        child: Column(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              width: 40, height: 4,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.black26,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Expanded(child: _buildPageContent()),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Hero 顶部内容（无波浪，幕布覆盖接缝）─────────────
  Widget _buildHeroContent() {
    return Stack(
      children: [
        // 毛玻璃顶栏
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: _buildGlassNavBar(),
        ),
        // 标题文字
        Positioned(
          bottom: 32,
          left: 28,
          right: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('StarRailAssistant WebUI',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(colors: [Colors.white, Color(0xFF00F0FF)]).createShader(bounds),
                child: Text(_pageTitles[_currentPage],
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
              ),
              const SizedBox(height: 8),
              Text(_pageDescs[_currentPage],
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  // 毛玻璃顶栏
  Widget _buildGlassNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/console-avatar.jpg',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 36,
                    height: 36,
                    color: const Color(0xFF00F0FF).withOpacity(0.3),
                    child: const Icon(Icons.person,
                        color: Color(0xFF00F0FF), size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SRA WebUI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '远程控制台',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              // 主题切换（在线左侧）
              GestureDetector(
                onTap: () => context.read<ThemeProvider>().toggle(),
                child: Icon(
                  context.watch<ThemeProvider>().isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // 在线状态
              Consumer<TaskProvider>(
                builder: (_, task, __) => Row(
                  children: [
                    _PulsingDot(isOnline: task.status != null),
                    const SizedBox(width: 6),
                    Text(task.status != null ? '在线' : '离线',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (mounted) context.go('/login');
                },
                child: Text('退出', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 底部导航（玻璃效果）
  Widget _buildBottomNav(bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: NavigationBar(
          backgroundColor: isDark ? Colors.black.withOpacity(0.55) : Colors.white.withOpacity(0.75),
          selectedIndex: _currentPage,
          onDestinationSelected: (i) => setState(() => _currentPage = i),
          indicatorColor: const Color(0xFF00C8D7).withOpacity(0.2),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle, color: Color(0xFF00C8D7)), label: '任务'),
            NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder, color: Color(0xFF00C8D7)), label: '配置'),
            NavigationDestination(icon: Icon(Icons.terminal_outlined), selectedIcon: Icon(Icons.terminal, color: Color(0xFF00C8D7)), label: '日志'),
            NavigationDestination(icon: Icon(Icons.extension_outlined), selectedIcon: Icon(Icons.extension, color: Color(0xFF00C8D7)), label: '拓展'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: Color(0xFF00C8D7)), label: '设置'),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_currentPage) {
      case 0:
        return const _TaskPage();
      case 1:
        return const _ConfigPage();
      case 2:
        return const _LogPage();
      case 3:
        return const _ExtensionsPage();
      case 4:
        return const _SettingsPage();
      default:
        return const _TaskPage();
    }
  }
}

// ── 任务页 ─────────────────────────────────────────
class _TaskPage extends StatelessWidget {
  const _TaskPage();

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Consumer<TaskProvider>(
      builder: (context, task, _) {
        final status = task.status;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          children: [
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (status?.running == true ? const Color(0xFF10B981) : Colors.grey).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          status?.running == true ? Icons.play_circle : Icons.stop_circle,
                          color: status?.running == true ? const Color(0xFF10B981) : Colors.grey,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('任务状态', style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 13)),
                            Text(
                              status?.displayState ?? '未知',
                              style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: task.refreshStatus,
                        icon: Icon(Icons.refresh, color: onSurface.withOpacity(0.4), size: 20),
                      ),
                    ],
                  ),
                  if (status?.taskName != null) ...[
                    const SizedBox(height: 16),
                    Divider(color: onSurface.withOpacity(0.1)),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.task_alt, label: '任务', value: status!.taskName!),
                  ],
                  if (status?.configNames?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.folder_outlined, label: '配置', value: status!.configNames!.join(', ')),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: '启动任务',
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFF10B981),
                    onTap: (status?.running == true || task.isLoading) ? null : () => _showRunDialog(context, task),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: '停止任务',
                    icon: Icons.stop_rounded,
                    color: const Color(0xFFFF006E),
                    onTap: (status?.running != true || task.isLoading) ? null : () => task.stopTask(),
                  ),
                ),
              ],
            ),
            if (task.error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: task.error!),
            ],
          ],
        );
      },
    );
  }

  void _showRunDialog(BuildContext context, TaskProvider task) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('选择配置', style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (task.configs.isEmpty)
                Text('暂无可用配置', style: TextStyle(color: onSurface.withOpacity(0.4)))
              else
                ...task.configs.map((cfg) => ListTile(
                      leading: const Icon(Icons.folder_outlined, color: Color(0xFF00F0FF)),
                      title: Text(cfg, style: TextStyle(color: onSurface)),
                      onTap: () {
                        Navigator.pop(ctx);
                        task.runTask(configName: cfg);
                      },
                    )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    task.runTask();
                  },
                  child: Text('使用默认配置启动', style: TextStyle(color: onSurface.withOpacity(0.5))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 配置页 ─────────────────────────────────────────
class _ConfigPage extends StatelessWidget {
  const _ConfigPage();

  void _openDetail(BuildContext context, String cfg) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TaskProvider>(),
        child: _ConfigDetailPage(configName: cfg),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Consumer<TaskProvider>(
      builder: (_, task, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Text('可用配置', style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: task.loadConfigs, icon: Icon(Icons.refresh, color: onSurface.withOpacity(0.4), size: 20)),
                ],
              ),
            ),
            Expanded(
              child: task.configs.isEmpty
                  ? Center(child: Text('暂无配置', style: TextStyle(color: onSurface.withOpacity(0.38))))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: task.configs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final cfg = task.configs[i];
                        return _GlassCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F0FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.folder_outlined, color: Color(0xFF00F0FF), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _openDetail(context, cfg),
                                  child: Text(cfg, style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF00F0FF), size: 20),
                                onPressed: () => _openDetail(context, cfg),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF10B981), size: 26),
                                onPressed: task.isRunning ? null : () => task.runTask(configName: cfg),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── 配置详情编辑页 ──────────────────────────────────
class _ConfigDetailPage extends StatefulWidget {
  final String configName;
  const _ConfigDetailPage({required this.configName});
  @override
  State<_ConfigDetailPage> createState() => _ConfigDetailPageState();
}

class _ConfigDetailPageState extends State<_ConfigDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _boolValues = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await context.read<TaskProvider>().api.getConfig(widget.configName);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      if (data != null) _initFields(data);
    });
  }

  void _initFields(Map<String, dynamic> data) {
    for (final section in data.entries) {
      if (section.value is! Map) continue;
      final m = Map<String, dynamic>.from(section.value as Map);
      for (final e in m.entries) {
        final key = '${section.key}.${e.key}';
        if (e.value is bool) {
          _boolValues[key] = e.value as bool;
        } else {
          _controllers[key] = TextEditingController(text: e.value?.toString() ?? '');
        }
      }
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    // 把扁平化的 key 还原成嵌套 map
    final out = Map<String, dynamic>.from(_data!);
    for (final section in out.keys.toList()) {
      if (out[section] is! Map) continue;
      final m = Map<String, dynamic>.from(out[section] as Map);
      for (final k in m.keys.toList()) {
        final flatKey = '$section.$k';
        if (_boolValues.containsKey(flatKey)) {
          m[k] = _boolValues[flatKey];
        } else if (_controllers.containsKey(flatKey)) {
          final raw = _controllers[flatKey]!.text;
          m[k] = num.tryParse(raw) ?? raw;
        }
      }
      out[section] = m;
    }
    final ok = await context.read<TaskProvider>().api.saveConfig(widget.configName, out);
    if (!mounted) return;
    setState(() { _saving = false; _error = ok ? null : '保存失败'; });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('配置已保存'), duration: Duration(seconds: 2)));
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(widget.configName, style: TextStyle(color: textColor)),
        leading: BackButton(color: textColor),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中...' : '保存', style: const TextStyle(color: Color(0xFF00C8D7))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C8D7)))
          : _data == null
              ? const Center(child: Text('加载失败'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: _ErrorBanner(message: _error!)),
                    // 按 section 分组渲染
                    ..._buildSections(context, _data!),
                  ],
                ),
    );
  }

  List<Widget> _buildSections(BuildContext context, Map<String, dynamic> data) {
    // data 顶层 key 就是 section（startGame, trailblazePower 等）
    return data.entries.where((e) => e.key != 'name' && e.key != 'version').map((section) {
      final sectionData = section.value;
      if (sectionData is! Map) return const SizedBox.shrink();
      return _SectionCard(
        title: _sectionLabel(section.key),
        fields: Map<String, dynamic>.from(sectionData),
        controllers: _controllers,
        boolValues: _boolValues,
        onBoolChanged: (k, v) => setState(() => _boolValues[k] = v),
      );
    }).toList();
  }

  static String _sectionLabel(String key) {
    const labels = {
      'startGame': '启动游戏',
      'trailblazePower': '锄大地',
      'receiveRewards': '领取奖励',
      'cosmicStrife': '模拟宇宙',
      'missionAccomplished': '任务完成后',
    };
    return labels[key] ?? key;
  }
}

// ── 日志页（SSE 实时流）────────────────────────────
class _LogPage extends StatefulWidget {
  const _LogPage();
  @override
  State<_LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<_LogPage> {
  final List<String> _lines = [];
  final ScrollController _scroll = ScrollController();
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    final api = context.read<TaskProvider>().api;
    _sub = api.streamLogs().listen(
      (chunk) {
        // SSE 格式: "data: {text}\n\n"
        for (final raw in chunk.split('\n')) {
          final line = raw.startsWith('data:') ? raw.substring(5).trim() : raw.trim();
          if (line.isEmpty) continue;
          // 尝试解析 JSON {"message":"..."}，否则直接显示
          String display;
          try {
            final m = jsonDecode(line) as Map;
            display = m['message']?.toString() ?? line;
          } catch (_) {
            display = line;
          }
          if (mounted) setState(() => _lines.add(display));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
          });
        }
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Text('运行日志', style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_lines.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _lines.clear()),
                  child: Text('清空', style: TextStyle(color: onSurface.withOpacity(0.38), fontSize: 12)),
                ),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _sub != null ? const Color(0xFF10B981) : Colors.grey,
              )),
              const SizedBox(width: 6),
              Text('实时', style: TextStyle(color: const Color(0xFF10B981).withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: onSurface.withOpacity(0.08)),
            ),
            child: _lines.isEmpty
                ? Center(child: Text('等待日志...', style: TextStyle(color: onSurface.withOpacity(0.38), fontSize: 14)))
                : ListView.builder(
                    controller: _scroll,
                    itemCount: _lines.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(_lines[i], style: TextStyle(
                        color: isDark ? const Color(0xFF9EEAFF) : const Color(0xFF005577),
                        fontSize: 12, fontFamily: 'monospace')),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── 设置页 ─────────────────────────────────────────
class _SettingsPage extends StatefulWidget {
  const _SettingsPage();
  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _boolValues = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await context.read<TaskProvider>().api.getSettings();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      if (data != null) _initFields(data);
    });
  }

  void _initFields(Map<String, dynamic> data) {
    for (final section in data.entries) {
      if (section.value is! Map) continue;
      final m = Map<String, dynamic>.from(section.value as Map);
      for (final e in m.entries) {
        final key = '${section.key}.${e.key}';
        if (e.value is bool) {
          _boolValues[key] = e.value as bool;
        } else if (e.value is! List && e.value is! Map) {
          _controllers[key] = TextEditingController(text: e.value?.toString() ?? '');
        }
      }
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    final out = Map<String, dynamic>.from(_data!);
    for (final section in out.keys.toList()) {
      if (out[section] is! Map) continue;
      final m = Map<String, dynamic>.from(out[section] as Map);
      for (final k in m.keys.toList()) {
        final flatKey = '$section.$k';
        if (_boolValues.containsKey(flatKey)) {
          m[k] = _boolValues[flatKey];
        } else if (_controllers.containsKey(flatKey)) {
          final raw = _controllers[flatKey]!.text;
          m[k] = num.tryParse(raw) ?? raw;
        }
      }
      out[section] = m;
    }
    final ok = await context.read<TaskProvider>().api.saveSettings(out);
    if (!mounted) return;
    setState(() { _saving = false; _error = ok ? null : '保存失败'; });
    if (ok) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存'), duration: Duration(seconds: 2)));
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  static const _sectionLabels = {
    'general': '通用', 'display': '显示', 'update': '更新',
    'advanced': '高级', 'notification': '通知', 'warpForecast': '抽卡预测',
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00C8D7)));
    if (_data == null) return const Center(child: Text('加载失败'));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(children: [
          Text('系统设置', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFFF3366), fontSize: 12)),
          const SizedBox(width: 8),
          TextButton(onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中...' : '保存', style: const TextStyle(color: Color(0xFF00C8D7)))),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: _data!.entries.map((section) {
            if (section.value is! Map) return const SizedBox.shrink();
            return _SectionCard(
              title: _sectionLabels[section.key] ?? section.key,
              fields: Map<String, dynamic>.from(section.value as Map),
              controllers: _controllers,
              boolValues: _boolValues,
              sectionKey: section.key,
              onBoolChanged: (k, v) => setState(() => _boolValues[k] = v),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}

// ── 拓展页 ─────────────────────────────────────────
class _ExtensionsPage extends StatefulWidget {
  const _ExtensionsPage();
  @override
  State<_ExtensionsPage> createState() => _ExtensionsPageState();
}

class _ExtensionsPageState extends State<_ExtensionsPage> {
  List<dynamic> _repos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<TaskProvider>().api.getScriptRepos();
      if (mounted) setState(() { _repos = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Text('脚本仓库', style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: _load, icon: Icon(Icons.refresh, color: onSurface.withOpacity(0.4), size: 20)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C8D7)))
              : _repos.isEmpty
                  ? Center(child: Text('暂无脚本仓库', style: TextStyle(color: onSurface.withOpacity(0.38))))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _repos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final repo = _repos[i] as Map<String, dynamic>;
                        final name = repo['name']?.toString() ?? repo['url']?.toString() ?? '未知';
                        final url = repo['url']?.toString() ?? '';
                        final enabled = repo['enabled'] as bool? ?? true;
                        return _GlassCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.extension, color: Color(0xFF7C3AED), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
                                    if (url.isNotEmpty)
                                      Text(url, style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (enabled ? const Color(0xFF10B981) : Colors.grey).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(enabled ? '已启用' : '已禁用',
                                    style: TextStyle(
                                      color: enabled ? const Color(0xFF10B981) : Colors.grey,
                                      fontSize: 11, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ── 通用组件 ───────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
        ),
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.38 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, color: onSurface.withOpacity(0.38), size: 16),
        const SizedBox(width: 8),
        Text('$label：', style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13)),
        Expanded(
          child: Text(value,
              style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3366).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF3366).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF3366), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFFFF3366), fontSize: 13))),
        ],
      ),
    );
  }
}

// 呼吸灯
class _PulsingDot extends StatefulWidget {
  final bool isOnline;
  const _PulsingDot({required this.isOnline});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isOnline ? const Color(0xFF10B981) : Colors.grey;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: widget.isOnline
              ? [
                  BoxShadow(
                    color: color.withOpacity(_anim.value * 0.7),
                    blurRadius: 8 * _anim.value,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}

// ── Section 智能表单卡片 ───────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> fields;
  final Map<String, TextEditingController> controllers;
  final Map<String, bool> boolValues;
  final String? sectionKey;
  final void Function(String key, bool val) onBoolChanged;

  const _SectionCard({
    required this.title,
    required this.fields,
    required this.controllers,
    required this.boolValues,
    required this.onBoolChanged,
    this.sectionKey,
  });

  static const _fieldLabels = <String, String>{
    // 通用 bool
    'enabled': '启用',
    // startGame / 启动游戏
    'autologin': '自动登录',
    'relogin': '重新登录',
    'game.path': '游戏路径',
    'game.channel': '游戏渠道',
    'game.useGlobalPath': '使用全局路径',
    'username': '账号',
    'password': '密码',
    // trailblazePower / 锄大地
    'replenish.enabled': '补充体力',
    'replenish.times': '补充次数',
    'replenish.way': '补充方式',
    'useAssistant': '使用助手',
    'useBuildTarget': '使用培养目标',
    'activity.enabled': '活动副本',
    'activity.gardenOfPlenty.level1': '丰收花园 难度1',
    'activity.gardenOfPlenty.level2': '丰收花园 难度2',
    'activity.planarFissure.level': '位面裂隙 难度',
    'activity.realmOfTheStrange.level': '异域秘境 难度',
    // receiveRewards / 领取奖励
    'redeemCodes': '兑换码',
    // cosmicStrife / 模拟宇宙
    'pointRewards.enabled': '积分奖励',
    'divergentUniverse.enabled': '差分宇宙',
    'divergentUniverse.mode': '差分宇宙模式',
    'divergentUniverse.runtimes': '差分宇宙次数',
    'divergentUniverse.useTechnique': '使用秘技',
    'currencyWars.enabled': '黄金与机械',
    'currencyWars.mode': '模式',
    'currencyWars.difficulty': '难度',
    'currencyWars.runtimes': '运行次数',
    'currencyWars.strategy': '策略',
    'currencyWars.username': '用户名',
    // missionAccomplished / 任务完成后
    'exitApp': '退出软件',
    'exitGame': '退出游戏',
    'shutdown': '关机',
    'sleep': '睡眠',
    'logout': '注销',
    // general settings
    'gamePath.autoDetect': '自动检测游戏路径',
    'gamePath.index': '游戏路径序号',
    'gameArgs.enabled': '启用游戏参数',
    'gameArgs.fullScreenMode': '全屏模式',
    'gameArgs.windowSize': '窗口尺寸',
    'gameArgs.popupWindow': '弹出窗口',
    'gameArgs.useCmd': '使用CMD启动',
    'gameArgs.advanced': '高级参数',
    'cloudGame.enabled': '云游戏',
    'cloudGame.browser': '云游戏浏览器',
    'ocrMatchConfidence': 'OCR 置信度',
    'templateMatchConfidence': '模板匹配置信度',
    // display settings
    'backgroundImage.uri': '背景图片',
    'backgroundImage.opacity': '背景透明度',
    'controlPanel.opacity': '控制面板透明度',
    'language': '语言',
    'window.remember': '记住窗口位置',
    // update settings
    'mirrorChyanCdk': 'CDK 镜像',
    'downloadChannel': '下载渠道',
    'autoUpdate': '自动更新',
    'checkForUpdates': '检查更新',
    'updateChannel': '更新渠道',
    // advanced settings
    'backend.launchArgs': '后端启动参数',
    'backend.remote.enabled': '启用远程后端',
    'backend.remote.baseUrl': '远程后端地址',
    'webui.remote.enabled': '启用 WebUI 远程',
    'webui.remote.autostart': '自动启动 WebUI',
    'webui.remote.token': 'WebUI Token',
    'developerMode.enabled': '开发者模式',
    'developerMode.overlay': '调试覆盖层',
    'developerMode.python.enabled': 'Python 脚本',
    'developerMode.saveOcrImage': '保存 OCR 图像',
    'developerMode.python.main': 'Python 入口',
    'developerMode.python.path': 'Python 路径',
    // notification settings
    'system.enabled': '系统通知',
    'bark.enabled': 'Bark 通知',
    'bark.serverUrl': 'Bark 服务器',
    'bark.deviceKey': 'Bark DeviceKey',
    'bark.group': 'Bark 分组',
    'bark.sound': 'Bark 声音',
    'bark.level': 'Bark 等级',
    'bark.ciphertext': 'Bark 密文',
    'bark.icon': 'Bark 图标',
    'dingTalk.enabled': '钉钉通知',
    'dingTalk.webhookUrl': '钉钉 Webhook',
    'dingTalk.secret': '钉钉签名密钥',
    'discord.enabled': 'Discord 通知',
    'discord.webhookUrl': 'Discord Webhook',
    'discord.sendImage': 'Discord 发送图片',
    'feishu.enabled': '飞书通知',
    'feishu.webhookUrl': '飞书 Webhook',
    'feishu.appId': '飞书 AppID',
    'feishu.appSecret': '飞书 AppSecret',
    'feishu.receiveId': '飞书接收者ID',
    'feishu.receiveIdType': '飞书接收者类型',
    'oneBot.enabled': 'OneBot 通知',
    'oneBot.url': 'OneBot 地址',
    'oneBot.token': 'OneBot Token',
    'oneBot.userId': 'OneBot 用户ID',
    'oneBot.groupId': 'OneBot 群ID',
    'oneBot.sendImage': 'OneBot 发送图片',
    'serverChan.enabled': 'Server酱',
    'serverChan.sendKey': 'Server酱 SendKey',
    'telegram.enabled': 'Telegram 通知',
    'telegram.botToken': 'Bot Token',
    'telegram.chatId': 'Chat ID',
    'telegram.apiBaseUrl': 'API 地址',
    'telegram.proxyEnabled': '启用代理',
    'telegram.proxyUrl': '代理地址',
    'telegram.sendImage': '发送图片',
    'weCom.enabled': '企业微信',
    'weCom.webhookUrl': '企业微信 Webhook',
    'weCom.sendImage': '发送图片',
    'webhook.enabled': 'Webhook',
    'webhook.url': 'Webhook 地址',
    'email.enabled': '邮件通知',
    'email.smtpServer': 'SMTP 服务器',
    'email.smtpPort': 'SMTP 端口',
    'email.smtpSender': '发件人',
    'email.smtpReceiver': '收件人',
    'email.smtpAuthCode': '授权码',
    'xxtui.enabled': 'XXTui 通知',
    'xxtui.apiKey': 'XXTui API Key',
    'xxtui.channel': 'XXTui 渠道',
    'xxtui.source': 'XXTui 来源',
  };

  static bool _isSensitive(String key) =>
      key.contains('password') || key.contains('token') ||
      key.contains('secret') || key.contains('Auth');

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final visibleFields = fields.entries
        .where((e) => e.value is! List && e.value is! Map)
        .toList();
    if (visibleFields.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _GlassCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...visibleFields.map((e) {
            final flatKey = sectionKey != null ? '$sectionKey.${e.key}' : e.key;
            final label = _fieldLabels[e.key] ?? e.key;
            if (e.value is bool) {
              final val = boolValues[flatKey] ?? (e.value as bool);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(label, style: TextStyle(color: onSurface, fontSize: 14))),
                  Switch(value: val, onChanged: (v) => onBoolChanged(flatKey, v), activeColor: const Color(0xFF00C8D7)),
                ]),
              );
            }
            final ctrl = controllers[flatKey];
            if (ctrl == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: ctrl,
                  obscureText: _isSensitive(e.key),
                  keyboardType: e.value is num ? TextInputType.number : TextInputType.text,
                  style: TextStyle(color: onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            );
          }),
        ],
      )),
    );
  }
}

// 波浪画笔（幕布顶部过渡，多层不同透明度，幅度随覆盖进度收缩）
class _WavePainter extends CustomPainter {
  final double t;
  final Color color;
  final double amplitude; // 1.0=full, 0.0=flat

  _WavePainter(this.t, this.color, this.amplitude);

  @override
  void paint(Canvas canvas, Size size) {
    // 三层波浪：主层 + 两层偏移半透明
    final layers = [
      _WaveLayer(opacity: 1.0,  ampScale: 1.0,  speedMul: 1.0,   phaseOffset: 0.0),
      _WaveLayer(opacity: 0.45, ampScale: 0.75, speedMul: 0.65,  phaseOffset: 0.35),
      _WaveLayer(opacity: 0.22, ampScale: 0.55, speedMul: 1.35,  phaseOffset: 0.65),
    ];

    final baseAmp = 14.0 * amplitude.clamp(0.0, 1.0);

    for (final layer in layers) {
      final paint = Paint()
        ..color = color.withOpacity(layer.opacity)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x++) {
        final px = x / size.width;
        final amp = baseAmp * layer.ampScale;
        final y = size.height * 0.55
            + sin((px * 2 * pi) + t * 2 * pi * layer.speedMul + layer.phaseOffset * 2 * pi) * amp
            + sin((px * 3.5 * pi) + t * 2 * pi * layer.speedMul * 0.7 + layer.phaseOffset) * amp * 0.5;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.t != t || old.amplitude != amplitude || old.color != color;
}

class _WaveLayer {
  final double opacity;
  final double ampScale;
  final double speedMul;
  final double phaseOffset;
  const _WaveLayer({
    required this.opacity,
    required this.ampScale,
    required this.speedMul,
    required this.phaseOffset,
  });
}
