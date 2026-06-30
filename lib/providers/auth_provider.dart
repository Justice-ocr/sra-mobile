import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storage;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiService, this._storage) {
    _checkLoginStatus();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _checkLoginStatus() async {
    final serverUrl = _storage.getServerUrl();
    final token = await _storage.getToken();

    if (serverUrl != null && token != null) {
      _apiService.configure(serverUrl, token);
      final isValid = await _apiService.verifyToken(serverUrl, token);
      _isAuthenticated = isValid;
      notifyListeners();
    }
  }

  Future<bool> login(String serverUrl, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isValid = await _apiService.verifyToken(serverUrl, token);

      if (isValid) {
        await _storage.saveServerUrl(serverUrl);
        await _storage.saveToken(token);
        _apiService.configure(serverUrl, token);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Token验证失败';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '连接失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _isAuthenticated = false;
    notifyListeners();
  }
}
