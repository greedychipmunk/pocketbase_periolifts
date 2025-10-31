class AppConstants {
  static const String appName = 'PerioLifts';
  static const String appVersion = '1.0.0';
  static const String tagline = 'Track your period-optimized workouts';

  // PocketBase Configuration
  static const String pocketBaseDevUrl = 'http://localhost:8090';
  static const String pocketBaseProdUrl =
      'https://your-production-pocketbase.com';

  // API Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Offline Storage Configuration
  static const String databaseName = 'periolifts_offline.db';
  static const int databaseVersion = 1;
  static const int maxOfflineRecords = 10000;
  static const int syncBatchSize = 100;

  // Collection Names (PocketBase collections)
  static const String usersCollection = 'users';
  static const String exercisesCollection = 'exercises';
  static const String workoutsCollection = 'workouts';
  static const String workoutSessionsCollection = 'workout_sessions';
  static const String workoutPlansCollection = 'workout_plans';
  static const String workoutHistoryCollection = 'workout_history';

  // Authentication Configuration
  static const Duration tokenRefreshThreshold = Duration(minutes: 30);
  static const Duration sessionTimeout = Duration(hours: 24);

  // Performance Thresholds (Constitutional Requirements)
  static const Duration maxTrackingResponseTime = Duration(milliseconds: 100);
  static const Duration maxStartupTime = Duration(seconds: 3);
  static const double requiredTestCoverage = 0.90; // 90%

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const int defaultPageSize = 30;
  static const int maxPageSize = 100;

  // Error Messages
  static const String networkErrorMessage =
      'Network connection failed. Data saved offline.';
  static const String authErrorMessage =
      'Authentication failed. Please log in again.';
  static const String syncErrorMessage =
      'Sync failed. Will retry automatically.';
  static const String dataNotFoundMessage = 'Requested data not found.';

  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableAutoSync = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableDebugLogging = false; // Should be false in production

  // Environment Detection
  static bool get isProduction =>
      const String.fromEnvironment('ENVIRONMENT') == 'production';

  static bool get isDevelopment =>
      const String.fromEnvironment('ENVIRONMENT') == 'development' ||
      const String.fromEnvironment('ENVIRONMENT').isEmpty;

  static bool get isTest =>
      const String.fromEnvironment('ENVIRONMENT') == 'test';

  /// Get the appropriate PocketBase URL based on environment
  static String get pocketBaseUrl {
    if (isProduction) {
      return pocketBaseProdUrl;
    } else {
      return pocketBaseDevUrl;
    }
  }

  /// Get debug mode status
  static bool get isDebugMode {
    if (isProduction) return false;
    return enableDebugLogging;
  }
}
