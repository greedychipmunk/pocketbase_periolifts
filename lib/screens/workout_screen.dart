import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/workout_service.dart';
import '../services/exercise_service.dart';

class WorkoutScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final ExerciseService exerciseService;

  const WorkoutScreen({
    Key? key,
    required this.workoutService,
    required this.exerciseService,
  }) : super(key: key);

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<Workout> workouts = [];
  List<Exercise> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _loadExercises();
  }

  Future<void> _loadWorkouts() async {
    final result = await widget.workoutService.getWorkouts();
    if (result.isSuccess) {
      setState(() {
        workouts = result.data!;
        isLoading = false;
      });
    } else {
      _showError('Failed to load workouts: ${result.error!.message}');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadExercises() async {
    final result = await widget.exerciseService.getExercises();
    if (result.isSuccess) {
      setState(() {
        exercises = result.data!;
      });
    } else {
      _showError('Failed to load exercises: ${result.error!.message}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _createWorkout() async {
    final name = await _showWorkoutNameDialog();
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

    final result = await widget.workoutService.createWorkout(workout);
    if (result.isSuccess) {
      setState(() {
        workouts.add(result.data!);
      });
    } else {
      _showError('Failed to create workout: ${result.error!.message}');
    }
  }

  Future<String?> _showWorkoutNameDialog() {
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createWorkout),
        ],
      ),
      body: ListView.builder(
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
    );
  }

  void _navigateToWorkoutDetail(Workout workout) {
    // TODO: Implement workout detail screen navigation
  }
}
