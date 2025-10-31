import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pocketbase_periolifts/screens/sign_up_screen.dart';

void main() {
  group('SignUpScreen Widget Tests', () {
    testWidgets('displays create account title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: SignUpScreen())),
      );

      // Verify title is displayed
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('displays all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: SignUpScreen())),
      );

      // Verify all form fields are present
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('displays sign up button and back button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: SignUpScreen())),
      );

      // Verify buttons are present
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('form handles empty submission', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: SignUpScreen())),
      );

      // Find the form and submit button
      final formFinder = find.byType(Form);
      final submitButton = find.byType(ElevatedButton);

      expect(formFinder, findsOneWidget);
      expect(submitButton, findsOneWidget);

      // Try to submit empty form - button should be tappable
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // The form should still be present (validation prevents submission)
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('form accepts valid input', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: SignUpScreen())),
      );

      // Fill form with valid data
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      // The form should accept the valid input
      expect(find.byType(TextFormField), findsNWidgets(4));

      // Submit button should be enabled (not disabled)
      final submitButton = find.byType(ElevatedButton);
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    });

    testWidgets('form fields accept input', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: SignUpScreen())),
      );

      // Test that fields can accept input
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test@example.com',
      );
      expect(find.text('test@example.com'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      // Password field should hide text, so we can't verify the text content
      expect(find.byType(TextFormField).at(2), findsOneWidget);
    });

    testWidgets('form handles interaction correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: SignUpScreen())),
      );

      // Verify form fields can be tapped and accept focus
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pump();

      await tester.tap(find.byType(TextFormField).at(1));
      await tester.pump();

      // Verify submit button is interactive
      final submitButton = find.byType(ElevatedButton);
      expect(submitButton, findsOneWidget);

      // Button should have an onPressed callback
      final buttonWidget = tester.widget<ElevatedButton>(submitButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('back button pops the screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => SignUpScreen()),
                  ),
                  child: Text('Go to Sign Up'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to sign up screen
      await tester.tap(find.text('Go to Sign Up'));
      await tester.pumpAndSettle();

      // Verify we're on sign up screen
      expect(find.text('Create Account'), findsOneWidget);

      // Tap back button
      await tester.tap(find.text('Already have an account? Sign In'));
      await tester.pumpAndSettle();

      // Should be back to original screen
      expect(find.text('Go to Sign Up'), findsOneWidget);
    });
  });
}
