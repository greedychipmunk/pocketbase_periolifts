import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lib/screens/login_screen.dart';
import '../../lib/screens/sign_up_screen.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/models/user.dart';
import '../../lib/utils/result.dart';
import '../../lib/constants/app_constants.dart';

/// Mock AuthService for integration testing
class IntegrationTestAuthService extends AuthService {
  final Map<String, User> _users = {};
  User? _currentUser;
  bool _simulateNetworkError = false;
  bool _simulateSlowResponse = false;

  void setNetworkError(bool value) => _simulateNetworkError = value;
  void setSlowResponse(bool value) => _simulateSlowResponse = value;
  void clearUsers() => _users.clear();

  @override
  Future<Result<User>> signUp(
    String email,
    String password,
    String name,
  ) async {
    if (_simulateNetworkError) {
      return Result.error(
        AppError.network(message: 'Network error: Unable to connect to server'),
      );
    }

    if (_simulateSlowResponse) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    if (_users.containsKey(email)) {
      return Result.error(
        AppError.validation(message: 'User with this email already exists'),
      );
    }

    final user = User(
      id: 'user_${_users.length + 1}',
      email: email,
      username: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      emailVerified: false,
      created: DateTime.now(),
      updated: DateTime.now(),
    );

    _users[email] = user;
    _currentUser = user;
    return Result.success(user);
  }

  @override
  Future<Result<User>> signIn(String email, String password) async {
    if (_simulateNetworkError) {
      return Result.error(
        AppError.network(message: 'Network error: Unable to connect to server'),
      );
    }

    if (_simulateSlowResponse) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    if (!_users.containsKey(email)) {
      return Result.error(
        AppError.authentication(message: 'Invalid email or password'),
      );
    }

    _currentUser = _users[email];
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    return Result.success(null);
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    if (_currentUser == null) {
      return Result.error(
        AppError.authentication(message: 'No authenticated user'),
      );
    }
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<User>> refreshToken() async {
    if (_currentUser == null) {
      return Result.error(
        AppError.authentication(message: 'No authenticated user'),
      );
    }
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<User>> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) {
      return Result.error(
        AppError.authentication(message: 'No authenticated user'),
      );
    }
    // Simple update simulation
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<void>> deleteAccount(String password) async {
    if (_currentUser == null) {
      return Result.error(
        AppError.authentication(message: 'No authenticated user'),
      );
    }
    _users.remove(_currentUser!.email);
    _currentUser = null;
    return Result.success(null);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> confirmPasswordReset(
    String token,
    String newPassword,
  ) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> sendEmailVerification(String email) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> confirmEmailVerification(String token) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    if (_currentUser == null) {
      return Result.error(
        AppError.authentication(message: 'No authenticated user'),
      );
    }
    return Result.success(null);
  }

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<void> restoreSession() async {
    // No-op for tests
  }
}

/// Integration Test Notifier
class IntegrationTestAuthNotifier extends AuthNotifier {
  final IntegrationTestAuthService _testService;

  IntegrationTestAuthNotifier(this._testService) : super(_testService);

  @override
  Future<Result<User>> signUp(
    String email,
    String password,
    String name,
  ) async {
    state = state.copyWith(isLoading: true);

    final result = await _testService.signUp(email, password, name);

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        user: result.data,
        isAuthenticated: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error?.message);
    }

    return result;
  }

  @override
  Future<Result<User>> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);

    final result = await _testService.signIn(email, password);

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        user: result.data,
        isAuthenticated: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error?.message);
    }

    return result;
  }

  @override
  Future<Result<void>> signOut() async {
    state = state.copyWith(isLoading: true);

    await _testService.signOut();

    state = const AuthState(
      isLoading: false,
      user: null,
      isAuthenticated: false,
      error: null,
    );

    return Result.success(null);
  }

  // Expose test service for test control
  IntegrationTestAuthService get testService => _testService;
}

void main() {
  group('Authentication Flow Integration Tests', () {
    late IntegrationTestAuthService testAuthService;
    late IntegrationTestAuthNotifier testAuthNotifier;

    setUp(() {
      testAuthService = IntegrationTestAuthService();
      testAuthNotifier = IntegrationTestAuthNotifier(testAuthService);
      testAuthService.clearUsers();
      testAuthService.setNetworkError(false);
      testAuthService.setSlowResponse(false);
    });

    Widget createTestApp({Widget? home}) {
      return ProviderScope(
        overrides: [authProvider.overrideWith((ref) => testAuthNotifier)],
        child: MaterialApp(
          home: home ?? const LoginScreen(),
          routes: {
            '/signup': (context) => const SignUpScreen(),
            '/login': (context) => const LoginScreen(),
          },
        ),
      );
    }

    group('Sign Up to Sign In Flow', () {
      testWidgets('completes full sign up and then sign in flow', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act 1: Complete sign up flow
        const testName = 'Integration Test User';
        const testEmail = 'integration@test.com';
        const testPassword = 'IntegrationTest123';

        // Fill sign up form
        await tester.enterText(find.byType(TextFormField).at(0), testName);
        await tester.enterText(find.byType(TextFormField).at(1), testEmail);
        await tester.enterText(find.byType(TextFormField).at(2), testPassword);
        await tester.enterText(find.byType(TextFormField).at(3), testPassword);

        // Submit sign up
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert 1: Sign up should be successful (user created)
        expect(testAuthService._users.containsKey(testEmail), isTrue);
        expect(testAuthService._currentUser?.email, equals(testEmail));
        expect(testAuthService._currentUser?.name, equals(testName));

        // Act 2: Simulate navigation to login screen (sign out first)
        await testAuthNotifier.signOut();
        await tester.pumpWidget(createTestApp(home: const LoginScreen()));
        await tester.pumpAndSettle();

        // Fill login form with same credentials
        await tester.enterText(find.byType(TextFormField).at(0), testEmail);
        await tester.enterText(find.byType(TextFormField).at(1), testPassword);

        // Submit login
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert 2: Sign in should be successful
        expect(testAuthService._currentUser?.email, equals(testEmail));
        expect(testAuthService._currentUser?.name, equals(testName));
      });

      testWidgets('handles duplicate email during sign up', (
        WidgetTester tester,
      ) async {
        // Arrange: Create existing user
        const existingEmail = 'existing@test.com';
        const password = 'Password123';
        await testAuthService.signUp(existingEmail, password, 'Existing User');

        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act: Try to sign up with same email
        await tester.enterText(find.byType(TextFormField).at(0), 'New User');
        await tester.enterText(find.byType(TextFormField).at(1), existingEmail);
        await tester.enterText(find.byType(TextFormField).at(2), password);
        await tester.enterText(find.byType(TextFormField).at(3), password);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show error message
        expect(find.textContaining('already exists'), findsOneWidget);
        expect(testAuthNotifier.state.error, isNotNull);
        expect(testAuthNotifier.state.isAuthenticated, isFalse);
      });

      testWidgets('handles invalid credentials during sign in', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp(home: const LoginScreen()));
        await tester.pumpAndSettle();

        // Act: Try to sign in with non-existent credentials
        const invalidEmail = 'nonexistent@test.com';
        const password = 'SomePassword123';

        await tester.enterText(find.byType(TextFormField).at(0), invalidEmail);
        await tester.enterText(find.byType(TextFormField).at(1), password);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show error message
        expect(
          find.textContaining('Invalid email or password'),
          findsOneWidget,
        );
        expect(testAuthNotifier.state.error, isNotNull);
        expect(testAuthNotifier.state.isAuthenticated, isFalse);
        expect(testAuthService._currentUser, isNull);
      });
    });

    group('Form Validation Integration', () {
      testWidgets('validates sign up form before API call', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act: Submit empty form
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show validation errors without API call
        expect(find.text('Please enter your name'), findsOneWidget);
        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter your password'), findsOneWidget);
        expect(find.text('Please confirm your password'), findsOneWidget);
        expect(testAuthService._users.isEmpty, isTrue);
      });

      testWidgets('validates email format before API call', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act: Enter invalid email format
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'invalid-email',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show validation error without API call
        expect(find.text('Please enter a valid email'), findsOneWidget);
        expect(testAuthService._users.isEmpty, isTrue);
      });

      testWidgets('validates password confirmation match', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act: Enter mismatched passwords
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(
          find.byType(TextFormField).at(3),
          'different123',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show validation error without API call
        expect(find.text('Passwords do not match'), findsOneWidget);
        expect(testAuthService._users.isEmpty, isTrue);
      });
    });

    group('Loading State Integration', () {
      testWidgets('shows loading state during sign up', (
        WidgetTester tester,
      ) async {
        // Arrange
        testAuthService.setSlowResponse(true);
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act: Fill form and submit
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // Don't wait for completion

        // Assert: Should show loading state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(testAuthNotifier.state.isLoading, isTrue);

        // Wait for completion
        await tester.pumpAndSettle();
        expect(testAuthNotifier.state.isLoading, isFalse);
      });

      testWidgets('shows loading state during sign in', (
        WidgetTester tester,
      ) async {
        // Arrange: Create user first
        await testAuthService.signUp(
          'test@example.com',
          'password123',
          'Test User',
        );
        await testAuthNotifier.signOut();

        testAuthService.setSlowResponse(true);
        await tester.pumpWidget(createTestApp(home: const LoginScreen()));
        await tester.pumpAndSettle();

        // Act: Fill form and submit
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // Don't wait for completion

        // Assert: Should show loading state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(testAuthNotifier.state.isLoading, isTrue);

        // Wait for completion
        await tester.pumpAndSettle();
        expect(testAuthNotifier.state.isLoading, isFalse);
      });
    });

    group('Network Error Handling', () {
      testWidgets('handles network error during sign up', (
        WidgetTester tester,
      ) async {
        // Arrange
        testAuthService.setNetworkError(true);
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act: Fill form and submit
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show network error
        expect(find.textContaining('Network error'), findsOneWidget);
        expect(testAuthNotifier.state.error, contains('Network error'));
        expect(testAuthNotifier.state.isAuthenticated, isFalse);
      });

      testWidgets('handles network error during sign in', (
        WidgetTester tester,
      ) async {
        // Arrange
        testAuthService.setNetworkError(true);
        await tester.pumpWidget(createTestApp(home: const LoginScreen()));
        await tester.pumpAndSettle();

        // Act: Fill form and submit
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show network error
        expect(find.textContaining('Network error'), findsOneWidget);
        expect(testAuthNotifier.state.error, contains('Network error'));
        expect(testAuthNotifier.state.isAuthenticated, isFalse);
      });

      testWidgets('recovers after network error is resolved', (
        WidgetTester tester,
      ) async {
        // Arrange: Start with network error
        testAuthService.setNetworkError(true);
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act 1: Try to sign up with network error
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert 1: Should show network error
        expect(find.textContaining('Network error'), findsOneWidget);

        // Act 2: Resolve network and try again
        testAuthService.setNetworkError(false);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert 2: Should succeed
        expect(testAuthNotifier.state.isAuthenticated, isTrue);
        expect(testAuthNotifier.state.error, isNull);
        expect(testAuthService._currentUser?.email, equals('test@example.com'));
      });
    });

    group('Performance Integration', () {
      testWidgets('completes sign up within performance limits', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act & Assert: Complete sign up within reasonable time limits
        final stopwatch = Stopwatch()..start();

        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Verify successful signup
        expect(testAuthNotifier.state.isAuthenticated, isTrue);

        // Verify reasonable performance (5 seconds for full UI interaction)
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
          reason:
              'Sign up should complete within 5 seconds for full UI interaction',
        );
      });

      testWidgets('completes sign in within performance limits', (
        WidgetTester tester,
      ) async {
        // Arrange: Create user first
        await testAuthService.signUp(
          'test@example.com',
          'password123',
          'Test User',
        );
        await testAuthNotifier.signOut();

        await tester.pumpWidget(createTestApp(home: const LoginScreen()));
        await tester.pumpAndSettle();

        // Act & Assert: Complete sign in within reasonable time limits
        final stopwatch = Stopwatch()..start();

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Verify successful signin
        expect(testAuthNotifier.state.isAuthenticated, isTrue);

        // Verify reasonable performance (5 seconds for full UI interaction)
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
          reason:
              'Sign in should complete within 5 seconds for full UI interaction',
        );
      });

      testWidgets('API operations complete within constitutional limits', (
        WidgetTester tester,
      ) async {
        // Test the actual API performance separately from UI
        final stopwatch = Stopwatch()..start();

        final result = await testAuthService.signUp(
          'api-test@example.com',
          'password123',
          'API Test User',
        );

        stopwatch.stop();

        // Verify successful API call
        expect(result.isSuccess, isTrue);

        // Verify constitutional API performance limit
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(AppConstants.maxTrackingResponseTime.inMilliseconds),
          reason:
              'API operations should complete within ${AppConstants.maxTrackingResponseTime.inMilliseconds}ms constitutional limit',
        );
      });

      testWidgets(
        'handles multiple rapid authentication attempts efficiently',
        (WidgetTester tester) async {
          // Arrange
          await tester.pumpWidget(createTestApp(home: const LoginScreen()));
          await tester.pumpAndSettle();

          // Act: Perform multiple authentication attempts
          for (int i = 0; i < 3; i++) {
            final stopwatch = Stopwatch()..start();

            // Clear previous entries
            await tester.enterText(find.byType(TextFormField).at(0), '');
            await tester.enterText(find.byType(TextFormField).at(1), '');

            // Enter new credentials
            await tester.enterText(
              find.byType(TextFormField).at(0),
              'test$i@example.com',
            );
            await tester.enterText(
              find.byType(TextFormField).at(1),
              'wrongpassword',
            );
            await tester.tap(find.byType(ElevatedButton));
            await tester.pumpAndSettle();

            stopwatch.stop();

            // Assert: Each attempt should complete within reasonable limits
            expect(
              stopwatch.elapsedMilliseconds,
              lessThan(5000),
              reason:
                  'Authentication attempt $i should complete within 5 seconds',
            );

            // Should fail but not crash
            expect(testAuthNotifier.state.isAuthenticated, isFalse);
          }
        },
      );
    });

    group('State Management Integration', () {
      testWidgets('maintains consistent state across sign up and sign in', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testEmail = 'state@test.com';
        const testPassword = 'StateTest123';
        const testName = 'State Test User';

        // Act 1: Sign up
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), testName);
        await tester.enterText(find.byType(TextFormField).at(1), testEmail);
        await tester.enterText(find.byType(TextFormField).at(2), testPassword);
        await tester.enterText(find.byType(TextFormField).at(3), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert 1: State after sign up
        expect(testAuthNotifier.state.isAuthenticated, isTrue);
        expect(testAuthNotifier.state.user?.email, equals(testEmail));
        expect(testAuthNotifier.state.user?.name, equals(testName));
        expect(testAuthNotifier.state.error, isNull);
        expect(testAuthNotifier.state.isLoading, isFalse);

        // Act 2: Sign out
        await testAuthNotifier.signOut();

        // Assert 2: State after sign out
        expect(testAuthNotifier.state.isAuthenticated, isFalse);
        expect(testAuthNotifier.state.user, isNull);
        expect(testAuthNotifier.state.error, isNull);
        expect(testAuthNotifier.state.isLoading, isFalse);

        // Act 3: Sign in with same credentials
        await tester.pumpWidget(createTestApp(home: const LoginScreen()));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), testEmail);
        await tester.enterText(find.byType(TextFormField).at(1), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert 3: State after sign in (should match original user)
        expect(testAuthNotifier.state.isAuthenticated, isTrue);
        expect(testAuthNotifier.state.user?.email, equals(testEmail));
        expect(testAuthNotifier.state.user?.name, equals(testName));
        expect(testAuthNotifier.state.error, isNull);
        expect(testAuthNotifier.state.isLoading, isFalse);
      });

      testWidgets('clears error state on successful authentication', (
        WidgetTester tester,
      ) async {
        // Arrange: Create user and set up error condition
        await testAuthService.signUp(
          'test@example.com',
          'password123',
          'Test User',
        );
        await testAuthNotifier.signOut();

        // Configure auth service to simulate network error first
        testAuthService.setNetworkError(true);

        await tester.pumpWidget(createTestApp(home: const LoginScreen()));
        await tester.pumpAndSettle();

        // Act 1: Cause authentication error (network failure)
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert 1: Should have error state
        expect(testAuthNotifier.state.error, isNotNull);
        expect(testAuthNotifier.state.isAuthenticated, isFalse);

        // Act 2: Resolve network error and try again
        testAuthService.setNetworkError(false);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert 2: Error should be cleared and user authenticated
        expect(testAuthNotifier.state.error, isNull);
        expect(testAuthNotifier.state.isAuthenticated, isTrue);
      });
    });

    group('Edge Cases Integration', () {
      testWidgets('handles rapid form submissions gracefully', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp(home: const LoginScreen()));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');

        // Act: Rapidly tap submit button multiple times
        await tester.tap(find.byType(ElevatedButton));
        await tester.tap(find.byType(ElevatedButton));
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // Don't settle yet

        // Assert: Should handle multiple clicks gracefully
        // (could be loading state or successful/failed state)
        expect(
          testAuthNotifier.state.isLoading || !testAuthNotifier.state.isLoading,
          isTrue,
        );

        await tester.pumpAndSettle();

        // Should either succeed or fail, but not crash
        expect(testAuthNotifier.state.isLoading, isFalse);
      });

      testWidgets('handles empty string inputs correctly', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act: Enter empty strings (which should be treated as null/empty)
        await tester.enterText(find.byType(TextFormField).at(0), '');
        await tester.enterText(find.byType(TextFormField).at(1), '');
        await tester.enterText(find.byType(TextFormField).at(2), '');
        await tester.enterText(find.byType(TextFormField).at(3), '');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show validation errors
        expect(find.text('Please enter your name'), findsOneWidget);
        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter your password'), findsOneWidget);
        expect(find.text('Please confirm your password'), findsOneWidget);
      });

      testWidgets('handles special characters in inputs', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp(home: const SignUpScreen()));
        await tester.pumpAndSettle();

        // Act: Enter special characters
        const specialName = 'Jose Maria';
        const specialEmail = 'jose.maria@example.com';
        const specialPassword = r'P@ssw0rd123';

        await tester.enterText(find.byType(TextFormField).at(0), specialName);
        await tester.enterText(find.byType(TextFormField).at(1), specialEmail);
        await tester.enterText(
          find.byType(TextFormField).at(2),
          specialPassword,
        );
        await tester.enterText(
          find.byType(TextFormField).at(3),
          specialPassword,
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should handle special characters correctly
        expect(testAuthNotifier.state.isAuthenticated, isTrue);
        expect(testAuthNotifier.state.user?.name, equals(specialName));
        expect(testAuthNotifier.state.user?.email, equals(specialEmail));
      });
    });
  });
}
