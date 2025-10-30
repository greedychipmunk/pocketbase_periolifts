// Test configuration for PocketBase migration testing
// Provides centralized test configuration and environment setup

/// Test configuration settings
class TestConfig {
  // Database settings
  static const bool useInMemoryDb = true;
  static const String testDbName = 'test_periolifts.db';

  // PocketBase test server settings
  static const String testPocketBaseUrl = 'http://localhost:8090';
  static const bool mockPocketBaseByDefault = true;

  // Test user credentials
  static const String testUserEmail = 'test@periolifts.com';
  static const String testUserPassword = 'test123456789';
  static const String testUserName = 'Test User';

  // Performance test thresholds (constitutional requirements)
  static const Duration maxTrackingResponseTime = Duration(milliseconds: 100);
  static const Duration maxStartupTime = Duration(seconds: 3);
  static const double requiredTestCoverage = 0.90; // 90%

  // Test data constraints
  static const int maxTestRecords = 1000;
  static const int bulkTestSize = 100;
  static const int defaultPageSize = 30;

  // Test timeout settings
  static const Duration defaultTestTimeout = Duration(seconds: 30);
  static const Duration performanceTestTimeout = Duration(seconds: 10);
  static const Duration integrationTestTimeout = Duration(minutes: 2);

  // Logging settings for tests
  static const bool enableTestLogging = true;
  static const bool verboseTestOutput = false;

  /// Environment-specific test settings
  static bool get isCI =>
      const String.fromEnvironment('CI', defaultValue: 'false') == 'true';

  static bool get shouldRunIntegrationTests =>
      const String.fromEnvironment(
        'RUN_INTEGRATION_TESTS',
        defaultValue: 'false',
      ) ==
      'true';

  static bool get shouldRunPerformanceTests =>
      const String.fromEnvironment(
        'RUN_PERFORMANCE_TESTS',
        defaultValue: 'false',
      ) ==
      'true';
}

/// Test environment configuration
enum TestEnvironment { unit, integration, performance, endToEnd }

/// Test configuration for different environments
class EnvironmentTestConfig {
  final TestEnvironment environment;
  final Duration timeout;
  final bool useMocks;
  final bool enableLogging;

  const EnvironmentTestConfig({
    required this.environment,
    required this.timeout,
    required this.useMocks,
    required this.enableLogging,
  });

  static const EnvironmentTestConfig unit = EnvironmentTestConfig(
    environment: TestEnvironment.unit,
    timeout: Duration(seconds: 10),
    useMocks: true,
    enableLogging: false,
  );

  static const EnvironmentTestConfig integration = EnvironmentTestConfig(
    environment: TestEnvironment.integration,
    timeout: Duration(seconds: 30),
    useMocks: false,
    enableLogging: true,
  );

  static const EnvironmentTestConfig performance = EnvironmentTestConfig(
    environment: TestEnvironment.performance,
    timeout: Duration(seconds: 60),
    useMocks: false,
    enableLogging: true,
  );

  static const EnvironmentTestConfig endToEnd = EnvironmentTestConfig(
    environment: TestEnvironment.endToEnd,
    timeout: Duration(minutes: 5),
    useMocks: false,
    enableLogging: true,
  );
}
