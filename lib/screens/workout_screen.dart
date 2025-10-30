import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/workout_service.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';

class WorkoutScreen extends StatefulWidget {
  final WorkoutService workoutService;

  const WorkoutScreen({Key? key, required this.workoutService})
    : super(key: key);

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
    try {
      final loadedWorkouts = await widget.workoutService.getWorkouts();
      setState(() {
        workouts = loadedWorkouts;
        isLoading = false;
      });
    } catch (e) {
      _showError('Failed to load workouts');
    }
  }

  Future<void> _loadExercises() async {
    try {
      final loadedExercises = await widget.workoutService.getExercises();
      setState(() {
        exercises = loadedExercises;
      });
    } catch (e) {
      _showError('Failed to load exercises');
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

    final workout = Workout(
      id: '', // Will be set by Appwrite
      userId: '', // Will be set by WorkoutService
      name: name,
      scheduledDate: DateTime.now(),
      exercises: [],
    );

    try {
      final createdWorkout = await widget.workoutService.createWorkout(workout);
      setState(() {
        workouts.add(createdWorkout);
      });
    } catch (e) {
      _showError('Failed to create workout');
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
              DateFormat('EEEE, MMMM d, y').format(workout.scheduledDate),
            ),
            trailing: workout.isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green)
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
