import 'package:flutter/material.dart';
import 'package:webnox_taskops/services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    final savedTheme = LocalStorageService().storage.getString(_themeKey);
    if (savedTheme != null) {
      if (savedTheme == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      }
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    await LocalStorageService()
        .storage
        .setString(_themeKey, _getThemeString(_themeMode));
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await LocalStorageService()
        .storage
        .setString(_themeKey, _getThemeString(mode));
    notifyListeners();
  }

  String _getThemeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }
}
