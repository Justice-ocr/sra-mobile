import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import 'config_editor_page.dart';
import 'settings_page_view.dart';
import 'extensions_page_view.dart';

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
  double _sheetProgress = 0.0; // 0=46% 1=100%
  bool _navVisible = true; // 悬浮导航可见性

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
      // minChildSize=0.46, maxChildSize=1.0, so progress = (size-0.46)/0.54
      final p = ((_sheetCtrl.size - 0.46) / 0.54).clamp(0.0, 1.0);
      if ((p - _sheetProgress).abs() > 0.005) setState(() => _sheetProgress = p);
    });
  }

  // 内容滚动方向 → 控制悬浮导航显隐
  bool _onScrollNotification(ScrollNotification n) {
    if (n is UserScrollNotification) {
      if (n.direction == ScrollDirection.reverse && _navVisible) {
        setState(() => _navVisible = false);
      } else if (n.direction == ScrollDirection.forward && !_navVisible) {
        setState(() => _navVisible = true);
      }
    }
    return false;
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
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Stack(
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
              bottom: MediaQuery.of(context).size.height * 0.56,
              child: _buildHeroContent(),
            ),
            // 幕布面板
            DraggableScrollableSheet(
              controller: _sheetCtrl,
              initialChildSize: 0.46,
              minChildSize: 0.46,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [0.46, 1.0],
              builder: (_, ctrl) {
                return AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (_, __) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 多层波浪：前层与面板同色无缝衔接，后层半透明装饰
                      Positioned(
                        top: -44,
                        left: 0,
                        right: 0,
                        height: 46,
                        child: Opacity(
                          opacity: (1.0 - _sheetProgress).clamp(0.0, 1.0),
                          child: CustomPaint(
                            size: Size(MediaQuery.of(context).size.width, 46),
                            painter: _WavePainter(_waveCtrl.value, panelColor, 1.0 - _sheetProgress),
                          ),
                        ),
                      ),
                      // 面板本体：无顶部阴影（阴影会形成可见接缝）
                      PrimaryScrollController(
                        controller: ctrl,
                        child: Container(
                          color: panelColor,
                          child: Column(children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
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
            // 悬浮液态玻璃导航（下滑隐藏，上滑出现）
            _buildFloatingNav(isDark),
          ],
        ),
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

  // 悬浮液态玻璃导航（下滑隐藏，上滑出现）
  Widget _buildFloatingNav(bool isDark) {
    const items = [
      (Icons.play_circle_outline, Icons.play_circle, '任务'),
      (Icons.folder_outlined, Icons.folder, '配置'),
      (Icons.terminal_outlined, Icons.terminal, '日志'),
      (Icons.extension_outlined, Icons.extension, '拓展'),
      (Icons.settings_outlined, Icons.settings, '设置'),
    ];
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      left: 16,
      right: 16,
      bottom: _navVisible ? bottomInset + 12 : -(72 + bottomInset),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: _navVisible ? 1.0 : 0.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                // 液态玻璃：渐变高光 + 半透明底色
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.white.withOpacity(0.16), Colors.white.withOpacity(0.05)]
                      : [Colors.white.withOpacity(0.78), Colors.white.withOpacity(0.48)],
                ),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.7),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final selected = _currentPage == i;
                  final (icon, selIcon, label) = items[i];
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(() => _currentPage = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF00C8D7).withOpacity(0.18) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              selected ? selIcon : icon,
                              size: 22,
                              color: selected
                                  ? const Color(0xFF00C8D7)
                                  : (isDark ? Colors.white60 : const Color(0xFF667085)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? const Color(0xFF00C8D7)
                                    : (isDark ? Colors.white60 : const Color(0xFF667085)),
                              )),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
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
        return const ExtensionsPageView();
      case 4:
        return const SettingsPageView();
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
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
        child: ConfigEditorPage(configName: cfg),
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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

// 波浪画笔（幕布顶部过渡，三层不同透明度，幅度随覆盖进度收缩）
// 参考 WebUI: .wave-back(0.32) / .wave-mid(0.58) / .wave-front(0.94)
class _WavePainter extends CustomPainter {
  final double t;
  final Color color;
  final double amplitude; // 1.0=full, 0.0=flat

  _WavePainter(this.t, this.color, this.amplitude);

  @override
  void paint(Canvas canvas, Size size) {
    final amp = amplitude.clamp(0.0, 1.0);
    // 三层：后→中→前。前层 100% 面板色，与面板无缝衔接；后两层半透明做层次
    final layers = [
      _WaveLayer(opacity: 0.28, baseFactor: 0.28, ampScale: 0.7, speed: 0.55, phase: 0.0,  freq: 1.0),
      _WaveLayer(opacity: 0.50, baseFactor: 0.42, ampScale: 0.85, speed: -0.8, phase: 0.4,  freq: 1.3),
      _WaveLayer(opacity: 1.0,  baseFactor: 0.58, ampScale: 1.0, speed: 1.1,  phase: 0.7,  freq: 0.85),
    ];

    final baseAmp = 16.0 * amp;

    for (final layer in layers) {
      final paint = Paint()
        ..color = color.withOpacity(layer.opacity)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final path = Path();
      path.moveTo(0, size.height + 1); // 底边下沉 1px，与面板重叠防接缝
      final baseline = size.height * layer.baseFactor;
      for (double x = 0; x <= size.width; x += 1) {
        final px = x / size.width;
        final a = baseAmp * layer.ampScale;
        final y = baseline
            + sin((px * 2 * pi * layer.freq) + t * 2 * pi * layer.speed + layer.phase * 2 * pi) * a
            + sin((px * 3.5 * pi * layer.freq) + t * 2 * pi * layer.speed * 0.7 + layer.phase) * a * 0.45;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height + 1);
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
  final double baseFactor; // 基线在画布高度的占比
  final double ampScale;
  final double speed;
  final double phase;
  final double freq;
  const _WaveLayer({
    required this.opacity,
    required this.baseFactor,
    required this.ampScale,
    required this.speed,
    required this.phase,
    required this.freq,
  });
}
