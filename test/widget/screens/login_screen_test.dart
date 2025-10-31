import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import '../../../lib/screens/login_screen.dart';
import '../../../lib/providers/auth_provider.dart';
import '../../../lib/services/auth_service.dart';
import '../../../lib/models/user.dart';
import '../../../lib/utils/result.dart';
import '../../../lib/constants/app_constants.dart';
import '../../test_helpers.dart';
import '../../mocks/generate_mocks.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late TestPocketBaseClient mockClient;
    late TestAuthStore mockAuthStore;
    late AuthService mockAuthService;

    setUp(() async {
      await TestHelpers.setupTestEnvironment();

      mockClient = TestPocketBaseClient();
      mockAuthStore = TestAuthStore();
      mockAuthService = AuthService();
    });

    tearDown(() async {
      await TestHelpers.cleanupTestEnvironment();
    });

    group('UI Elements Tests', () {
      testWidgets('should display all required login form elements', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act & Assert - These will fail because LoginScreen UI doesn't exist yet
        expect(find.text('Sign In'), findsOneWidget);
        expect(
          find.byType(TextFormField),
          findsNWidgets(2),
        ); // Email and password fields
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget); // Sign in button
        expect(find.text('Don\'t have an account? Sign up'), findsOneWidget);
      });

      testWidgets('should show password visibility toggle', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act & Assert - Will fail because password visibility toggle doesn't exist
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);

        // Tap the visibility toggle
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();

        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });

      testWidgets('should display app logo and branding', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act & Assert - Will fail because branding elements don't exist
        expect(find.text('PerioLifts'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget); // App logo
      });
    });

    group('Form Validation Tests', () {
      testWidgets('should show validation error for empty email', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act - Try to submit form without email
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert - Will fail because validation doesn't exist yet
        expect(find.text('Please enter your email'), findsOneWidget);
      });

      testWidgets('should show validation error for invalid email format', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act - Enter invalid email
        await tester.enterText(
          find.byType(TextFormField).first,
          'invalid-email',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert - Will fail because email validation doesn't exist yet
        expect(find.text('Please enter a valid email address'), findsOneWidget);
      });

      testWidgets('should show validation error for empty password', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act - Enter email but no password
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert - Will fail because password validation doesn't exist yet
        expect(find.text('Please enter your password'), findsOneWidget);
      });
    });

    group('Authentication Interaction Tests', () {
      testWidgets('should call AuthService.signIn with correct credentials', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'password123';

        final mockUser = User(
          id: 'user_123',
          email: testEmail,
          name: 'Test User',
          verified: true,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        // Mock successful authentication
        // Note: This will fail because AuthService.signIn doesn't exist yet
        when(
          mockAuthService.signIn(testEmail, testPassword),
        ).thenAnswer((_) async => Result.success(mockUser));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act - Fill form and submit
        await tester.enterText(find.byType(TextFormField).first, testEmail);
        await tester.enterText(find.byType(TextFormField).last, testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert - Will fail because AuthService integration doesn't exist yet
        verify(mockAuthService.signIn(testEmail, testPassword)).called(1);
      });

      testWidgets('should show loading indicator during authentication', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'password123';

        // Mock delayed authentication
        when(mockAuthService.signIn(testEmail, testPassword)).thenAnswer((
          _,
        ) async {
          await Future.delayed(const Duration(seconds: 1));
          return Result.success(
            User(
              id: 'user_123',
              email: testEmail,
              name: 'Test User',
              verified: true,
              created: DateTime.now(),
              updated: DateTime.now(),
            ),
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act - Fill form and submit
        await tester.enterText(find.byType(TextFormField).first, testEmail);
        await tester.enterText(find.byType(TextFormField).last, testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // Start the async operation

        // Assert - Will fail because loading state doesn't exist yet
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Signing in...'), findsOneWidget);
      });

      testWidgets('should display error message on authentication failure', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testEmail = 'invalid@example.com';
        const testPassword = 'wrongpassword';
        const errorMessage = 'Invalid email or password';

        // Mock authentication failure
        when(mockAuthService.signIn(testEmail, testPassword)).thenAnswer(
          (_) async => Result.error(
            AppError(message: errorMessage, type: 'AuthenticationError'),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act - Fill form with invalid credentials and submit
        await tester.enterText(find.byType(TextFormField).first, testEmail);
        await tester.enterText(find.byType(TextFormField).last, testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - Will fail because error handling doesn't exist yet
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should navigate to dashboard on successful authentication', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'password123';

        final mockUser = User(
          id: 'user_123',
          email: testEmail,
          name: 'Test User',
          verified: true,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        when(
          mockAuthService.signIn(testEmail, testPassword),
        ).thenAnswer((_) async => Result.success(mockUser));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: MaterialApp(
              home: const LoginScreen(),
              routes: {
                '/dashboard': (context) =>
                    const Scaffold(body: Text('Dashboard Screen')),
              },
            ),
          ),
        );

        // Act - Successful authentication
        await tester.enterText(find.byType(TextFormField).first, testEmail);
        await tester.enterText(find.byType(TextFormField).last, testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - Will fail because navigation doesn't exist yet
        expect(find.text('Dashboard Screen'), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper accessibility labels', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act & Assert - Will fail because accessibility labels don't exist yet
        expect(
          find.bySemanticsLabel('Email address input field'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Password input field'), findsOneWidget);
        expect(find.bySemanticsLabel('Sign in button'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Toggle password visibility'),
          findsOneWidget,
        );
      });

      testWidgets('should support keyboard navigation', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act - Tab through form fields
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Assert - Will fail because keyboard navigation isn't implemented yet
        expect(
          tester.testTextInput.isRegisteredFor(
            find.byType(TextFormField).first,
          ),
          isTrue,
        );
      });
    });

    group('Performance Tests', () {
      testWidgets('should render within constitutional performance limits', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        stopwatch.stop();

        // Assert - Must render within startup time limits per constitutional requirement
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(AppConstants.maxStartupTime),
        );
      });

      testWidgets('should handle authentication within response time limits', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'password123';

        final mockUser = User(
          id: 'user_123',
          email: testEmail,
          name: 'Test User',
          verified: true,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        when(
          mockAuthService.signIn(testEmail, testPassword),
        ).thenAnswer((_) async => Result.success(mockUser));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        // Act & Assert - Authentication must complete within 100ms
        final stopwatch = Stopwatch()..start();

        await tester.enterText(find.byType(TextFormField).first, testEmail);
        await tester.enterText(find.byType(TextFormField).last, testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(AppConstants.maxTrackingResponseTime),
        );
      });
    });

    group('Navigation Tests', () {
      testWidgets('should navigate to sign up screen when link tapped', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: MaterialApp(
              home: const LoginScreen(),
              routes: {
                '/signup': (context) =>
                    const Scaffold(body: Text('Sign Up Screen')),
              },
            ),
          ),
        );

        // Act - Will fail because sign up navigation doesn't exist yet
        await tester.tap(find.text('Don\'t have an account? Sign up'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Sign Up Screen'), findsOneWidget);
      });

      testWidgets('should navigate to forgot password screen when link tapped', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: MaterialApp(
              home: const LoginScreen(),
              routes: {
                '/forgot-password': (context) =>
                    const Scaffold(body: Text('Forgot Password Screen')),
              },
            ),
          ),
        );

        // Act - Will fail because forgot password navigation doesn't exist yet
        await tester.tap(find.text('Forgot Password?'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Forgot Password Screen'), findsOneWidget);
      });
    });
  });
}
