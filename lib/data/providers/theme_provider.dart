import 'package:flutter/material.dart';
import 'package:hrms/common/constants/constant.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void saveTheme(bool isDark) {
    sharedPreferences.setBool(themeKey, isDark);
  }

  bool? getTheme() {
    return sharedPreferences.getBool(themeKey);
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _isDarkMode = _themeMode == ThemeMode.dark;
    notifyListeners();
    saveTheme(isDark);
  }

  Future<void> _loadTheme() async {
    final bool? isDark = getTheme();
    if (isDark == null) {
      _themeMode = ThemeMode.system;
      _isDarkMode =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    } else {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _isDarkMode = isDark;
    }
    notifyListeners();
  }
}
