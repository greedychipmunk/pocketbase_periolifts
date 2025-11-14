import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/programs_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_providers.dart';
import 'providers/workout_session_providers.dart';
import 'providers/workout_plan_providers.dart';
import 'providers/theme_provider.dart';
import 'providers/units_provider.dart';
import 'providers/rest_time_settings_provider.dart';
import 'config/theme_config.dart';
import 'constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => ThemeProvider()),
        provider.ChangeNotifierProvider(create: (_) => UnitsProvider()),
        provider.ChangeNotifierProvider(create: (_) => RestTimeSettingsProvider()),
      ],
      child: const ProviderScope(child: PerioLiftsApp()),
    ),
  );
}

class PerioLiftsApp extends ConsumerWidget {
  const PerioLiftsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return provider.Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          theme: LightThemeConfig.themeData(),
          darkTheme: DarkThemeConfig.themeData(),
          themeMode: themeProvider.themeMode,
          home: _buildHomeScreen(authState, ref),
        );
      },
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
      final workoutPlanService = ref.read(workoutPlanServiceProvider);

      // Check if user has active programs with future workouts
      return FutureBuilder<bool>(
        future: _checkActiveProgramsWithFutureWorkouts(workoutPlanService),
        builder: (context, snapshot) {
          // Show loading while checking for active programs
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If there's an error or user has no active programs with future workouts,
          // redirect to Programs screen
          if (snapshot.hasError || snapshot.data == false) {
            return ProgramsScreen(
              workoutService: workoutService,
              authService: authService,
              onAuthError: () => _handleSignOut(ref),
            );
          }

          // User has active programs, show dashboard
          return DashboardScreen(
            workoutService: workoutService,
            workoutSessionService: workoutSessionService,
            authService: authService,
            onAuthError: () => _handleSignOut(ref),
            onLogout: () => _handleSignOut(ref),
          );
        },
      );
    }

    // Show login screen if not authenticated
    return const LoginScreen();
  }

  Future<bool> _checkActiveProgramsWithFutureWorkouts(
    dynamic workoutPlanService,
  ) async {
    final result =
        await workoutPlanService.hasActiveProgramsWithFutureWorkouts();
    if (result.isSuccess) {
      return result.data as bool;
    }
    // On error, default to false to redirect to Programs screen
    return false;
  }

  Future<void> _handleSignOut(WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
  }
}
