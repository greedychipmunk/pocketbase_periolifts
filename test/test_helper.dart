// Test environment configuration and shared utilities
// This provides consistent test setup across all test files

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'mocks/generate_mocks.dart';

/// Shared test configuration and setup utilities
class TestHelper {
  static late TestPocketBaseClient mockPocketBaseClient;
  static bool _isInitialized = false;

  /// Initialize test environment
  /// Must be called once before running any tests
  static Future<void> initializeTestEnvironment() async {
    if (_isInitialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize sqflite for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Mock PocketBase client
    mockPocketBaseClient = TestPocketBaseClient();

    _isInitialized = true;
  }

  /// Reset test environment between tests
  static Future<void> resetTestEnvironment() async {
    await initializeTestEnvironment();

    // Reset mock client state
    mockPocketBaseClient.dispose();
    mockPocketBaseClient = TestPocketBaseClient();
  }

  /// Configure mock authentication state
  static void setMockAuthState({
    bool isAuthenticated = false,
    Map<String, dynamic>? user,
    String? token,
  }) {
    if (isAuthenticated && user != null) {
      mockPocketBaseClient.authStore.setAuth(user, token ?? 'mock_token');
    } else {
      mockPocketBaseClient.authStore.clear();
    }
  }

  /// Create a basic test user map
  static Map<String, dynamic> createTestUserMap({
    String id = 'test_user_123',
    String email = 'test@example.com',
    String name = 'Test User',
    bool verified = true,
  }) {
    return {
      'id': id,
      'email': email,
      'name': name,
      'verified': verified,
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
    };
  }

  /// Setup basic mock data for collections
  static void setupMockCollectionData() {
    // Setup test users
    final userCollection = mockPocketBaseClient.collection('users');
    userCollection.addTestRecord('test_user_123', {
      'email': 'test@example.com',
      'name': 'Test User',
      'verified': true,
    });

    // Setup test exercises
    final exerciseCollection = mockPocketBaseClient.collection('exercises');
    exerciseCollection.addTestRecord('test_exercise_123', {
      'name': 'Test Exercise',
      'category': 'strength',
      'description': 'Test exercise description',
      'targetMuscles': ['chest'],
      'instructions': ['Step 1', 'Step 2'],
      'equipment': ['barbell'],
      'difficulty': 'intermediate',
    });

    // Setup test workouts
    final workoutCollection = mockPocketBaseClient.collection('workouts');
    workoutCollection.addTestRecord('test_workout_123', {
      'name': 'Test Workout',
      'description': 'Test workout description',
      'exercises': [
        {
          'exerciseId': 'test_exercise_123',
          'exerciseName': 'Test Exercise',
          'sets': [
            {'reps': 10, 'weight': 100},
            {'reps': 8, 'weight': 105},
          ],
          'restTime': 60,
          'notes': 'Test notes',
        },
      ],
      'estimatedDuration': 45,
      'difficulty': 'intermediate',
      'userId': 'test_user_123',
    });
  }

  /// Simulate network error conditions
  static void simulateNetworkError({String? message, int? statusCode}) {
    mockPocketBaseClient.setConnected(false);

    // Configure all collections to throw network errors
    final collections = [
      'users',
      'exercises',
      'workouts',
      'workout_sessions',
      'workout_history',
    ];
    for (final collectionName in collections) {
      final collection = mockPocketBaseClient.collection(collectionName);
      collection.setMockError(
        message ?? 'Network connection failed',
        statusCode: statusCode ?? 500,
      );
    }
  }

  /// Clear network error simulation
  static void clearNetworkError() {
    mockPocketBaseClient.setConnected(true);

    // Clear errors from all collections
    final collections = [
      'users',
      'exercises',
      'workouts',
      'workout_sessions',
      'workout_history',
    ];
    for (final collectionName in collections) {
      final collection = mockPocketBaseClient.collection(collectionName);
      collection.clearMockError();
    }
  }

  /// Performance testing helpers
  static Future<Duration> measurePerformance(
    Future<void> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Verify constitutional performance requirements
  static void verifyPerformanceRequirement(
    Duration actual,
    Duration expected,
    String operation,
  ) {
    expect(
      actual.inMilliseconds,
      lessThanOrEqualTo(expected.inMilliseconds),
      reason:
          '$operation took ${actual.inMilliseconds}ms, expected ≤${expected.inMilliseconds}ms (constitutional requirement)',
    );
  }

  /// Common test teardown
  static Future<void> tearDown() async {
    await resetTestEnvironment();
  }
}
