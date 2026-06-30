import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_history.dart';

/// App 端本地通知服务（不依赖 SRA 本体）。
/// 监听任务状态变化，在任务完成时弹出系统通知（可带游戏截图大图）。
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

  /// 基础通知（可选大图路径）
  Future<void> show(String title, String body, {String? imagePath}) async {
    if (!_enabled || !_initialized) return;
    AndroidNotificationDetails android;
    if (imagePath != null) {
      final picture = FilePathAndroidBitmap(imagePath);
      android = AndroidNotificationDetails(
        'sra_task_channel',
        'SRA 任务通知',
        channelDescription: 'SRA 任务状态变化通知',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigPictureStyleInformation(
          picture,
          contentTitle: title,
          summaryText: body,
        ),
      );
    } else {
      android = const AndroidNotificationDetails(
        'sra_task_channel',
        'SRA 任务通知',
        channelDescription: 'SRA 任务状态变化通知',
        importance: Importance.high,
        priority: Priority.high,
      );
    }
    final details = NotificationDetails(android: android);
    try {
      await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
    } catch (e) {
      debugPrint('通知发送失败: $e');
    }
  }

  /// 用 PNG 字节作为大图发送通知（任务完成时附游戏截图用），并记入历史
  Future<void> showWithBytes(String title, String body, List<int>? imageBytes) async {
    final bytes = (imageBytes != null && imageBytes.isNotEmpty)
        ? Uint8List.fromList(imageBytes)
        : null;
    // 记入历史（不受通知开关影响，始终留档）
    await NotificationHistory.instance.add(title, body, imageBytes: bytes);
    if (!_enabled || !_initialized) return;
    String? path;
    if (bytes != null) {
      path = await _saveTempImage(bytes, 'sra_shot');
    }
    await show(title, body, imagePath: path);
  }

  /// 发送测试通知：使用内置 SRA 头像作为大图，并记入历史
  Future<void> showTest() async {
    if (!_initialized) await init();
    Uint8List? bytes;
    try {
      final data = await rootBundle.load('assets/images/console-avatar.jpg');
      bytes = data.buffer.asUint8List();
    } catch (e) {
      debugPrint('加载测试头像失败: $e');
    }
    await NotificationHistory.instance.add('SRA 测试通知', '这是一条来自 SRA 控制台的测试通知', imageBytes: bytes);
    String? path;
    if (bytes != null) {
      path = await _saveTempImage(bytes, 'sra_test_avatar');
    }
    await show('SRA 测试通知', '这是一条来自 SRA 控制台的测试通知', imagePath: path);
  }

  /// 把字节写入临时文件，返回路径
  Future<String?> _saveTempImage(Uint8List bytes, String name) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name.png');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('保存临时图片失败: $e');
      return null;
    }
  }
}
