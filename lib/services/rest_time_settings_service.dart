import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing rest time settings and preferences
class RestTimeSettingsService {
  static const String _useDefaultRestTimeKey = 'useDefaultRestTime';
  static const String _defaultRestTimeSecondsKey = 'defaultRestTimeSeconds';
  
  bool? _useDefaultRestTime;
  int? _defaultRestTimeSeconds;
  
  /// Get whether to use default rest time override from cache or SharedPreferences
  Future<bool> getUseDefaultRestTime() async {
    if (_useDefaultRestTime != null) {
      return _useDefaultRestTime!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _useDefaultRestTime = prefs.getBool(_useDefaultRestTimeKey) ?? false;
    return _useDefaultRestTime!;
  }
  
  /// Set whether to use default rest time override and save to SharedPreferences
  Future<void> setUseDefaultRestTime(bool useDefault) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDefaultRestTimeKey, useDefault);
    _useDefaultRestTime = useDefault;
  }
  
  /// Get default rest time in seconds from cache or SharedPreferences
  Future<int> getDefaultRestTimeSeconds() async {
    if (_defaultRestTimeSeconds != null) {
      return _defaultRestTimeSeconds!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _defaultRestTimeSeconds = prefs.getInt(_defaultRestTimeSecondsKey) ?? 120;
    return _defaultRestTimeSeconds!;
  }
  
  /// Set default rest time in seconds and save to SharedPreferences
  Future<void> setDefaultRestTimeSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultRestTimeSecondsKey, seconds);
    _defaultRestTimeSeconds = seconds;
  }
  
  /// Get the effective rest time for a workout set
  /// Returns either the default rest time (if override is enabled) or the program rest time
  Future<Duration> getEffectiveRestTime(Duration? programRestTime) async {
    final useDefault = await getUseDefaultRestTime();
    
    if (useDefault) {
      final defaultSeconds = await getDefaultRestTimeSeconds();
      return Duration(seconds: defaultSeconds);
    } else {
      // Use program rest time if available, otherwise fall back to default
      if (programRestTime != null && programRestTime.inSeconds > 0) {
        return programRestTime;
      } else {
        final defaultSeconds = await getDefaultRestTimeSeconds();
        return Duration(seconds: defaultSeconds);
      }
    }
  }
  
  /// Clear cache to force reload from SharedPreferences
  void clearCache() {
    _useDefaultRestTime = null;
    _defaultRestTimeSeconds = null;
  }
}