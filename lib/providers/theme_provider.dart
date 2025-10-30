import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme_config.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
  
  // Light theme
  static final ThemeData lightTheme = LightThemeConfig.themeData();
  
  // Dark theme
  static final ThemeData darkTheme = DarkThemeConfig.themeData();
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey) ?? 'system';
      _themeMode = _themeModeFromString(themeString);
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }
  
  Future<void> setTheme(ThemeMode themeMode) async {
    try {
      _themeMode = themeMode;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeModeString);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }
  
  Future<void> setThemeFromString(String theme) async {
    final themeMode = _themeModeFromString(theme);
    await setTheme(themeMode);
  }
  
  ThemeMode _themeModeFromString(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
  
  String getThemeDescription(String theme) {
    switch (theme) {
      case 'light':
        return 'Light mode';
      case 'dark':
        return 'Dark mode';
      case 'system':
        return 'Follow system';
      default:
        return 'Follow system';
    }
  }
}