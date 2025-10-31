import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../lib/screens/login_screen.dart';
import '../../../lib/providers/auth_provider.dart';
import '../../test_helpers.dart';

void main() {
  group('LoginScreen Tests', () {
    late ProviderContainer container;

    setUp(() async {
      await TestHelpers.setupTestEnvironment();
      container = ProviderContainer();
    });

    tearDown(() async {
      container.dispose();
    });

    testWidgets('should render login form correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: const LoginScreen()),
        ),
      );

      // Wait for any async initialization
      await tester.pump(const Duration(milliseconds: 100));

      // Verify key elements are present
      expect(
        find.byType(TextFormField),
        findsNWidgets(2),
      ); // Email and password fields
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Don\'t have an account? Sign Up'), findsOneWidget);
    });

    testWidgets('should validate empty form fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: const LoginScreen()),
        ),
      );

      // Wait for initial session restoration
      await tester.pump(const Duration(milliseconds: 100));

      // Tap sign in button without filling fields
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should integrate with AuthProvider', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: const LoginScreen()),
        ),
      );

      // Verify that AuthProvider is accessible
      final authState = container.read(authProvider);
      expect(authState.user, isNull);
      expect(authState.isAuthenticated, isFalse);
    });
  });
}
