import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverController = TextEditingController(
    text: 'http://192.168.1.100:5074',
  );
  final _tokenController = TextEditingController(
    text: 'starrailassistant',
  );
  bool _obscureToken = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图片
          Image.asset(
            'assets/images/bg-login.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF050816)),
          ),

          // 渐变遮罩
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.85),
                ],
              ),
            ),
          ),

          // 登录表单
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    ClipOval(
                      child: Image.asset(
                        'assets/images/console-avatar.jpg',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 88,
                          height: 88,
                          color: const Color(0xFF00F0FF).withOpacity(0.3),
                          child: const Icon(Icons.person,
                              color: Color(0xFF00F0FF), size: 48),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'SRA 远程控制台',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'StarRailAssistant WebUI',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 毛玻璃卡片
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 服务器地址
                              TextField(
                                controller: _serverController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: '服务器地址',
                                  hintText: 'http://192.168.1.100:5074',
                                  prefixIcon: Icon(Icons.dns_outlined,
                                      color: Color(0xFF00F0FF)),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Token
                              TextField(
                                controller: _tokenController,
                                obscureText: _obscureToken,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: '访问令牌',
                                  hintText: 'starrailassistant',
                                  prefixIcon: const Icon(Icons.key_outlined,
                                      color: Color(0xFF00F0FF)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureToken
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureToken = !_obscureToken),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // 登录按钮
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : () => _login(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF00F0FF),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.black,
                                              ),
                                            )
                                          : const Text(
                                              '连接',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),

                              // 错误提示
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  if (auth.error == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF3366)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFFF3366)
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline,
                                              color: Color(0xFFFF3366),
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              auth.error!,
                                              style: const TextStyle(
                                                  color: Color(0xFFFF3366),
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      '确保已在 SRA.exe 设置中开启远程连接',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 主题切换按钮（右上角）
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              onPressed: () => context.read<ThemeProvider>().toggle(),
              icon: Icon(
                context.watch<ThemeProvider>().isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: Colors.white.withOpacity(0.85),
                size: 24,
              ),
              tooltip: '切换主题',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _serverController.text.trim(),
      _tokenController.text.trim(),
    );
    if (success && context.mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
}
