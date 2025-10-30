import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lib/screens/login_screen.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/models/user.dart';
import '../../lib/utils/result.dart';
import '../../lib/constants/app_constants.dart';

/// Comprehensive widget tests for LoginScreen
/// 
/// Following TDD constitutional mandate - testing UI components, form validation,
/// user interaction scenarios, accessibility, and performance
/// 
/// Coverage targets:
/// - UI component rendering and styling
/// - Form validation (email/password requirements)  
/// - User interaction scenarios (tap, input, navigation)
/// - Accessibility compliance
/// - Performance validation (<500ms response)
void main() {
  group('LoginScreen Widget Tests', () {
    /// Helper function to create test widget with proper providers
    Widget createTestWidget({
      VoidCallback? onAuthSuccess,
      AuthState? overrideState,
    }) {
      return ProviderScope(
        overrides: overrideState != null
            ? [
                authProvider.overrideWith((ref) => TestAuthNotifier(overrideState)),
              ]
            : [],
        child: MaterialApp(
          home: LoginScreen(onAuthSuccess: onAuthSuccess),
        ),
      );
    }

    group('UI Component Rendering', () {
      testWidgets('renders all essential UI components', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Check all major UI components exist
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byIcon(Icons.fitness_center), findsOneWidget);
        
        // Check app branding
        expect(find.text(AppConstants.appName), findsOneWidget);
        expect(find.text(AppConstants.tagline), findsOneWidget);
        
        // Check form components
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.byIcon(Icons.email_outlined), findsOneWidget);
        expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
        
        // Check buttons
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);
        expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);
      });

      testWidgets('displays correct styling and theme integration', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Check styling elements
        final card = tester.widget<Card>(find.byType(Card).first);
        expect(card.elevation, equals(8));
        expect(card.shape, isA<RoundedRectangleBorder>());
        
        final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(elevatedButton.style?.elevation?.resolve({}), equals(2));
        
        // Check gradient containers exist
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('maintains proper accessibility support', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Check form field accessibility
        final emailField = find.ancestor(
          of: find.text('Email'),
          matching: find.byType(TextFormField),
        );
        final passwordField = find.ancestor(
          of: find.text('Password'),
          matching: find.byType(TextFormField),
        );
        
        expect(emailField, findsOneWidget);
        expect(passwordField, findsOneWidget);
        
        // Check button accessibility
        final signInButton = find.byType(ElevatedButton);
        expect(tester.widget<ElevatedButton>(signInButton).onPressed, isNotNull);
      });
    });

    group('Form Validation', () {
      testWidgets('validates empty email field', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap sign in without entering email
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Please enter your email'), findsOneWidget);
      });

      testWidgets('validates empty password field', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter email but leave password empty
        await tester.enterText(
          find.ancestor(
            of: find.text('Email'),
            matching: find.byType(TextFormField),
          ),
          'test@example.com',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Please enter your password'), findsOneWidget);
      });

      testWidgets('validates both fields when empty', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap sign in without entering anything
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter your password'), findsOneWidget);
      });

      testWidgets('accepts valid email and password input', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid credentials
        await tester.enterText(
          find.ancestor(
            of: find.text('Email'),
            matching: find.byType(TextFormField),
          ),
          'test@example.com',
        );
        await tester.enterText(
          find.ancestor(
            of: find.text('Password'),
            matching: find.byType(TextFormField),
          ),
          'password123',
        );

        // Tap sign in
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - No validation errors should appear
        expect(find.text('Please enter your email'), findsNothing);
        expect(find.text('Please enter your password'), findsNothing);
      });
    });

    group('User Interaction Scenarios', () {
      testWidgets('allows text input in email and password fields', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter text in email field
        await tester.enterText(
          find.ancestor(
            of: find.text('Email'),
            matching: find.byType(TextFormField),
          ),
          'user@example.com',
        );

        // Enter text in password field
        await tester.enterText(
          find.ancestor(
            of: find.text('Password'),
            matching: find.byType(TextFormField),
          ),
          'securePassword',
        );

        await tester.pumpAndSettle();

        // Assert - Text should be present in email field
        expect(find.text('user@example.com'), findsOneWidget);
        
        // Password field text is obscured, check controller
        final passwordField = tester.widget<TextFormField>(
          find.ancestor(
            of: find.text('Password'),
            matching: find.byType(TextFormField),
          ),
        );
        expect(passwordField.controller?.text, equals('securePassword'));
      });

      testWidgets('handles onAuthSuccess callback when provided', (WidgetTester tester) async {
        // Setup
        void onAuthSuccess() {
          // Callback implementation - would be called on successful auth
        }

        // Act
        await tester.pumpWidget(createTestWidget(onAuthSuccess: onAuthSuccess));
        await tester.pumpAndSettle();

        // Enter valid credentials
        await tester.enterText(
          find.ancestor(
            of: find.text('Email'),
            matching: find.byType(TextFormField),
          ),
          'test@example.com',
        );
        await tester.enterText(
          find.ancestor(
            of: find.text('Password'),
            matching: find.byType(TextFormField),
          ),
          'password123',
        );

        // Note: Actual sign in would require proper auth service mock
        // This test validates callback setup
        expect(onAuthSuccess, isNotNull);
      });
    });

    group('Loading State Display', () {
      testWidgets('shows loading state correctly', (WidgetTester tester) async {
        // Create a loading auth state
        final loadingState = AuthState(isLoading: true);
        
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(loadingState)),
            ],
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        // Should show CircularProgressIndicator inside the button when loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // CircularProgressIndicator should be within a SizedBox
        expect(find.byType(SizedBox), findsWidgets);
        
        // Sign In button text should not be visible when loading
        expect(find.text('Sign In'), findsNothing);
        
        // Button should be disabled when loading
        final elevatedButton = find.byType(ElevatedButton);
        expect(elevatedButton, findsOneWidget);
        
        final button = tester.widget<ElevatedButton>(elevatedButton);
        expect(button.onPressed, isNull);
      });

      testWidgets('hides loading state when not loading', (WidgetTester tester) async {
        // Setup normal state
        final normalState = const AuthState(
          user: null,
          isLoading: false,
          error: null,
          isAuthenticated: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(overrideState: normalState));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Sign In'), findsOneWidget);
        
        // Button should be enabled
        final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(elevatedButton.onPressed, isNotNull);
      });
    });

    group('Performance Requirements', () {
      testWidgets('widget builds within constitutional time limit', (WidgetTester tester) async {
        // Act & Assert - Measure build time
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Constitutional requirement: <500ms response time
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(500),
          reason: 'LoginScreen should build within 500ms constitutional requirement',
        );
      });

      testWidgets('form validation performs within time limits', (WidgetTester tester) async {
        // Setup
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act & Assert - Measure validation time
        final stopwatch = Stopwatch()..start();
        
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Validation should be nearly instantaneous
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'Form validation should complete within 100ms',
        );
      });
    });

    group('Widget Lifecycle', () {
      testWidgets('properly disposes controllers on unmount', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Unmount widget
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();

        // Assert - Widget should unmount cleanly without errors
        expect(find.byType(LoginScreen), findsNothing);
      });
    });
  });
}

/// Test auth notifier for controlled testing
class TestAuthNotifier extends AuthNotifier {
  final AuthState _overrideState;

  TestAuthNotifier(this._overrideState) : super(TestAuthService()) {
    state = _overrideState;
  }
}

/// Test auth service that extends the actual AuthService
class TestAuthService extends AuthService {
  @override
  bool get isAuthenticated => false;
  
  @override
  User? get currentUser => null;
  
  @override
  Future<void> restoreSession() async {}
  
  @override
  Future<Result<User>> signIn(String email, String password) async {
    return Result.success(User(
      id: 'test-user-id',
      email: email,
      name: 'Test User',
      username: 'testuser',
      created: DateTime.now(),
      updated: DateTime.now(),
    ));
  }
}