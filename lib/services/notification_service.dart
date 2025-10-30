import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);
    _isInitialized = true;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      return await iOSPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
    }
    return false;
  }

  /// Check if notifications are enabled in app settings
  Future<bool> areNotificationsEnabledInSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('enableNotifications') ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking notification settings: $e');
      }
      return true; // Default to enabled
    }
  }

  /// Check if sound effects are enabled in app settings
  Future<bool> areSoundEffectsEnabledInSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('enableSounds') ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking sound effects settings: $e');
      }
      return true; // Default to enabled
    }
  }

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

  /// Check if notifications are allowed by the system
  Future<bool> areNotificationsAllowedBySystem() async {
    if (!_isInitialized) await initialize();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final settings = await iOSPlugin?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return false;
  }

  /// Show notification for rest timer completion
  Future<void> showRestTimerCompletionNotification() async {
    try {
      // Check if notifications should be shown
      final notificationsEnabled = await areNotificationsEnabledInSettings();
      final systemAllowsNotifications = await areNotificationsAllowedBySystem();

      if (!notificationsEnabled || !systemAllowsNotifications) {
        return;
      }

      if (!_isInitialized) await initialize();

      // Check if sound effects and vibration are enabled
      final soundEffectsEnabled = await areSoundEffectsEnabledInSettings();
      final vibrationEnabled = await isVibrationEnabledInSettings();

      // Configure Android notification details with conditional sound and vibration
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'rest_timer_channel',
        'Rest Timer',
        channelDescription: 'Notifications for rest timer completion',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: false,
        playSound: soundEffectsEnabled,
        enableVibration: vibrationEnabled,
      );

      // Configure iOS notification details with conditional sound
      final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundEffectsEnabled,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notifications.show(
        1, // notification id
        'Rest Timer Complete!',
        'Your rest period has finished. Time for the next set!',
        notificationDetails,
      );

      if (kDebugMode) {
        print('Rest timer completion notification shown');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing rest timer notification: $e');
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    if (!_isInitialized) await initialize();
    await _notifications.cancelAll();
  }

  /// Cancel notification by id
  Future<void> cancel(int id) async {
    if (!_isInitialized) await initialize();
    await _notifications.cancel(id);
  }
}