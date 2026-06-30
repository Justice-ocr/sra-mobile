import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App 端本地通知服务（不依赖 SRA 本体）。
/// 监听任务状态变化，在任务完成时弹出系统通知。
class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _enabled = true;
  static const _prefsKey = 'appNotificationEnabled';

  bool get enabled => _enabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? true; // 默认启用

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    try {
      await _plugin.initialize(initSettings);
      // Android 13+ 运行时通知权限
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (e) {
      debugPrint('通知初始化失败: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    if (value && !_initialized) await init();
  }

  Future<void> show(String title, String body) async {
    if (!_enabled || !_initialized) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sra_task_channel',
        'SRA 任务通知',
        channelDescription: 'SRA 任务状态变化通知',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    try {
      await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
    } catch (e) {
      debugPrint('通知发送失败: $e');
    }
  }
}
