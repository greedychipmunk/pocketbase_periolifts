import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import '../../lib/main.dart';
import '../../lib/screens/login_screen.dart';
import '../../lib/screens/sign_up_screen.dart';
import '../../lib/screens/dashboard_screen.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/models/user.dart';
import '../../lib/constants/app_constants.dart';
import '../test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    setUp(() async {
      await TestHelpers.setupTestEnvironment();
    });

    tearDown(() async {
      await TestHelpers.cleanupTestEnvironment();
    });

    group('Complete Sign Up Flow', () {
      testWidgets('should complete full sign up flow from start to dashboard', (
        WidgetTester tester,
      ) async {
        // Arrange - This will fail because main app doesn't exist yet
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Should start on login screen or splash screen
        expect(find.byType(LoginScreen), findsOneWidget);

        // Act 1: Navigate to sign up screen
        await tester.tap(find.text('Don\'t have an account? Sign up'));
        await tester.pumpAndSettle();

        // Assert: Should be on sign up screen
        expect(find.byType(SignUpScreen), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);

        // Act 2: Fill sign up form
        const testName = 'Integration Test User';
        const testEmail = 'integration@test.com';
        const testPassword = 'IntegrationTest123!';

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testName);
        await tester.enterText(textFields.at(1), testEmail);
        await tester.enterText(textFields.at(2), testPassword);
        await tester.enterText(textFields.at(3), testPassword);

        // Act 3: Submit sign up form - This will fail because form submission doesn't exist
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Assert: Should show email verification prompt or navigate to dashboard
        expect(
          find.textContaining('verify').or(find.byType(DashboardScreen)),
          findsOneWidget,
        );
      });

      testWidgets('should handle sign up validation errors gracefully', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Navigate to sign up screen
        await tester.tap(find.text('Don\'t have an account? Sign up'));
        await tester.pumpAndSettle();

        // Act: Try to submit empty form - This will fail because validation doesn't exist
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert: Should show validation errors
        expect(find.text('Please enter your full name'), findsOneWidget);
        expect(find.text('Please enter your email'), findsOneWidget);
      });

      testWidgets('should handle duplicate email error during sign up', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Navigate to sign up screen
        await tester.tap(find.text('Don\'t have an account? Sign up'));
        await tester.pumpAndSettle();

        // Act: Fill form with existing email - This will fail because error handling doesn't exist
        const existingEmail = 'existing@test.com';
        const testPassword = 'Password123!';

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, 'Test User');
        await tester.enterText(textFields.at(1), existingEmail);
        await tester.enterText(textFields.at(2), testPassword);
        await tester.enterText(textFields.at(3), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show duplicate email error
        expect(find.textContaining('Email already exists'), findsOneWidget);
      });
    });

    group('Complete Sign In Flow', () {
      testWidgets('should complete full sign in flow with valid credentials', (
        WidgetTester tester,
      ) async {
        // Arrange - Start with existing user
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Should be on login screen
        expect(find.byType(LoginScreen), findsOneWidget);

        // Act: Fill login form with valid credentials - This will fail because auth doesn't exist
        const testEmail = 'test@example.com';
        const testPassword = 'Password123!';

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testEmail);
        await tester.enterText(textFields.at(1), testPassword);

        // Submit login form
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Assert: Should navigate to dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);
      });

      testWidgets('should handle invalid credentials error gracefully', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Act: Fill login form with invalid credentials - This will fail because error handling doesn't exist
        const invalidEmail = 'invalid@example.com';
        const wrongPassword = 'WrongPassword!';

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, invalidEmail);
        await tester.enterText(textFields.at(1), wrongPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show authentication error
        expect(
          find.textContaining('Invalid email or password'),
          findsOneWidget,
        );
        expect(
          find.byType(LoginScreen),
          findsOneWidget,
        ); // Should stay on login screen
      });

      testWidgets('should validate email format before API call', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Act: Enter invalid email format - This will fail because validation doesn't exist
        const invalidEmail = 'not-an-email';
        const password = 'Password123!';

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, invalidEmail);
        await tester.enterText(textFields.at(1), password);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert: Should show email validation error
        expect(find.text('Please enter a valid email address'), findsOneWidget);
      });
    });

    group('Session Management Flow', () {
      testWidgets('should restore session on app restart', (
        WidgetTester tester,
      ) async {
        // Arrange: First complete sign in
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        const testEmail = 'test@example.com';
        const testPassword = 'Password123!';

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testEmail);
        await tester.enterText(textFields.at(1), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify logged in
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Act: Simulate app restart - This will fail because session restoration doesn't exist
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Assert: Should automatically be logged in
        expect(find.byType(DashboardScreen), findsOneWidget);
      });

      testWidgets('should handle expired session gracefully', (
        WidgetTester tester,
      ) async {
        // Arrange: Start with expired session
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Act: Try to access protected content - This will fail because session handling doesn't exist
        // Simulate expired token scenario

        // Assert: Should redirect to login screen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.textContaining('Session expired'), findsOneWidget);
      });
    });

    group('Sign Out Flow', () {
      testWidgets('should complete sign out flow and clear session', (
        WidgetTester tester,
      ) async {
        // Arrange: First sign in
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        const testEmail = 'test@example.com';
        const testPassword = 'Password123!';

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testEmail);
        await tester.enterText(textFields.at(1), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify logged in
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Act: Sign out - This will fail because sign out doesn't exist
        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();

        // Assert: Should return to login screen
        expect(find.byType(LoginScreen), findsOneWidget);

        // Verify session is cleared by trying to restart app
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Navigation Flow', () {
      testWidgets('should navigate between auth screens correctly', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Start on login screen
        expect(find.byType(LoginScreen), findsOneWidget);

        // Act 1: Navigate to sign up - This will fail because navigation doesn't exist
        await tester.tap(find.text('Don\'t have an account? Sign up'));
        await tester.pumpAndSettle();

        // Assert: Should be on sign up screen
        expect(find.byType(SignUpScreen), findsOneWidget);

        // Act 2: Navigate back to login
        await tester.tap(find.text('Already have an account? Sign in'));
        await tester.pumpAndSettle();

        // Assert: Should be back on login screen
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('should handle deep linking to protected routes', (
        WidgetTester tester,
      ) async {
        // Arrange: Try to access dashboard directly without authentication
        // This will fail because route protection doesn't exist
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: '/dashboard',
            routes: {
              '/': (context) => const LoginScreen(),
              '/dashboard': (context) => const DashboardScreen(),
            },
          ),
        );
        await tester.pumpAndSettle();

        // Assert: Should redirect to login screen
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Performance Integration Tests', () {
      testWidgets(
        'should complete auth flow within constitutional performance limits',
        (WidgetTester tester) async {
          // Arrange
          await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
          await tester.pumpAndSettle();

          // Act & Assert: Complete sign in within time limits
          await TestHelpers.measurePerformance(
            () async {
              const testEmail = 'test@example.com';
              const testPassword = 'Password123!';

              final textFields = find.byType(TextFormField);
              await tester.enterText(textFields.first, testEmail);
              await tester.enterText(textFields.at(1), testPassword);
              await tester.tap(find.byType(ElevatedButton));
              await tester.pumpAndSettle();
            },
            maxDurationMs: AppConstants.maxTrackingResponseTime,
            testName: 'Complete authentication flow performance',
          );
        },
      );

      testWidgets(
        'should handle rapid authentication attempts without performance degradation',
        (WidgetTester tester) async {
          // Arrange
          await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
          await tester.pumpAndSettle();

          // Act: Perform multiple rapid authentication attempts
          for (int i = 0; i < 5; i++) {
            final stopwatch = Stopwatch()..start();

            final textFields = find.byType(TextFormField);
            await tester.enterText(textFields.first, 'test$i@example.com');
            await tester.enterText(textFields.at(1), 'Password$i!');
            await tester.tap(find.byType(ElevatedButton));
            await tester.pump();

            stopwatch.stop();

            // Assert: Each attempt should complete within limits
            expect(
              stopwatch.elapsedMilliseconds,
              lessThan(AppConstants.maxTrackingResponseTime),
            );

            // Clear form for next attempt
            await tester.enterText(textFields.first, '');
            await tester.enterText(textFields.at(1), '');
          }
        },
      );
    });

    group('Offline/Network Error Handling', () {
      testWidgets('should handle network connectivity issues gracefully', (
        WidgetTester tester,
      ) async {
        // Arrange - Simulate network disconnect
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Act: Try to sign in without network - This will fail because offline handling doesn't exist
        const testEmail = 'test@example.com';
        const testPassword = 'Password123!';

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testEmail);
        await tester.enterText(textFields.at(1), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should show network error message
        expect(find.textContaining('network'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should retry authentication after network restoration', (
        WidgetTester tester,
      ) async {
        // Arrange: Start with network error state
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Show network error
        const testEmail = 'test@example.com';
        const testPassword = 'Password123!';

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testEmail);
        await tester.enterText(textFields.at(1), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should see network error
        expect(find.textContaining('network'), findsOneWidget);

        // Act: Tap retry - This will fail because retry logic doesn't exist
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Assert: Should attempt authentication again
        expect(find.byType(DashboardScreen), findsOneWidget);
      });
    });

    group('Accessibility Integration Tests', () {
      testWidgets('should support full keyboard navigation through auth flow', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Act: Navigate using only keyboard - This will fail because keyboard nav doesn't exist
        await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Email field
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Password field
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Password123!',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Sign in button
        await tester.sendKeyEvent(LogicalKeyboardKey.enter); // Activate button
        await tester.pumpAndSettle();

        // Assert: Should complete authentication
        expect(find.byType(DashboardScreen), findsOneWidget);
      });

      testWidgets('should announce screen reader updates during auth flow', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(const ProviderScope(child: PerioLiftsApp()));
        await tester.pumpAndSettle();

        // Act: Trigger authentication error - This will fail because announcements don't exist
        const invalidEmail = 'invalid@example.com';
        const wrongPassword = 'Wrong!';

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, invalidEmail);
        await tester.enterText(textFields.at(1), wrongPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert: Should have accessibility announcement for error
        expect(
          find.bySemanticsLabel(RegExp(r'Error:.*Invalid.*')),
          findsOneWidget,
        );
      });
    });
  });
}
