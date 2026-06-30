import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 一条通知历史记录
class NotificationRecord {
  final int timestamp; // 毫秒
  final String title;
  final String body;
  final String? imagePath; // 本地截图文件路径（可空）

  NotificationRecord({
    required this.timestamp,
    required this.title,
    required this.body,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'title': title,
        'body': body,
        'imagePath': imagePath,
      };

  factory NotificationRecord.fromJson(Map<String, dynamic> j) => NotificationRecord(
        timestamp: j['timestamp'] as int,
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        imagePath: j['imagePath']?.toString(),
      );

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

/// 通知历史存储：JSON 存元数据，截图存文件，保留 7 日。
class NotificationHistory {
  NotificationHistory._();
  static final NotificationHistory instance = NotificationHistory._();

  static const _prefsKey = 'notificationHistory';
  static const _retentionDays = 7;

  List<NotificationRecord> _records = [];
  bool _loaded = false;

  List<NotificationRecord> get records => List.unmodifiable(_records);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _records = list
            .map((e) => NotificationRecord.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        _records = [];
      }
    }
    _loaded = true;
    await _purgeExpired();
  }

  /// 添加一条记录：若有图片字节，存到持久目录并记录路径
  Future<void> add(String title, String body, {Uint8List? imageBytes, int? timestamp}) async {
    await _ensureLoaded();
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    String? imagePath;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      imagePath = await _saveImage(imageBytes, ts);
    }
    _records.insert(0, NotificationRecord(timestamp: ts, title: title, body: body, imagePath: imagePath));
    await _persist();
  }

  Future<List<NotificationRecord>> getAll() async {
    await _ensureLoaded();
    // 时间倒序
    final sorted = [..._records]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  Future<void> clear() async {
    await _ensureLoaded();
    // 删除截图文件
    for (final r in _records) {
      if (r.imagePath != null) {
        try {
          final f = File(r.imagePath!);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
    _records = [];
    await _persist();
  }

  Future<String?> _saveImage(Uint8List bytes, int ts) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final shotsDir = Directory('${dir.path}/notif_shots');
      if (!await shotsDir.exists()) await shotsDir.create(recursive: true);
      final file = File('${shotsDir.path}/$ts.png');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('保存通知截图失败: $e');
      return null;
    }
  }

  Future<void> _purgeExpired() async {
    final cutoff = DateTime.now().millisecondsSinceEpoch - _retentionDays * 24 * 60 * 60 * 1000;
    final expired = _records.where((r) => r.timestamp < cutoff).toList();
    if (expired.isEmpty) return;
    for (final r in expired) {
      if (r.imagePath != null) {
        try {
          final f = File(r.imagePath!);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
    _records.removeWhere((r) => r.timestamp < cutoff);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_records.map((e) => e.toJson()).toList()));
  }
}
