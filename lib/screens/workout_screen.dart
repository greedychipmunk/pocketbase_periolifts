import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../providers/workout_providers.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = const WorkoutTemplatesFilter(userOnly: true);
    final workoutsAsync = ref.watch(workoutTemplatesProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createWorkout(context, ref),
          ),
        ],
      ),
      body: workoutsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorMessage(
          message: 'Failed to load workouts: $error',
          onRetry: () => ref.refresh(workoutTemplatesProvider(filter)),
        ),
        data: (workouts) => ListView.builder(
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index];
            return ListTile(
              title: Text(workout.name),
              subtitle: Text(
                'Exercises: ${workout.exercises.length} • ${workout.estimatedDuration} min',
              ),
              trailing: workout.description?.isNotEmpty == true
                  ? const Icon(Icons.notes, color: Colors.grey)
                  : null,
              onTap: () => _navigateToWorkoutDetail(workout),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createWorkout(BuildContext context, WidgetRef ref) async {
    final name = await _showWorkoutNameDialog(context);
    if (name == null) return;

    final now = DateTime.now();
    final workout = Workout(
      id: '',
      created: now,
      updated: now,
      name: name,
      description: null,
      estimatedDuration: 60, // Default 60 minutes
      exercises: [],
      userId: '', // Will be set by WorkoutService
    );

    final filter = const WorkoutTemplatesFilter(userOnly: true);
    final notifier = ref.read(workoutTemplatesProvider(filter).notifier);

    try {
      await notifier.createWorkout(workout);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create workout: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showWorkoutNameDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Workout'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Workout Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _navigateToWorkoutDetail(Workout workout) {
    // TODO: Implement workout detail screen navigation
  }
}
