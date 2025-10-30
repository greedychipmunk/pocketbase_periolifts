import 'package:flutter/material.dart';
import '../services/rest_time_settings_service.dart';

/// Provider for managing rest time settings across the app
class RestTimeSettingsProvider extends ChangeNotifier {
  final RestTimeSettingsService _service = RestTimeSettingsService();
  bool _useDefaultRestTime = false;
  int _defaultRestTimeSeconds = 120;
  bool _isLoading = true;

  bool get useDefaultRestTime => _useDefaultRestTime;
  int get defaultRestTimeSeconds => _defaultRestTimeSeconds;
  bool get isLoading => _isLoading;
  
  RestTimeSettingsProvider() {
    _loadSettings();
  }
  
  /// Load current settings from SharedPreferences
  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _useDefaultRestTime = await _service.getUseDefaultRestTime();
      _defaultRestTimeSeconds = await _service.getDefaultRestTimeSeconds();
    } catch (e) {
      // If loading fails, keep defaults and log error
      print('Error loading rest time settings: $e');
      _useDefaultRestTime = false;
      _defaultRestTimeSeconds = 120;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Set whether to use default rest time override
  Future<void> setUseDefaultRestTime(bool useDefault) async {
    if (_useDefaultRestTime == useDefault) return;
    
    _useDefaultRestTime = useDefault;
    notifyListeners();
    
    try {
      await _service.setUseDefaultRestTime(useDefault);
      // Clear service cache to ensure consistency
      _service.clearCache();
    } catch (e) {
      // If saving fails, revert local state and log error
      print('Error saving rest time override setting: $e');
      _useDefaultRestTime = !useDefault;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Set default rest time in seconds
  Future<void> setDefaultRestTimeSeconds(int seconds) async {
    if (_defaultRestTimeSeconds == seconds) return;
    
    _defaultRestTimeSeconds = seconds;
    notifyListeners();
    
    try {
      await _service.setDefaultRestTimeSeconds(seconds);
      // Clear service cache to ensure consistency
      _service.clearCache();
    } catch (e) {
      // If saving fails, revert local state and log error  
      print('Error saving default rest time: $e');
      // Reload from service to get previous value
      try {
        _defaultRestTimeSeconds = await _service.getDefaultRestTimeSeconds();
      } catch (_) {
        _defaultRestTimeSeconds = 120; // Fallback
      }
      notifyListeners();
      rethrow;
    }
  }
  
  /// Get the effective rest time for a workout set
  Future<Duration> getEffectiveRestTime(Duration? programRestTime) async {
    return await _service.getEffectiveRestTime(programRestTime);
  }
  
  /// Get formatted description of current rest time setting
  String getDescription() {
    if (_useDefaultRestTime) {
      return 'Override: ${_defaultRestTimeSeconds}s (${(_defaultRestTimeSeconds / 60).toStringAsFixed(1)}min)';
    } else {
      return 'Use program rest times';
    }
  }
}