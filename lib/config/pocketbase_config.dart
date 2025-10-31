import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../constants/app_constants.dart';

/// PocketBase configuration and client management
///
/// Provides a singleton PocketBase client instance with proper configuration
/// for development and production environments.
class PocketBaseConfig {
  static PocketBase? _instance;

  /// Get the singleton PocketBase client instance
  static PocketBase get instance {
    _instance ??= PocketBase(AppConstants.pocketBaseUrl);
    return _instance!;
  }

  /// Reset the instance (useful for testing)
  static void reset() {
    _instance = null;
  }

  /// Initialize PocketBase with custom configuration
  static PocketBase initialize({String? customUrl}) {
    final url = customUrl ?? AppConstants.pocketBaseUrl;
    _instance = PocketBase(url);
    return _instance!;
  }

  /// Get the current PocketBase URL
  static String get currentUrl => instance.baseUrl;

  /// Check if user is authenticated
  static bool get isAuthenticated => instance.authStore.isValid;

  /// Get current user data
  static Map<String, dynamic>? get currentUser {
    final model = instance.authStore.model;
    return model?.toJson() as Map<String, dynamic>?;
  }

  /// Get current auth token
  static String get authToken => instance.authStore.token;
}
