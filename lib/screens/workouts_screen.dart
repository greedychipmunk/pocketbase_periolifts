import 'package:flutter/material.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../models/workout.dart';
import '../widgets/workout_card.dart';
import '../widgets/base_layout.dart';
import 'workout_tracking_screen_riverpod.dart';

class WorkoutsScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final AuthService authService;
  final VoidCallback onAuthError;

  const WorkoutsScreen({
    Key? key,
    required this.workoutService,
    required this.authService,
    required this.onAuthError,
  }) : super(key: key);

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  List<Workout> _workouts = [];
  List<Workout> _nextWorkouts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'all'; // all, upcoming, completed, in_progress

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final workouts = await widget.workoutService.getWorkouts();
      final nextWorkouts = await widget.workoutService.getNextThreeWorkouts();
      if (mounted) {
        setState(() {
          _workouts = workouts;
          _nextWorkouts = nextWorkouts;
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

  List<Workout> _getFilteredWorkouts() {
    final now = DateTime.now();

    switch (_filter) {
      case 'upcoming':
        return _workouts
            .where(
              (w) =>
                  w.scheduledDate.isAfter(now) &&
                  !w.isCompleted &&
                  !w.isInProgress,
            )
            .toList();
      case 'completed':
        return _workouts.where((w) => w.isCompleted).toList();
      case 'in_progress':
        return _workouts.where((w) => w.isInProgress).toList();
      case 'all':
      default:
        return _workouts;
    }
  }

  bool _isWorkoutStartable(Workout workout) {
    // Only the first workout in the next workouts list is startable
    return _nextWorkouts.isNotEmpty &&
        _nextWorkouts.first.id == workout.id &&
        !workout.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      workoutService: widget.workoutService,
      authService: widget.authService,
      onAuthError: widget.onAuthError,
      currentIndex: 0, // Workouts accessed from Home/Dashboard
      title: 'PerioLifts',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWorkouts),
      ],
      child: Column(
        children: [
          // Workouts list
          Expanded(child: _buildWorkoutsList()),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList() {
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
              'Error loading workouts',
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
              onPressed: _loadWorkouts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredWorkouts = _getFilteredWorkouts();

    if (filteredWorkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubMessage(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkouts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: filteredWorkouts.length,
        itemBuilder: (context, index) {
          final workout = filteredWorkouts[index];
          final isStartable = _isWorkoutStartable(workout);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: WorkoutCard(
              workout: workout,
              onTap: () => _onWorkoutTap(workout),
              onToggleComplete: () => _toggleWorkoutComplete(workout),
              onStartWorkout: !workout.isCompleted
                  ? () => _startWorkout(workout)
                  : null,
              isStartable: isStartable,
            ),
          );
        },
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_filter) {
      case 'upcoming':
        return 'No upcoming workouts';
      case 'completed':
        return 'No completed workouts';
      case 'in_progress':
        return 'No workouts in progress';
      case 'all':
      default:
        return 'No workouts found';
    }
  }

  String _getEmptySubMessage() {
    switch (_filter) {
      case 'upcoming':
        return 'Schedule some workouts to get started!';
      case 'completed':
        return 'Complete some workouts to see them here.';
      case 'in_progress':
        return 'Start a workout to track your progress here.';
      case 'all':
      default:
        return 'Create your first workout to get started!';
    }
  }

  void _onWorkoutTap(Workout workout) async {
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

      if (result == true) {
        _loadWorkouts(); // Refresh the list if workout was completed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening workout: $e')));
      }
    }
  }

  void _startWorkout(Workout workout) async {
    // Check if this workout is startable
    if (!_isWorkoutStartable(workout)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete your current workout before starting this one',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

      if (result == true) {
        _loadWorkouts(); // Refresh the list if workout was completed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting workout: $e')));
      }
    }
  }

  Future<bool> _showCompletionConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mark Workout as Completed?'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to mark this workout as completed?',
                ),
                SizedBox(height: 12),
                Text(
                  '⚠️ This will mark the workout as complete without tracking individual exercises and sets.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'For proper progress tracking, consider starting the workout and completing each exercise.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Mark Complete Anyway'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _toggleWorkoutComplete(Workout workout) async {
    try {
      // If trying to mark as completed, show warning that this bypasses exercise validation
      if (!workout.isCompleted) {
        final confirmed = await _showCompletionConfirmationDialog();
        if (!confirmed) {
          return;
        }
      }

      final updatedWorkout = workout.copyWith(
        isCompleted: !workout.isCompleted,
        completedDate: workout.isCompleted ? null : DateTime.now(),
      );

      await widget.workoutService.updateWorkout(updatedWorkout);

      // Refresh the list
      _loadWorkouts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedWorkout.isCompleted
                ? 'Workout manually marked as completed!'
                : 'Workout marked as incomplete',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating workout: $e')));
    }
  }
}
