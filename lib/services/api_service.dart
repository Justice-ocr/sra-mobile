import 'package:dio/dio.dart';
import '../models/task_status.dart';

class ApiService {
  late final Dio _dio;
  String? _baseUrl;
  String? _token;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_baseUrl != null) {
            options.baseUrl = _baseUrl!;
          }
          if (_token != null) {
            options.headers['X-Api-Key'] = _token;
          }
          return handler.next(options);
        },
      ),
    );
  }

  void configure(String baseUrl, String token) {
    _baseUrl = baseUrl;
    _token = token;
  }

  Future<bool> verifyToken(String baseUrl, String token) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/Auth/verify',
        data: {'token': token},
      );
      return response.data['ok'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<TaskStatus> getTaskStatus() async {
    final response = await _dio.get('/api/Task/status');
    return TaskStatus.fromJson(response.data);
  }

  Future<bool> runTask({String? configName}) async {
    try {
      final response = await _dio.post(
        '/api/Task/run',
        data: {
          if (configName != null) 'configName': configName,
          'persist': true,
        },
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stopTask() async {
    try {
      final response = await _dio.post('/api/Task/stop');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getConfigNames() async {
    try {
      final response = await _dio.get('/api/Configs');
      return List<String>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getConfig(String name) async {
    try {
      final response = await _dio.get('/api/Configs/$name');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveConfig(String name, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/Configs/$name', data: data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final response = await _dio.get('/api/Settings');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveSettings(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/Settings', data: data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getScriptRepos() async {
    try {
      final response = await _dio.get('/api/Extensions/repos');
      return List<dynamic>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  // 锄大地任务定义（副本/关卡元数据）
  Future<List<dynamic>> getTaskDefinitions() async {
    try {
      final response = await _dio.get('/api/Metadata/trailblaze-power/tasks');
      return List<dynamic>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  // 自动对话设置
  Future<bool> saveAutoPlot(bool enabled, bool skipPlot) async {
    try {
      final response = await _dio.post('/api/Extensions/auto-plot',
          data: {'enabled': enabled, 'skipPlot': skipPlot});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 运行抽卡资源预测
  Future<bool> runWarpForecast() async {
    try {
      final response = await _dio.post('/api/Extensions/warp-forecast/run');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // SSE 日志流：返回原始 Stream<String>
  Stream<String> streamLogs() {
    final uri = Uri.parse('${_baseUrl!}/api/Task/logs/stream?access_token=$_token');
    return Stream.fromFuture(
      _dio.get<ResponseBody>(
        uri.toString(),
        options: Options(responseType: ResponseType.stream),
      ),
    ).asyncExpand((resp) {
      return resp.data!.stream
          .map((chunk) => String.fromCharCodes(chunk))
          .where((s) => s.trim().isNotEmpty);
    });
  }
}
