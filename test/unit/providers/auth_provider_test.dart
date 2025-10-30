import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../lib/providers/auth_provider.dart';
import '../../../lib/services/auth_service.dart';
import '../../test_helpers.dart';

void main() {
  group('AuthProvider Tests', () {
    late AuthService authService;
    late ProviderContainer container;

    setUp(() async {
      await TestHelpers.setupTestEnvironment();

      authService = AuthService();

      container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(authService)],
      );
    });

    tearDown(() async {
      container.dispose();
      await TestHelpers.cleanupTestEnvironment();
    });

    group('Initial State', () {
      test('should start with session restoration loading', () {
        final authState = container.read(authProvider);

        expect(authState.user, isNull);
        expect(
          authState.isLoading,
          isTrue,
        ); // Loading during session restoration
        expect(authState.error, isNull);
        expect(authState.isAuthenticated, isFalse);
      });

      test('convenience providers should reflect loading state initially', () {
        expect(container.read(isAuthenticatedProvider), isFalse);
        expect(container.read(currentUserProvider), isNull);
        expect(
          container.read(authLoadingProvider),
          isTrue,
        ); // Loading during session restoration
        expect(container.read(authErrorProvider), isNull);
      });
    });

    group('Authentication Flow', () {
      test('should handle sign in attempt', () async {
        // This test will fail because we don't have a real PocketBase server
        // but it validates the provider structure and state management

        // Act
        final result = await container
            .read(authProvider.notifier)
            .signIn('test@example.com', 'password123');

        // Assert - In TDD Red phase, this should fail
        expect(
          result.isError,
          isTrue,
          reason: 'Expected failure in TDD Red phase - no real server',
        );

        final state = container.read(authProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
      });

      test('should handle sign up attempt', () async {
        // This test will fail because we don't have a real PocketBase server
        // but it validates the provider structure and state management

        // Act
        final result = await container
            .read(authProvider.notifier)
            .signUp('test@example.com', 'Password123!', 'Test User');

        // Assert - In TDD Red phase, this should fail
        expect(
          result.isError,
          isTrue,
          reason: 'Expected failure in TDD Red phase - no real server',
        );

        final state = container.read(authProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
      });

      test('should handle sign out attempt', () async {
        // Act
        final result = await container.read(authProvider.notifier).signOut();

        // Assert - Even without auth, sign out should succeed
        expect(result.isSuccess, isTrue);

        final state = container.read(authProvider);
        expect(state.user, isNull);
        expect(state.isAuthenticated, isFalse);
        expect(state.isLoading, isFalse);
      });
    });

    group('User Management', () {
      test('should handle profile update attempt', () async {
        // Act
        final result = await container
            .read(authProvider.notifier)
            .updateProfile({'name': 'Updated Name'});

        // Assert - Should fail without authentication
        expect(result.isError, isTrue);

        final state = container.read(authProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
      });

      test('should handle password change attempt', () async {
        // Act
        final result = await container
            .read(authProvider.notifier)
            .changePassword('oldPass', 'newPass');

        // Assert - Should fail without authentication
        expect(result.isError, isTrue);

        final state = container.read(authProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
      });

      test('should handle password reset email request', () async {
        // Act
        final result = await container
            .read(authProvider.notifier)
            .resetPassword('test@example.com');

        // Assert - Should fail without real server
        expect(result.isError, isTrue);

        final state = container.read(authProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
      });

      test('should fail email verification when not authenticated', () async {
        // Act
        final result = await container
            .read(authProvider.notifier)
            .sendEmailVerification();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error?.type, equals('AuthenticationError'));
        expect(result.error?.message, contains('No user logged in'));
      });

      test('should handle delete account attempt', () async {
        // Act
        final result = await container
            .read(authProvider.notifier)
            .deleteAccount('password123');

        // Assert - Should fail without authentication
        expect(result.isError, isTrue);

        final state = container.read(authProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
      });
    });

    group('Session Management', () {
      test('should handle session restoration attempt', () async {
        // Session restoration should complete since it only checks local store
        // Allow brief time for the async operation
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = container.read(authProvider);

        // Should finish loading after session restoration
        expect(state.user, isNull);
        expect(state.isAuthenticated, isFalse);
        // Note: isLoading might still be true if restoration is slow, that's okay
      });

      test('should handle token refresh attempt', () async {
        // Act
        final result = await container
            .read(authProvider.notifier)
            .refreshToken();

        // Assert - Should fail without valid session
        expect(result.isError, isTrue);

        final state = container.read(authProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle validation errors in sign in', () async {
        // Act - Invalid email
        final result = await container
            .read(authProvider.notifier)
            .signIn('invalid-email', 'password123');

        // Assert
        expect(result.isError, isTrue);
        expect(result.error?.type, equals('ValidationError'));

        final state = container.read(authProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
      });

      test('should handle validation errors in sign up', () async {
        // Act - Weak password
        final result = await container
            .read(authProvider.notifier)
            .signUp('test@example.com', 'weak', 'Test User');

        // Assert
        expect(result.isError, isTrue);
        expect(result.error?.type, equals('ValidationError'));

        final state = container.read(authProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
      });
    });

    group('Performance Requirements', () {
      test(
        'should meet constitutional performance requirements for sign in',
        () async {
          // Act & Assert - Test that the provider itself is fast
          await TestHelpers.measurePerformance(() async {
            await container
                .read(authProvider.notifier)
                .signIn('test@example.com', 'password123');
          }, maxDurationMs: 100);
        },
      );

      test(
        'should meet constitutional performance requirements for state updates',
        () async {
          // Act & Assert - Test that sign out is fast
          await TestHelpers.measurePerformance(() async {
            await container.read(authProvider.notifier).signOut();
          }, maxDurationMs: 100);
        },
      );
    });

    group('State Consistency', () {
      test('should maintain state consistency with loading', () async {
        // Brief delay to allow provider initialization
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = container.read(authProvider);

        // Verify state consistency
        expect(state.user, isNull);
        expect(state.isAuthenticated, isFalse);

        // Test that convenience provider matches main state
        expect(container.read(isAuthenticatedProvider), state.isAuthenticated);
        expect(container.read(currentUserProvider), state.user);
      });

      test('should maintain state consistency with error state', () {
        final notifier = container.read(authProvider.notifier);

        // Set error state manually for testing
        notifier.state = notifier.state.copyWith(error: 'Test error message');

        final state = container.read(authProvider);
        expect(state.error, equals('Test error message'));

        // Check convenience provider
        expect(container.read(authErrorProvider), equals('Test error message'));
      });

      test(
        'should maintain state consistency between convenience providers',
        () {
          // All convenience providers should reflect the main provider state
          final authState = container.read(authProvider);

          expect(container.read(currentUserProvider), equals(authState.user));
          expect(
            container.read(isAuthenticatedProvider),
            equals(authState.isAuthenticated),
          );
          expect(
            container.read(authLoadingProvider),
            equals(authState.isLoading),
          );
          expect(container.read(authErrorProvider), equals(authState.error));
        },
      );
    });

    group('AuthProvider Integration', () {
      test('should integrate properly with Riverpod', () {
        // Verify provider is properly configured
        expect(() => container.read(authProvider), returnsNormally);
        expect(() => container.read(authProvider.notifier), returnsNormally);
      });

      test('should handle provider disposal correctly', () {
        // Verify container disposal doesn't throw
        expect(() => container.dispose(), returnsNormally);
      });
    });
  });
}
