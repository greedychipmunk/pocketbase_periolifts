import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_providers.dart';
import 'providers/workout_session_providers.dart';
import 'config/theme_config.dart';
import 'constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: PerioLiftsApp()));
}

class PerioLiftsApp extends ConsumerWidget {
  const PerioLiftsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: AppConstants.appName,
      theme: LightThemeConfig.themeData(),
      darkTheme: DarkThemeConfig.themeData(),
      themeMode: ThemeMode.system,
      home: _buildHomeScreen(authState, ref),
    );
  }

  Widget _buildHomeScreen(AuthState authState, WidgetRef ref) {
    // Show loading while checking authentication
    if (authState.isLoading && authState.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show DashboardScreen if authenticated
    if (authState.user != null) {
      // Use service providers instead of creating new instances
      final workoutService = ref.read(workoutServiceProvider);
      final workoutSessionService = ref.read(workoutSessionServiceProvider);
      final authService = ref.read(authServiceProvider);

      return DashboardScreen(
        workoutService: workoutService,
        workoutSessionService: workoutSessionService,
        authService: authService,
        onAuthError: () => _handleSignOut(ref),
        onLogout: () => _handleSignOut(ref),
      );
    }

    // Show login screen if not authenticated
    return const LoginScreen();
  }

  Future<void> _handleSignOut(WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
  }
}
