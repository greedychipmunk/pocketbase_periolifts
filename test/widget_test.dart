// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'package:pocketbase_periolifts/main.dart';
import 'package:pocketbase_periolifts/screens/login_screen.dart';
import 'package:pocketbase_periolifts/providers/theme_provider.dart';
import 'package:pocketbase_periolifts/providers/units_provider.dart';
import 'package:pocketbase_periolifts/providers/rest_time_settings_provider.dart';

void main() {
  testWidgets('App shows LoginScreen when not authenticated', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame with proper provider setup
    await tester.pumpWidget(
      provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => ThemeProvider()),
          provider.ChangeNotifierProvider(create: (_) => UnitsProvider()),
          provider.ChangeNotifierProvider(create: (_) => RestTimeSettingsProvider()),
        ],
        child: const ProviderScope(child: PerioLiftsApp()),
      ),
    );

    // Allow async operations to complete
    await tester.pump();

    // Verify that we show the login screen when not authenticated
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
