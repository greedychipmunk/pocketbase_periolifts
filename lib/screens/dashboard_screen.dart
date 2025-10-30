import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/workout_service.dart';
import '../services/workout_session_service.dart';
import '../services/workout_history_service.dart';
import '../services/auth_service.dart';
import '../models/workout.dart';
import '../models/workout_history.dart';
import '../widgets/base_layout.dart';
import '../widgets/workout_history_card.dart';
import 'workout_tracking_screen_riverpod.dart';
import 'workout_history_detail_screen.dart';
import '../constants/app_constants.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final WorkoutService workoutService;
  final WorkoutSessionService workoutSessionService;
  final AuthService authService;
  final VoidCallback onAuthError;
  final Future<void> Function()? onLogout;

  const DashboardScreen({
    Key? key,
    required this.workoutService,
    required this.workoutSessionService,
    required this.authService,
    required this.onAuthError,
    this.onLogout,
  }) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late WorkoutHistoryService _workoutHistoryService;
  List<WorkoutHistoryEntry> _workoutHistory = [];
  Workout? _todayWorkout;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _workoutHistoryService = WorkoutHistoryService(
      databases: widget.workoutService.databases,
      client: widget.authService.client,
    );
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get today's workout
      final nextWorkouts = await widget.workoutService.getNextThreeWorkouts();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if there's a workout scheduled for today
      Workout? todayWorkout;
      if (nextWorkouts.isNotEmpty) {
        final firstWorkout = nextWorkouts.first;
        final workoutDate = DateTime(
          firstWorkout.scheduledDate.year,
          firstWorkout.scheduledDate.month,
          firstWorkout.scheduledDate.day,
        );

        // Only show if it's scheduled for today and not completed
        if (workoutDate.isAtSameMomentAs(today) && !firstWorkout.isCompleted) {
          todayWorkout = firstWorkout;
        }
      }

      // Get workout history (past 30 days)
      final workoutHistory = await _workoutHistoryService.getWorkoutHistory(
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _todayWorkout = todayWorkout;
          _workoutHistory = workoutHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleError(BuildContext context, Object error) async {
    if (error is AuthenticationException) {
      widget.onAuthError();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      workoutService: widget.workoutService,
      workoutSessionService: widget.workoutSessionService,
      authService: widget.authService,
      onAuthError: widget.onAuthError,
      onLogout: widget.onLogout,
      currentIndex: 0, // Home tab
      title: AppConstants.appName,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWorkoutData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkoutData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Workout Section (if exists)
            if (_todayWorkout != null) ...[
              _buildTodayWorkoutSection(),
              const SizedBox(height: 24),
            ],

            // Past Workouts Section
            _buildPastWorkoutsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayWorkoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.today,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                'Next Workout',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        _buildTodayWorkoutCard(_todayWorkout!),
      ],
    );
  }

  Widget _buildTodayWorkoutCard(Workout workout) {
    return Card(
      elevation: 8.0,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _startWorkout(context, workout),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.08),
                Theme.of(context).colorScheme.tertiary.withOpacity(0.04),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${workout.exercises.length} exercises',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'TODAY',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPastWorkoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                'Past Workouts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        if (_workoutHistory.isEmpty)
          _buildEmptyState()
        else
          ..._workoutHistory.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: WorkoutHistoryCard(
                entry: entry,
                onTap: () => _navigateToWorkoutDetail(entry),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Past Workouts',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first workout to see it here!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToWorkoutDetail(WorkoutHistoryEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutHistoryDetailScreen(entry: entry),
      ),
    );
  }

  void _startWorkout(BuildContext context, Workout workout) async {
    // Check if workout has exercises
    if (workout.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This workout has no exercises to track'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // If this is a placeholder workout (generated from schedule), create a real workout document
      Workout actualWorkout = workout;
      if (workout.id.contains('-workout-')) {
        // This is a placeholder, create a real workout document
        actualWorkout = await widget.workoutService.createWorkout(workout);
      }

      // Navigate to workout tracking screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutTrackingScreenRiverpod(
            workout: actualWorkout,
            workoutService: widget.workoutService,
            authService: widget.authService,
            onAuthError: widget.onAuthError,
          ),
        ),
      );

      // If workout was completed, refresh the dashboard
      if (result == true && mounted) {
        // Reload the workout data to reflect the completion
        _loadWorkoutData();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting workout: $e')));
      }
    }
  }
}
