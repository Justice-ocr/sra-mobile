import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/app_notification_service.dart';
import '../models/task_status.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService api;

  TaskStatus? _status;
  bool _isLoading = false;
  String? _error;
  List<String> _configs = [];
  Timer? _pollTimer;

  TaskProvider(this.api) {
    startPolling();
    loadConfigs();
  }

  TaskStatus? get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get configs => _configs;
  bool get isRunning => _status?.running ?? false;

  void startPolling() {
    _pollTimer?.cancel();
    refreshStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => refreshStatus());
  }

  void stopPolling() => _pollTimer?.cancel();

  Future<void> refreshStatus() async {
    try {
      final prev = _status;
      _status = await api.getTaskStatus();
      _error = null;
      // 任务由运行→停止：拉取游戏截图并发本地通知（app 端实现，不依赖 SRA 本体）
      if (prev?.running == true && _status?.running == false) {
        final shot = await api.getScreenshot();
        await AppNotificationService.instance
            .showWithBytes('SRA 任务完成', '任务已结束运行', shot);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadConfigs() async {
    _configs = await api.getConfigNames();
    notifyListeners();
  }

  Future<bool> runTask({String? configName}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await api.runTask(configName: configName);
      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        await refreshStatus();
      } else {
        _error = '启动任务失败';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = '启动任务出错: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> stopTask() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await api.stopTask();
      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        await refreshStatus();
      } else {
        _error = '停止任务失败';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = '停止任务出错: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
