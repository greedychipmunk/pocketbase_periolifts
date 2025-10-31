import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import '../../../lib/screens/sign_up_screen.dart';
import '../../../lib/providers/auth_provider.dart';
import '../../../lib/services/auth_service.dart';
import '../../../lib/models/user.dart';
import '../../../lib/utils/result.dart';
import '../../../lib/constants/app_constants.dart';
import '../../test_helpers.dart';
import '../../mocks/generate_mocks.dart';

void main() {
  group('SignUpScreen Widget Tests', () {
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
      testWidgets('should display all required sign up form elements', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act & Assert - These will fail because SignUpScreen UI doesn't exist yet
        expect(find.text('Create Account'), findsOneWidget);
        expect(
          find.byType(TextFormField),
          findsNWidgets(4),
        ); // Name, email, password, confirm password
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Confirm Password'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget); // Sign up button
        expect(find.text('Already have an account? Sign in'), findsOneWidget);
      });

      testWidgets(
        'should show password visibility toggles for both password fields',
        (WidgetTester tester) async {
          // Arrange
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authServiceProvider.overrideWithValue(mockAuthService),
              ],
              child: const MaterialApp(home: SignUpScreen()),
            ),
          );

          // Act & Assert - Will fail because password visibility toggles don't exist
          expect(
            find.byIcon(Icons.visibility_off),
            findsNWidgets(2),
          ); // Both password fields

          // Tap the first visibility toggle (password field)
          await tester.tap(find.byIcon(Icons.visibility_off).first);
          await tester.pump();

          expect(find.byIcon(Icons.visibility), findsOneWidget);
          expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        },
      );

      testWidgets('should display app logo and branding', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act & Assert - Will fail because branding elements don't exist
        expect(find.text('PerioLifts'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget); // App logo
        expect(
          find.text('Join the fitness community'),
          findsOneWidget,
        ); // Subtitle
      });

      testWidgets('should display terms and privacy policy links', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act & Assert - Will fail because legal links don't exist
        expect(
          find.textContaining('By signing up, you agree to our'),
          findsOneWidget,
        );
        expect(find.text('Terms of Service'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
      });
    });

    group('Form Validation Tests', () {
      testWidgets('should show validation error for empty name', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Try to submit form without name
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert - Will fail because validation doesn't exist yet
        expect(find.text('Please enter your full name'), findsOneWidget);
      });

      testWidgets('should show validation error for empty email', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Enter name but no email
        await tester.enterText(find.byType(TextFormField).first, 'Test User');
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
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Enter invalid email
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, 'Test User');
        await tester.enterText(textFields.at(1), 'invalid-email');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert - Will fail because email validation doesn't exist yet
        expect(find.text('Please enter a valid email address'), findsOneWidget);
      });

      testWidgets('should show validation error for weak password', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Enter weak password
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, 'Test User');
        await tester.enterText(textFields.at(1), 'test@example.com');
        await tester.enterText(textFields.at(2), '123'); // Weak password
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert - Will fail because password validation doesn't exist yet
        expect(
          find.text('Password must be at least 8 characters'),
          findsOneWidget,
        );
      });

      testWidgets('should show validation error for mismatched passwords', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Enter mismatched passwords
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, 'Test User');
        await tester.enterText(textFields.at(1), 'test@example.com');
        await tester.enterText(textFields.at(2), 'password123');
        await tester.enterText(textFields.at(3), 'differentpassword');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert - Will fail because password matching validation doesn't exist yet
        expect(find.text('Passwords do not match'), findsOneWidget);
      });

      testWidgets('should show real-time password strength indicator', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Enter password and check strength indicator
        final passwordField = find.byType(TextFormField).at(2);
        await tester.enterText(passwordField, 'weak');
        await tester.pump();

        // Assert - Will fail because password strength indicator doesn't exist yet
        expect(find.text('Weak'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // Enter stronger password
        await tester.enterText(passwordField, 'StrongPassword123!');
        await tester.pump();

        expect(find.text('Strong'), findsOneWidget);
      });
    });

    group('Authentication Interaction Tests', () {
      testWidgets('should call AuthService.signUp with correct data', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testName = 'Test User';
        const testEmail = 'test@example.com';
        const testPassword = 'password123';

        final mockUser = User(
          id: 'user_123',
          email: testEmail,
          name: testName,
          verified: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        // Mock successful sign up
        // Note: This will fail because AuthService.signUp doesn't exist yet
        when(
          mockAuthService.signUp(testEmail, testPassword, testName),
        ).thenAnswer((_) async => Result.success(mockUser));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Fill form and submit
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testName);
        await tester.enterText(textFields.at(1), testEmail);
        await tester.enterText(textFields.at(2), testPassword);
        await tester.enterText(textFields.at(3), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert - Will fail because AuthService integration doesn't exist yet
        verify(
          mockAuthService.signUp(testEmail, testPassword, testName),
        ).called(1);
      });

      testWidgets('should show loading indicator during sign up', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testName = 'Test User';
        const testEmail = 'test@example.com';
        const testPassword = 'password123';

        // Mock delayed sign up
        when(
          mockAuthService.signUp(testEmail, testPassword, testName),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          return Result.success(
            User(
              id: 'user_123',
              email: testEmail,
              name: testName,
              verified: false,
              created: DateTime.now(),
              updated: DateTime.now(),
            ),
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Fill form and submit
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testName);
        await tester.enterText(textFields.at(1), testEmail);
        await tester.enterText(textFields.at(2), testPassword);
        await tester.enterText(textFields.at(3), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // Start the async operation

        // Assert - Will fail because loading state doesn't exist yet
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Creating account...'), findsOneWidget);
      });

      testWidgets('should display error message on sign up failure', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testName = 'Test User';
        const testEmail = 'existing@example.com';
        const testPassword = 'password123';
        const errorMessage = 'Email already exists';

        // Mock sign up failure
        when(
          mockAuthService.signUp(testEmail, testPassword, testName),
        ).thenAnswer(
          (_) async => Result.error(
            AppError(message: errorMessage, type: 'ValidationError'),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Fill form with existing email and submit
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testName);
        await tester.enterText(textFields.at(1), testEmail);
        await tester.enterText(textFields.at(2), testPassword);
        await tester.enterText(textFields.at(3), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - Will fail because error handling doesn't exist yet
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should show email verification prompt on successful sign up', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testName = 'Test User';
        const testEmail = 'test@example.com';
        const testPassword = 'password123';

        final mockUser = User(
          id: 'user_123',
          email: testEmail,
          name: testName,
          verified: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        when(
          mockAuthService.signUp(testEmail, testPassword, testName),
        ).thenAnswer((_) async => Result.success(mockUser));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Successful sign up
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testName);
        await tester.enterText(textFields.at(1), testEmail);
        await tester.enterText(textFields.at(2), testPassword);
        await tester.enterText(textFields.at(3), testPassword);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - Will fail because email verification prompt doesn't exist yet
        expect(find.text('Verify your email'), findsOneWidget);
        expect(
          find.textContaining('We sent a verification link to'),
          findsOneWidget,
        );
        expect(find.text('Resend verification email'), findsOneWidget);
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
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act & Assert - Will fail because accessibility labels don't exist yet
        expect(find.bySemanticsLabel('Full name input field'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Email address input field'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Password input field'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Confirm password input field'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Create account button'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Toggle password visibility'),
          findsNWidgets(2),
        );
      });

      testWidgets('should support keyboard navigation', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
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
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        stopwatch.stop();

        // Assert - Must render within startup time limits per constitutional requirement
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(AppConstants.maxStartupTime),
        );
      });

      testWidgets('should handle sign up within response time limits', (
        WidgetTester tester,
      ) async {
        // Arrange
        const testName = 'Test User';
        const testEmail = 'test@example.com';
        const testPassword = 'password123';

        final mockUser = User(
          id: 'user_123',
          email: testEmail,
          name: testName,
          verified: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        when(
          mockAuthService.signUp(testEmail, testPassword, testName),
        ).thenAnswer((_) async => Result.success(mockUser));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act & Assert - Sign up must complete within 100ms
        final stopwatch = Stopwatch()..start();

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, testName);
        await tester.enterText(textFields.at(1), testEmail);
        await tester.enterText(textFields.at(2), testPassword);
        await tester.enterText(textFields.at(3), testPassword);
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
      testWidgets('should navigate to login screen when link tapped', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: MaterialApp(
              home: const SignUpScreen(),
              routes: {
                '/login': (context) =>
                    const Scaffold(body: Text('Login Screen')),
              },
            ),
          ),
        );

        // Act - Will fail because login navigation doesn't exist yet
        await tester.tap(find.text('Already have an account? Sign in'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Login Screen'), findsOneWidget);
      });

      testWidgets('should open terms of service when link tapped', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: MaterialApp(
              home: const SignUpScreen(),
              routes: {
                '/terms': (context) =>
                    const Scaffold(body: Text('Terms of Service')),
              },
            ),
          ),
        );

        // Act - Will fail because terms navigation doesn't exist yet
        await tester.tap(find.text('Terms of Service'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Terms of Service'), findsAtLeastNWidgets(1));
      });

      testWidgets('should open privacy policy when link tapped', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: MaterialApp(
              home: const SignUpScreen(),
              routes: {
                '/privacy': (context) =>
                    const Scaffold(body: Text('Privacy Policy')),
              },
            ),
          ),
        );

        // Act - Will fail because privacy navigation doesn't exist yet
        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Privacy Policy'), findsAtLeastNWidgets(1));
      });
    });

    group('Social Sign Up Tests', () {
      testWidgets('should display social sign up options', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act & Assert - Will fail because social sign up doesn't exist yet
        expect(find.text('Or sign up with'), findsOneWidget);
        expect(find.text('Google'), findsOneWidget);
        expect(find.text('Apple'), findsOneWidget);
        expect(find.byIcon(Icons.google), findsOneWidget);
        expect(find.byIcon(Icons.apple), findsOneWidget);
      });

      testWidgets('should handle Google sign up', (WidgetTester tester) async {
        // Arrange
        final mockUser = User(
          id: 'google_user_123',
          email: 'test@gmail.com',
          name: 'Google User',
          verified: true,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        when(
          mockAuthService.signUpWithGoogle(),
        ).thenAnswer((_) async => Result.success(mockUser));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
            child: const MaterialApp(home: SignUpScreen()),
          ),
        );

        // Act - Will fail because Google sign up doesn't exist yet
        await tester.tap(find.text('Google'));
        await tester.pumpAndSettle();

        // Assert
        verify(mockAuthService.signUpWithGoogle()).called(1);
      });
    });
  });
}
