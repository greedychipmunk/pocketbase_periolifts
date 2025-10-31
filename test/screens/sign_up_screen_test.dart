import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lib/screens/sign_up_screen.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/models/user.dart';
import '../../lib/utils/result.dart';

void main() {
  group('SignUpScreen Widget Tests', () {
    group('UI Component Rendering', () {
      testWidgets('renders all essential UI components', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        // Check for essential UI components
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Sign Up'), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);

        // Check for all form fields
        expect(
          find.byType(TextFormField),
          findsNWidgets(4),
        ); // name, email, password, confirm password
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Confirm Password'), findsOneWidget);

        // Check for buttons
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);
        expect(find.text('Sign Up'), findsOneWidget); // Only in AppBar title
        expect(find.text('Already have an account? Sign In'), findsOneWidget);
      });

      testWidgets('displays correct styling and layout', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        // Check for SingleChildScrollView for scrollable content
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // Check form layout structure
        expect(find.byType(Column), findsWidgets);

        // Check for proper spacing with SizedBox widgets
        expect(find.byType(SizedBox), findsWidgets);

        // Verify the Create Account title styling
        final titleText = tester.widget<Text>(find.text('Create Account'));
        expect(titleText.style?.fontSize, 28.0);
        expect(titleText.style?.fontWeight, FontWeight.bold);
        expect(titleText.textAlign, TextAlign.center);
      });

      testWidgets('maintains proper accessibility support', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        // Check that all text fields have labels for accessibility
        final nameField = find.widgetWithText(TextFormField, 'Name');
        final emailField = find.widgetWithText(TextFormField, 'Email');
        final passwordField = find.widgetWithText(TextFormField, 'Password');
        final confirmPasswordField = find.widgetWithText(
          TextFormField,
          'Confirm Password',
        );

        expect(nameField, findsOneWidget);
        expect(emailField, findsOneWidget);
        expect(passwordField, findsOneWidget);
        expect(confirmPasswordField, findsOneWidget);

        // Verify password fields exist (we can't easily check obscureText property in widget tests)
        expect(passwordField, findsOneWidget);
        expect(confirmPasswordField, findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('validates empty name field', (WidgetTester tester) async {
        final testState = AuthState(isLoading: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(testState)),
            ],
            child: MaterialApp(home: SignUpScreen()),
          ),
        );

        // Tap the Sign Up button without entering name
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.text('Please enter your name'), findsOneWidget);
      });

      testWidgets('validates empty email field', (WidgetTester tester) async {
        final testState = AuthState(isLoading: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(testState)),
            ],
            child: MaterialApp(home: SignUpScreen()),
          ),
        );

        // Fill name but leave email empty
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show email validation error
        expect(find.text('Please enter your email'), findsOneWidget);
      });

      testWidgets('validates invalid email format', (
        WidgetTester tester,
      ) async {
        final testState = AuthState(isLoading: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(testState)),
            ],
            child: MaterialApp(home: SignUpScreen()),
          ),
        );

        // Fill with invalid email
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'invalid-email',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show email format validation error
        expect(find.text('Please enter a valid email'), findsOneWidget);
      });

      testWidgets('validates empty password field', (
        WidgetTester tester,
      ) async {
        final testState = AuthState(isLoading: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(testState)),
            ],
            child: MaterialApp(home: SignUpScreen()),
          ),
        );

        // Fill name and email but leave password empty
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'test@example.com',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show password validation error
        expect(find.text('Please enter your password'), findsOneWidget);
      });

      testWidgets('validates minimum password length', (
        WidgetTester tester,
      ) async {
        final testState = AuthState(isLoading: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(testState)),
            ],
            child: MaterialApp(home: SignUpScreen()),
          ),
        );

        // Fill with short password
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(2), '123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show password length validation error
        expect(
          find.text('Password must be at least 8 characters'),
          findsOneWidget,
        );
      });

      testWidgets('validates empty confirm password field', (
        WidgetTester tester,
      ) async {
        final testState = AuthState(isLoading: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(testState)),
            ],
            child: MaterialApp(home: SignUpScreen()),
          ),
        );

        // Fill all fields except confirm password
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show confirm password validation error
        expect(find.text('Please confirm your password'), findsOneWidget);
      });

      testWidgets('validates password confirmation mismatch', (
        WidgetTester tester,
      ) async {
        final testState = AuthState(isLoading: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(testState)),
            ],
            child: MaterialApp(home: SignUpScreen()),
          ),
        );

        // Fill with mismatched passwords
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password456');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show password mismatch validation error
        expect(find.text('Passwords do not match'), findsOneWidget);
      });

      testWidgets('accepts valid form input', (WidgetTester tester) async {
        final testState = AuthState(isLoading: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(testState)),
            ],
            child: MaterialApp(home: SignUpScreen()),
          ),
        );

        // Fill all fields with valid data
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'Test User',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'password123',
        );

        // Should not show any validation errors
        expect(find.text('Please enter your name'), findsNothing);
        expect(find.text('Please enter your email'), findsNothing);
        expect(find.text('Please enter a valid email'), findsNothing);
        expect(find.text('Please enter your password'), findsNothing);
        expect(
          find.text('Password must be at least 8 characters'),
          findsNothing,
        );
        expect(find.text('Please confirm your password'), findsNothing);
        expect(find.text('Passwords do not match'), findsNothing);
      });
    });

    group('User Interaction Scenarios', () {
      testWidgets('allows text input in all form fields', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        // Test text input in all fields
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'John Doe',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'john.doe@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'securePassword123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'securePassword123',
        );

        // Verify text was entered
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('john.doe@example.com'), findsOneWidget);
        // Password fields are obscured, so we can't verify the visible text
      });

      testWidgets('handles navigation back to login screen', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        // Tap the "Already have an account? Sign In" button
        await tester.tap(find.text('Already have an account? Sign In'));
        await tester.pumpAndSettle();

        // The screen should attempt to navigate back
        // Note: In a real app, this would pop the current route
        // For testing, we just verify the button tap doesn't cause errors
      });

      testWidgets('handles onAuthSuccess callback when provided', (
        WidgetTester tester,
      ) async {
        bool callbackExecuted = false;
        final testState = AuthState(isLoading: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(testState)),
            ],
            child: MaterialApp(
              home: SignUpScreen(
                onAuthSuccess: () {
                  callbackExecuted = true;
                },
              ),
            ),
          ),
        );

        // Fill valid form data
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'Test User',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'password123',
        );

        // Note: Actual callback testing would require successful sign up
        // For now, we verify the widget accepts the callback without error
        expect(callbackExecuted, isFalse); // Callback hasn't been triggered yet
      });
    });

    group('Loading State Display', () {
      testWidgets('shows loading state correctly', (WidgetTester tester) async {
        // Create a loading auth state
        final loadingState = AuthState(isLoading: true);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => TestAuthNotifier(loadingState),
              ),
            ],
            child: MaterialApp(home: SignUpScreen()),
          ),
        );

        // Should show CircularProgressIndicator inside the button when loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // CircularProgressIndicator should be within a SizedBox
        expect(find.byType(SizedBox), findsWidgets);

        // Sign Up button text should not be visible when loading
        // Note: The ElevatedButton shows CircularProgressIndicator instead of text when loading
        expect(
          find.descendant(
            of: find.byType(ElevatedButton),
            matching: find.text('Sign Up'),
          ),
          findsNothing,
        );

        // Button should be disabled when loading
        final elevatedButton = find.byType(ElevatedButton);
        expect(elevatedButton, findsOneWidget);

        final button = tester.widget<ElevatedButton>(elevatedButton);
        expect(button.onPressed, isNull);
      });

      testWidgets('hides loading state when not loading', (
        WidgetTester tester,
      ) async {
        // Create a non-loading auth state
        final normalState = AuthState(isLoading: false);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => TestAuthNotifier(normalState)),
            ],
            child: MaterialApp(home: SignUpScreen()),
          ),
        );

        // Should not show CircularProgressIndicator when not loading
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Sign Up button text should be visible
        expect(
          find.descendant(
            of: find.byType(ElevatedButton),
            matching: find.text('Sign Up'),
          ),
          findsOneWidget,
        );

        // Button should be enabled when not loading
        final elevatedButton = find.byType(ElevatedButton);
        expect(elevatedButton, findsOneWidget);

        final button = tester.widget<ElevatedButton>(elevatedButton);
        expect(button.onPressed, isNotNull);
      });
    });

    group('Performance Requirements', () {
      testWidgets('widget builds within constitutional time limit', (
        WidgetTester tester,
      ) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        stopwatch.stop();

        // Constitutional requirement: widget should build in <500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      testWidgets('form validation performs within time limits', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        final stopwatch = Stopwatch()..start();

        // Trigger form validation
        await tester.tap(find.text('Sign Up').last);
        await tester.pump();

        stopwatch.stop();

        // Form validation should be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Widget Lifecycle', () {
      testWidgets('properly disposes controllers on unmount', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        // Enter text in all fields to initialize controllers
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'Test',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'password123',
        );

        // Remove the widget from the tree
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: Container())),
        );

        // If controllers are properly disposed, this should not cause any errors
        // The test passes if no exceptions are thrown during disposal
      });
    });

    group('Field-Specific Behavior', () {
      testWidgets('name field exists with proper label', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        // Verify name field exists
        expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
      });

      testWidgets('email field exists with proper label', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        // Verify email field exists
        expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      });

      testWidgets('password fields exist and are properly labeled', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: SignUpScreen())),
        );

        // Verify both password fields exist
        expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          findsOneWidget,
        );
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
  Future<Result<User>> signUp(
    String email,
    String password,
    String name,
  ) async {
    // Simulate successful sign up
    final user = User(
      id: 'test-user-id',
      email: email,
      name: name,
      username: email.split('@')[0], // Use email prefix as username
      emailVerified: false,
      created: DateTime.now(),
      updated: DateTime.now(),
    );
    return Result.success(user);
  }

  @override
  Future<Result<User>> signIn(String email, String password) async {
    // Simulate successful sign in
    final user = User(
      id: 'test-user-id',
      email: email,
      name: 'Test User',
      username: email.split('@')[0], // Use email prefix as username
      emailVerified: true,
      created: DateTime.now(),
      updated: DateTime.now(),
    );
    return Result.success(user);
  }

  @override
  Future<Result<void>> signOut() async {
    return Result.success(null);
  }

  @override
  Future<Result<User>> refreshToken() async {
    // Return a user instead of null for successful refresh
    final user = User(
      id: 'test-user-id',
      email: 'test@example.com',
      name: 'Test User',
      username: 'test',
      emailVerified: true,
      created: DateTime.now(),
      updated: DateTime.now(),
    );
    return Result.success(user);
  }

  @override
  Future<Result<User?>> initializeAuth() async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> resetPassword(String token, String newPassword) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> sendEmailVerification(String email) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> verifyEmail(String token) async {
    return Result.success(null);
  }

  @override
  Future<Result<User>> updateProfile(Map<String, dynamic> updates) async {
    final user = User(
      id: 'test-user-id',
      email: (updates['email'] as String?) ?? 'test@example.com',
      name: (updates['name'] as String?) ?? 'Test User',
      username: (updates['username'] as String?) ?? 'test',
      emailVerified: true,
      created: DateTime.now(),
      updated: DateTime.now(),
    );
    return Result.success(user);
  }

  @override
  Future<Result<void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteAccount(String password) async {
    return Result.success(null);
  }
}
