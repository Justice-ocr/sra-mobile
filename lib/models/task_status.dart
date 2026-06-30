class TaskStatus {
  final bool running;
  final String state;
  final String? taskName;
  final List<String>? configNames;

  TaskStatus({
    required this.running,
    required this.state,
    this.taskName,
    this.configNames,
  });

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    return TaskStatus(
      running: json['running'] ?? false,
      state: json['state'] ?? 'unknown',
      taskName: json['taskName'],
      configNames: json['configNames'] != null
          ? List<String>.from(json['configNames'])
          : null,
    );
  }

  String get displayState {
    const stateMap = {
      'running': '运行中',
      'stopping': '停止中',
      'completed': '已完成',
      'stopped': '已停止',
      'failed': '失败',
      'idle': '空闲',
    };
    return stateMap[state] ?? state;
  }
}
