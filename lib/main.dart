import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/workout_service.dart';
import 'services/workout_session_service.dart';
import 'providers/theme_provider.dart';
import 'providers/units_provider.dart';
import 'providers/rest_time_settings_provider.dart';
import 'providers/workout_session_providers.dart';
import 'constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  Client client = Client();
  client
      .setEndpoint(dotenv.env['APPWRITE_PUBLIC_ENDPOINT']!)
      .setProject(dotenv.env['APPWRITE_PROJECT_ID']!)
      .setSelfSigned(status: true); // Enable for self-signed certificates

  final databases = Databases(client);
  final authService = AuthService(client: client);
  final workoutService = WorkoutService(
    databases: databases,
    client: client,
  );
  final workoutSessionService = WorkoutSessionService(
    databases: databases,
    client: client,
  );

  runApp(
    ProviderScope(
      overrides: [
        workoutSessionServiceProvider.overrideWithValue(workoutSessionService),
      ],
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (context) => ThemeProvider()),
          provider.ChangeNotifierProvider(create: (context) => UnitsProvider()),
          provider.ChangeNotifierProvider(create: (context) => RestTimeSettingsProvider()),
        ],
        child: PerioLiftsApp(
          authService: authService,
          workoutService: workoutService,
          workoutSessionService: workoutSessionService,
        ),
      ),
    ),
  );
}

class PerioLiftsApp extends StatefulWidget {
  final AuthService authService;
  final WorkoutService workoutService;
  final WorkoutSessionService workoutSessionService;

  const PerioLiftsApp({
    Key? key,
    required this.authService,
    required this.workoutService,
    required this.workoutSessionService,
  }) : super(key: key);

  @override
  State<PerioLiftsApp> createState() => _PerioLiftsAppState();
}

class _PerioLiftsAppState extends State<PerioLiftsApp> {
  bool? _isAuthenticated;
  bool _isCheckingAuth = false;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }
  
  void _onAuthSuccess() {
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    if (_isCheckingAuth) return;
    
    _isCheckingAuth = true;
    try {
      final isAuth = await widget.authService.isAuthenticated();
      if (mounted) {
        setState(() => _isAuthenticated = isAuth);
      }
    } finally {
      _isCheckingAuth = false;
    }
  }

  void _handleAuthError() {
    if (mounted) {
      setState(() => _isAuthenticated = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Immediately set auth state to false to prevent API calls
      if (mounted) {
        setState(() => _isAuthenticated = false);
      }
      // Then sign out from the backend
      await widget.authService.signOut();
    } catch (e) {
      print('Logout failed: $e');
      // Even if logout fails, keep user logged out locally for security
    }
  }

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: AppConstants.appName,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: _isAuthenticated == null
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _isAuthenticated == true
              ? DashboardScreen(
                  workoutService: widget.workoutService,
                  authService: widget.authService,
                  workoutSessionService: widget.workoutSessionService,
                  onAuthError: _handleAuthError,
                  onLogout: _handleLogout,
                )
              : LoginScreen(
                  authService: widget.authService,
                  workoutService: widget.workoutService,
                  onAuthSuccess: _onAuthSuccess,
                ),
        );
      },
    );
  }
}
