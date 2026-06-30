import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  SharedPreferences? _prefs;

  static const String _keyToken = 'sra_token';
  static const String _keyServerUrl = 'sra_server_url';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _keyToken);
  }

  Future<void> saveServerUrl(String url) async {
    await _prefs?.setString(_keyServerUrl, url);
  }

  String? getServerUrl() {
    return _prefs?.getString(_keyServerUrl);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
}
