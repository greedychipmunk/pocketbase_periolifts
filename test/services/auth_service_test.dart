import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../lib/services/auth_service.dart';
import '../../lib/models/user.dart';
import '../../lib/utils/result.dart';
import '../../lib/utils/error_handler.dart';
import '../mocks/generate_mocks.dart';

void main() {
  group('AuthService - PocketBase Integration Tests', () {
    late AuthService authService;
    late TestPocketBaseClient mockPb;
    late TestRecordService mockUsersCollection;

    setUp(() {
      // Create mock PocketBase client
      mockPb = TestPocketBaseClient();
      mockUsersCollection = TestRecordService('users');
      mockPb.setMockCollection('users', mockUsersCollection);

      // Create AuthService instance with mock client
      authService = AuthService(mockPb);
    });

    tearDown(() {
      // Clean up after each test
      mockUsersCollection.reset();
      mockPb.reset();
    });

    group('Authentication State', () {
      test('currentUser returns null when not authenticated', () {
        expect(authService.currentUser, isNull);
      });

      test('isAuthenticated returns false when no user', () {
        expect(authService.isAuthenticated, isFalse);
      });

      test('authToken returns null when not authenticated', () {
        expect(authService.authToken, isNull);
      });

      test(
        'isAuthenticated returns true when user exists and token valid',
        () async {
          // Simulate authenticated state
          final testUser = _createTestUser();
          mockPb.authStore.save('test-token', testUser.toJson());

          final result = await authService.initializeAuth();

          expect(result.isSuccess, isTrue);
          expect(authService.isAuthenticated, isTrue);
          expect(authService.currentUser, isNotNull);
          expect(authService.authToken, equals('test-token'));
        },
      );
    });

    group('Sign In', () {
      test('signIn succeeds with valid credentials', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'TestPass123!';
        final testUser = _createTestUser(email: email);

        // Configure mock response
        mockUsersCollection.configureAuthWithPassword(
          email: email,
          password: password,
          user: testUser,
        );

        // Act
        final result = await authService.signIn(email, password);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.email, equals(email));
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!.email, equals(email));

        // Verify performance requirement (<500ms)
        final stopwatch = Stopwatch()..start();
        await authService.signIn(email, password);
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('signIn fails with invalid email format', () async {
        // Arrange
        const invalidEmail = 'invalid-email';
        const password = 'TestPass123!';

        // Act
        final result = await authService.signIn(invalidEmail, password);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Invalid email format'));
        expect(result.error!.details?['field'], equals('email'));
      });

      test('signIn fails with empty password', () async {
        // Arrange
        const email = 'test@example.com';
        const password = '';

        // Act
        final result = await authService.signIn(email, password);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Password is required'));
        expect(result.error!.details?['field'], equals('password'));
      });

      test('signIn handles authentication failure', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'WrongPassword';

        // Configure mock to simulate authentication failure
        mockUsersCollection.configureError(
          ClientException(
            statusCode: 401,
            response: {'message': 'Invalid credentials'},
          ),
        );

        // Act
        final result = await authService.signIn(email, password);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
      });

      test('signIn handles network error', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'TestPass123!';

        // Configure mock to simulate network error
        mockUsersCollection.configureError(
          ClientException(
            statusCode: 0,
            response: {'message': 'Network error'},
          ),
        );

        // Act
        final result = await authService.signIn(email, password);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('NetworkError'));
      });

      test('signIn handles server error', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'TestPass123!';

        // Configure mock to simulate server error
        mockUsersCollection.configureError(
          ClientException(
            statusCode: 500,
            response: {'message': 'Internal server error'},
          ),
        );

        // Act
        final result = await authService.signIn(email, password);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ServerError'));
      });
    });

    group('Sign Up', () {
      test('signUp succeeds with valid data', () async {
        // Arrange
        const email = 'newuser@example.com';
        const password = 'TestPass123!';
        const name = 'Test User';
        final testUser = _createTestUser(email: email, name: name);

        // Configure mock responses
        mockUsersCollection.configureCreate(testUser);
        mockUsersCollection.configureAuthWithPassword(
          email: email,
          password: password,
          user: testUser,
        );
        mockUsersCollection.configureRequestVerification(email);

        // Act
        final result = await authService.signUp(email, password, name);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.email, equals(email));
        expect(result.data!.name, equals(name));
        expect(authService.currentUser, isNotNull);

        // Verify performance requirement (<500ms)
        final stopwatch = Stopwatch()..start();
        await authService.signUp(email, password, name);
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('signUp fails with invalid email format', () async {
        // Arrange
        const invalidEmail = 'invalid-email';
        const password = 'TestPass123!';
        const name = 'Test User';

        // Act
        final result = await authService.signUp(invalidEmail, password, name);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Invalid email format'));
        expect(result.error!.details?['field'], equals('email'));
      });

      test('signUp fails with weak password', () async {
        // Arrange
        const email = 'test@example.com';
        const weakPassword = 'weak';
        const name = 'Test User';

        // Act
        final result = await authService.signUp(email, weakPassword, name);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Password must be at least 8 characters'),
        );
        expect(result.error!.details?['field'], equals('password'));
      });

      test('signUp fails with empty name', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'TestPass123!';
        const name = '';

        // Act
        final result = await authService.signUp(email, password, name);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Name cannot be empty'));
        expect(result.error!.details?['field'], equals('name'));
      });

      test('signUp handles duplicate email error', () async {
        // Arrange
        const email = 'existing@example.com';
        const password = 'TestPass123!';
        const name = 'Test User';

        // Configure mock to simulate duplicate email error
        mockUsersCollection.configureError(
          ClientException(
            statusCode: 400,
            response: {'message': 'Email already exists'},
          ),
        );

        // Act
        final result = await authService.signUp(email, password, name);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
      });
    });

    group('Sign Out', () {
      test('signOut clears authentication state', () async {
        // Arrange - first sign in
        const email = 'test@example.com';
        const password = 'TestPass123!';
        final testUser = _createTestUser(email: email);

        mockUsersCollection.configureAuthWithPassword(
          email: email,
          password: password,
          user: testUser,
        );

        await authService.signIn(email, password);
        expect(authService.isAuthenticated, isTrue);

        // Act
        final result = await authService.signOut();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
        expect(authService.authToken, isNull);
      });

      test('signOut handles error gracefully', () async {
        // This test ensures signOut is resilient even if something goes wrong
        final result = await authService.signOut();

        expect(result.isSuccess, isTrue);
        expect(authService.isAuthenticated, isFalse);
      });
    });

    group('Token Refresh', () {
      test('refreshToken succeeds with valid session', () async {
        // Arrange
        final testUser = _createTestUser();
        mockPb.authStore.save('valid-token', testUser.toJson());

        // Configure mock response
        mockUsersCollection.configureAuthRefresh(testUser);

        // Act
        final result = await authService.refreshToken();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(authService.currentUser, isNotNull);
      });

      test('refreshToken fails without valid session', () async {
        // Arrange - ensure no valid session
        mockPb.authStore.clear();

        // Act
        final result = await authService.refreshToken();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(result.error!.message, contains('No valid session to refresh'));
      });

      test('refreshToken handles network error', () async {
        // Arrange
        final testUser = _createTestUser();
        mockPb.authStore.save('valid-token', testUser.toJson());

        // Configure mock to simulate network error
        mockUsersCollection.configureError(
          ClientException(
            statusCode: 0,
            response: {'message': 'Network error'},
          ),
        );

        // Act
        final result = await authService.refreshToken();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('NetworkError'));
      });
    });

    group('Initialize Auth', () {
      test('initializeAuth loads existing valid session', () async {
        // Arrange
        final testUser = _createTestUser();
        mockPb.authStore.save('valid-token', testUser.toJson());

        // Act
        final result = await authService.initializeAuth();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.email, equals(testUser.email));
        expect(authService.currentUser, isNotNull);
        expect(authService.isAuthenticated, isTrue);
      });

      test('initializeAuth returns null for no session', () async {
        // Arrange - ensure no session
        mockPb.authStore.clear();

        // Act
        final result = await authService.initializeAuth();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
        expect(authService.currentUser, isNull);
        expect(authService.isAuthenticated, isFalse);
      });
    });

    group('Password Reset', () {
      test('sendPasswordResetEmail succeeds with valid email', () async {
        // Arrange
        const email = 'user@example.com';

        // Configure mock response
        mockUsersCollection.configureRequestPasswordReset(email);

        // Act
        final result = await authService.sendPasswordResetEmail(email);

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('sendPasswordResetEmail fails with invalid email', () async {
        // Arrange
        const invalidEmail = 'invalid-email';

        // Act
        final result = await authService.sendPasswordResetEmail(invalidEmail);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Invalid email format'));
      });

      test('resetPassword succeeds with valid token and password', () async {
        // Arrange
        const token = 'valid-reset-token';
        const newPassword = 'NewPass123!';

        // Configure mock response
        mockUsersCollection.configureConfirmPasswordReset(token, newPassword);

        // Act
        final result = await authService.resetPassword(token, newPassword);

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('resetPassword fails with weak password', () async {
        // Arrange
        const token = 'valid-reset-token';
        const weakPassword = 'weak';

        // Act
        final result = await authService.resetPassword(token, weakPassword);

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Password must be at least 8 characters'),
        );
      });
    });

    group('Email Verification', () {
      test('sendEmailVerification succeeds with valid email', () async {
        // Arrange
        const email = 'user@example.com';

        // Configure mock response
        mockUsersCollection.configureRequestVerification(email);

        // Act
        final result = await authService.sendEmailVerification(email);

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('verifyEmail succeeds with valid token', () async {
        // Arrange
        const token = 'valid-verification-token';

        // Configure mock response
        mockUsersCollection.configureConfirmVerification(token);

        // Act
        final result = await authService.verifyEmail(token);

        // Assert
        expect(result.isSuccess, isTrue);
      });
    });

    group('Profile Management', () {
      test('updateProfile succeeds with valid data', () async {
        // Arrange
        final testUser = _createTestUser();
        mockPb.authStore.save('valid-token', testUser.toJson());

        const updates = {'name': 'Updated Name', 'preferredUnits': 'metric'};
        final updatedUser = _createTestUser(name: 'Updated Name');

        // Configure mock response
        mockUsersCollection.configureUpdate(testUser.id, updatedUser);

        // Act
        final result = await authService.updateProfile(updates);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data!.name, equals('Updated Name'));
      });

      test('changePassword succeeds with valid credentials', () async {
        // Arrange
        final testUser = _createTestUser();
        mockPb.authStore.save('valid-token', testUser.toJson());

        const currentPassword = 'CurrentPass123!';
        const newPassword = 'NewPass123!';

        // Configure mock response
        mockUsersCollection.configureUpdate(testUser.id, testUser);

        // Act
        final result = await authService.changePassword(
          currentPassword,
          newPassword,
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('deleteAccount succeeds with valid password', () async {
        // Arrange
        final testUser = _createTestUser();
        mockPb.authStore.save('valid-token', testUser.toJson());

        const password = 'TestPass123!';

        // Configure mock response
        mockUsersCollection.configureDelete(testUser.id);

        // Act
        final result = await authService.deleteAccount(password);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
      });
    });

    group('Performance Tests', () {
      test('all operations complete within 500ms requirement', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'TestPass123!';
        const name = 'Test User';
        final testUser = _createTestUser(email: email, name: name);

        // Configure mocks for all operations
        mockUsersCollection.configureCreate(testUser);
        mockUsersCollection.configureAuthWithPassword(
          email: email,
          password: password,
          user: testUser,
        );
        mockUsersCollection.configureRequestVerification(email);
        mockUsersCollection.configureRequestPasswordReset(email);
        mockUsersCollection.configureAuthRefresh(testUser);

        // Test each operation for performance
        final operations = [
          () => authService.signUp(email, password, name),
          () => authService.signIn(email, password),
          () => authService.refreshToken(),
          () => authService.sendPasswordResetEmail(email),
          () => authService.sendEmailVerification(email),
          () => authService.signOut(),
        ];

        for (final operation in operations) {
          final stopwatch = Stopwatch()..start();
          await operation();
          stopwatch.stop();
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(500),
            reason: 'Operation exceeded 500ms performance requirement',
          );
        }
      });
    });

    group('Error Resilience', () {
      test('handles unexpected exceptions gracefully', () async {
        // Arrange
        mockUsersCollection.configureError(Exception('Unexpected error'));

        // Act
        final result = await authService.signIn('test@example.com', 'password');

        // Assert
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('UnknownError'));
      });

      test('maintains state consistency after errors', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'TestPass123!';
        final testUser = _createTestUser(email: email);

        // First successful sign in
        mockUsersCollection.configureAuthWithPassword(
          email: email,
          password: password,
          user: testUser,
        );

        await authService.signIn(email, password);
        expect(authService.isAuthenticated, isTrue);

        // Now simulate an error on refresh
        mockUsersCollection.configureError(
          ClientException(
            statusCode: 401,
            response: {'message': 'Token expired'},
          ),
        );

        // Act
        final result = await authService.refreshToken();

        // Assert
        expect(result.isError, isTrue);
        // State should remain consistent (still authenticated with original user)
        expect(authService.currentUser, isNotNull);
      });
    });
  });
}

/// Helper function to create test user data
User _createTestUser({
  String email = 'test@example.com',
  String name = 'Test User',
  String username = 'testuser',
}) {
  return User(
    id: 'test-user-id',
    created: DateTime.now(),
    updated: DateTime.now(),
    email: email,
    name: name,
    username: username,
  );
}
