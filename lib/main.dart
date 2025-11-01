import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'services/workout_service.dart';
import 'services/workout_session_service.dart';
import 'services/auth_service.dart';
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
      // Initialize services
      final workoutService = WorkoutService();
      final workoutSessionService = WorkoutSessionService();
      final authService = ref.read(authServiceProvider);

      return DashboardScreen(
        workoutService: workoutService,
        workoutSessionService: workoutSessionService,
        authService: authService,
        onAuthError: () {
          // Handle authentication error by signing out
          ref.read(authProvider.notifier).signOut();
        },
        onLogout: () async {
          await ref.read(authProvider.notifier).signOut();
        },
      );
    }

    // Show login screen if not authenticated
    return const LoginScreen();
  }
}
