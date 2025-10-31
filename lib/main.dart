import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
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
      home: _buildHomeScreen(authState),
    );
  }

  Widget _buildHomeScreen(AuthState authState) {
    // Show loading while checking authentication
    if (authState.isLoading && authState.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show temporary welcome screen if authenticated
    if (authState.user != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Welcome'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                // TODO: Get ref here to sign out
                // ref.read(authProvider.notifier).signOut();
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome, ${authState.user?.name ?? 'User'}!',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              const Text(
                'Dashboard coming soon...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show login screen if not authenticated
    return const LoginScreen();
  }
}
