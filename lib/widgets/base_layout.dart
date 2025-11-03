import 'package:flutter/material.dart';
import '../services/workout_service.dart';
import '../services/workout_session_service.dart';
import '../services/workout_history_service.dart';
import '../services/auth_service.dart';
import '../screens/dashboard_screen.dart';
import '../screens/programs_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/enhanced_workout_history_screen.dart';
import '../screens/settings_screen.dart';

class BaseLayout extends StatefulWidget {
  final Widget child;
  final WorkoutService workoutService;
  final WorkoutSessionService? workoutSessionService;
  final WorkoutHistoryService? workoutHistoryService;
  final AuthService authService;
  final VoidCallback onAuthError;
  final Future<void> Function()? onLogout;
  final int currentIndex;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const BaseLayout({
    Key? key,
    required this.child,
    required this.workoutService,
    this.workoutSessionService,
    this.workoutHistoryService,
    required this.authService,
    required this.onAuthError,
    this.onLogout,
    required this.currentIndex,
    required this.title,
    this.actions,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  void _onNavigationTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return; // Don't navigate to same screen

    Widget targetScreen;
    switch (index) {
      case 0: // Home
        // Always use DashboardScreen for Home
        // Create WorkoutSessionService if not provided
        final sessionService = widget.workoutSessionService ??
            WorkoutSessionService();
        targetScreen = DashboardScreen(
          workoutService: widget.workoutService,
          workoutSessionService: sessionService,
          authService: widget.authService,
          onAuthError: widget.onAuthError,
          onLogout: widget.onLogout,
        );
        break;
      case 1: // Programs
        targetScreen = ProgramsScreen(
          workoutService: widget.workoutService,
          authService: widget.authService,
          onAuthError: widget.onAuthError,
        );
        break;
      case 2: // Calendar
        targetScreen = CalendarScreen(
          workoutService: widget.workoutService,
          authService: widget.authService,
          onAuthError: widget.onAuthError,
        );
        break;
      case 3: // Progress
        if (widget.workoutHistoryService != null) {
          // Use enhanced workout history screen if service is available
          targetScreen = const EnhancedWorkoutHistoryScreen();
        } else {
          // Fallback to original progress screen
          targetScreen = ProgressScreen(
            workoutService: widget.workoutService,
            authService: widget.authService,
            onAuthError: widget.onAuthError,
          );
        }
        break;
      case 4: // Settings
        targetScreen = SettingsScreen(
          workoutService: widget.workoutService,
          authService: widget.authService,
          onAuthError: widget.onAuthError,
        );
        break;
      default:
        return;
    }

    // Replace current screen with new screen
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => targetScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: widget.actions,
        // Add subtle gradient effect using flexibleSpace
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: widget.currentIndex,
          onTap: (index) => _onNavigationTap(context, index),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_rounded),
              label: 'Programs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
