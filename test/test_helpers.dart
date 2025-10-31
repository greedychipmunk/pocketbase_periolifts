// Test helpers and utilities for PocketBase migration testing
// Provides common test setup, data factories, and assertions

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'mocks/generate_mocks.dart';

/// Test environment setup and utilities
class TestHelpers {
  static bool _initialized = false;

  /// Initialize test environment
  static Future<void> setupTestEnvironment() async {
    if (_initialized) return;

    // Setup sqflite for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    _initialized = true;
  }

  /// Get a test database instance
  static Future<Database> createTestDatabase({String? dbName}) async {
    await setupTestEnvironment();

    // Use in-memory database for tests
    return await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        // Create the same tables as the main app
        await _createTestTables(db);
      },
    );
  }

  /// Create test database tables (simplified version)
  static Future<void> _createTestTables(Database db) async {
    await db.transaction((txn) async {
      // Exercises table
      await txn.execute('''
        CREATE TABLE exercises (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          description TEXT,
          muscle_groups TEXT,
          equipment TEXT,
          instructions TEXT,
          created TEXT NOT NULL,
          updated TEXT NOT NULL,
          synced INTEGER DEFAULT 0
        )
      ''');

      // Workouts table
      await txn.execute('''
        CREATE TABLE workouts (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          created TEXT NOT NULL,
          updated TEXT NOT NULL,
          synced INTEGER DEFAULT 0
        )
      ''');

      // Workout sessions table
      await txn.execute('''
        CREATE TABLE workout_sessions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          workout_id TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT,
          notes TEXT,
          created TEXT NOT NULL,
          updated TEXT NOT NULL,
          synced INTEGER DEFAULT 0
        )
      ''');

      // Sync queue table
      await txn.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          record_id TEXT NOT NULL,
          operation TEXT NOT NULL,
          data TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    });
  }

  /// Clean up test database
  static Future<void> cleanupTestDatabase(Database db) async {
    await db.close();
  }

  /// Create test PocketBase client
  static TestPocketBaseClient createTestPocketBaseClient() {
    return TestPocketBaseClient();
  }

  /// Test data factories
  static Map<String, dynamic> createTestUser({
    String? id,
    String? email,
    String? name,
  }) {
    return {
      'id': id ?? 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      'email': email ?? 'test@example.com',
      'name': name ?? 'Test User',
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createTestWorkout({
    String? id,
    String? userId,
    String? name,
  }) {
    return {
      'id': id ?? 'test_workout_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': userId ?? 'test_user_123',
      'name': name ?? 'Test Workout',
      'description': 'Test workout description',
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createTestExercise({
    String? id,
    String? name,
    String? category,
  }) {
    return {
      'id': id ?? 'test_exercise_${DateTime.now().millisecondsSinceEpoch}',
      'name': name ?? 'Test Exercise',
      'category': category ?? 'strength',
      'muscle_groups': '["chest", "arms"]', // JSON string
      'equipment': 'barbell',
      'instructions': 'Test exercise instructions',
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createTestWorkoutSession({
    String? id,
    String? userId,
    String? workoutId,
  }) {
    return {
      'id': id ?? 'test_session_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': userId ?? 'test_user_123',
      'workout_id': workoutId ?? 'test_workout_456',
      'start_time': DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
      'end_time': DateTime.now().toIso8601String(),
      'notes': 'Test session notes',
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
    };
  }

  /// Custom test matchers and assertions
  static Matcher isValidPocketBaseRecord() {
    return predicate<Map<String, dynamic>>((record) {
      return record.containsKey('id') &&
          record.containsKey('created') &&
          record.containsKey('updated') &&
          record['id'] is String &&
          record['created'] is String &&
          record['updated'] is String;
    }, 'is a valid PocketBase record');
  }

  static Matcher hasValidTimestamps() {
    return predicate<Map<String, dynamic>>((record) {
      try {
        DateTime.parse(record['created'] as String);
        DateTime.parse(record['updated'] as String);
        return true;
      } catch (e) {
        return false;
      }
    }, 'has valid ISO8601 timestamps');
  }

  /// Performance test helpers
  static Future<Duration> measureAsyncOperation(
    Future<void> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Measure performance of an operation with expectation
  static Future<void> measurePerformance(
    Future<void> Function() operation, {
    int? maxDurationMs,
    Duration? maxDuration,
    String? testName,
  }) async {
    final effectiveMaxDuration =
        maxDuration ??
        (maxDurationMs != null
            ? Duration(milliseconds: maxDurationMs)
            : const Duration(milliseconds: 100));

    final duration = await measureAsyncOperation(operation);
    expect(
      duration,
      lessThan(effectiveMaxDuration),
      reason: testName != null
          ? '$testName took ${duration.inMilliseconds}ms, expected < ${effectiveMaxDuration.inMilliseconds}ms'
          : 'Operation took ${duration.inMilliseconds}ms, expected < ${effectiveMaxDuration.inMilliseconds}ms',
    );
  }

  /// Clean up test environment
  static Future<void> cleanupTestEnvironment() async {
    // Reset any global state
    // In a real test, this might clean up PocketBase connections, etc.
    _initialized = false;
  }

  static Future<void> expectFastOperation(
    Future<void> Function() operation, {
    Duration maxDuration = const Duration(milliseconds: 100),
  }) async {
    final duration = await measureAsyncOperation(operation);
    expect(
      duration,
      lessThan(maxDuration),
      reason:
          'Operation took ${duration.inMilliseconds}ms, expected < ${maxDuration.inMilliseconds}ms',
    );
  }

  /// Test group helpers
  static void runOfflineTests(
    String description,
    Future<void> Function() tests,
  ) {
    group('Offline Tests: $description', () {
      setUpAll(() async {
        await setupTestEnvironment();
      });

      tests();
    });
  }

  static void runOnlineTests(
    String description,
    Future<void> Function() tests,
  ) {
    group('Online Tests: $description', () {
      setUpAll(() async {
        await setupTestEnvironment();
        // TODO: Setup test PocketBase server connection when available
      });

      tests();
    });
  }

  static void runPerformanceTests(
    String description,
    Future<void> Function() tests,
  ) {
    group('Performance Tests: $description', () {
      setUpAll(() async {
        await setupTestEnvironment();
      });

      tests();
    });
  }
}

/// Test constants and configuration
class TestConstants {
  static const String testPocketBaseUrl = 'http://localhost:8090';
  static const String testUserEmail = 'test@example.com';
  static const String testUserPassword = 'test123456';

  // Performance thresholds per constitutional requirements
  static const Duration maxTrackingResponseTime = Duration(milliseconds: 100);
  static const Duration maxStartupTime = Duration(seconds: 3);
  static const double minTestCoverage = 0.90; // 90%

  // Test data limits
  static const int maxTestRecords = 1000;
  static const int bulkOperationSize = 100;
}

/// Test utilities for data validation
class TestValidators {
  /// Validate that a record matches expected PocketBase structure
  static void validatePocketBaseRecord(Map<String, dynamic> record) {
    expect(record, TestHelpers.isValidPocketBaseRecord());
    expect(record, TestHelpers.hasValidTimestamps());
  }

  /// Validate workout data structure
  static void validateWorkoutData(Map<String, dynamic> workout) {
    validatePocketBaseRecord(workout);
    expect(workout, containsPair('name', isA<String>()));
    expect(workout, containsPair('user_id', isA<String>()));
  }

  /// Validate exercise data structure
  static void validateExerciseData(Map<String, dynamic> exercise) {
    validatePocketBaseRecord(exercise);
    expect(exercise, containsPair('name', isA<String>()));
    expect(exercise, containsPair('category', isA<String>()));
    expect(exercise, containsPair('muscle_groups', isA<String>()));
  }

  /// Validate session data structure
  static void validateSessionData(Map<String, dynamic> session) {
    validatePocketBaseRecord(session);
    expect(session, containsPair('user_id', isA<String>()));
    expect(session, containsPair('workout_id', isA<String>()));
    expect(session, containsPair('start_time', isA<String>()));
  }
}
