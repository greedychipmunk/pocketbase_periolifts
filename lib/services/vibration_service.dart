import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Service for handling device vibration
class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  /// Check if vibration is enabled in app settings
  Future<bool> isVibrationEnabledInSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('enableVibration') ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking vibration settings: $e');
      }
      return true; // Default to enabled
    }
  }

  /// Check if device has vibration capability
  Future<bool> hasVibrationCapability() async {
    try {
      return await Vibration.hasVibrator() ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking vibration capability: $e');
      }
      return false;
    }
  }

  /// Vibrate device for rest timer completion
  Future<void> vibrateForRestTimer() async {
    try {
      // Check if vibration is enabled in settings
      final vibrationEnabled = await isVibrationEnabledInSettings();
      if (!vibrationEnabled) {
        return;
      }

      // Check if device has vibration capability
      final hasVibrator = await hasVibrationCapability();
      if (!hasVibrator) {
        if (kDebugMode) {
          print('Device does not have vibration capability');
        }
        return;
      }

      // Create a pattern for rest timer completion
      // 200ms vibration, 100ms pause, 200ms vibration, 100ms pause, 300ms vibration
      const pattern = [0, 200, 100, 200, 100, 300];
      
      // Vibrate with pattern
      await Vibration.vibrate(pattern: pattern);

      if (kDebugMode) {
        print('Rest timer completion vibration triggered');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering vibration: $e');
      }
    }
  }

  /// Vibrate device with a simple vibration
  Future<void> vibrateSimple({int duration = 500}) async {
    try {
      // Check if vibration is enabled in settings
      final vibrationEnabled = await isVibrationEnabledInSettings();
      if (!vibrationEnabled) {
        return;
      }

      // Check if device has vibration capability
      final hasVibrator = await hasVibrationCapability();
      if (!hasVibrator) {
        return;
      }

      // Simple vibration
      await Vibration.vibrate(duration: duration);
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering simple vibration: $e');
      }
    }
  }

  /// Cancel any ongoing vibration
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling vibration: $e');
      }
    }
  }
}