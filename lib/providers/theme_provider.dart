import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  ThemeProvider() {
    SharedPreferences.getInstance().then((p) {
      _isDark = p.getBool('isDark') ?? true;
      notifyListeners();
    });
  }

  void toggle() {
    _isDark = !_isDark;
    SharedPreferences.getInstance().then((p) => p.setBool('isDark', _isDark));
    notifyListeners();
  }
}
