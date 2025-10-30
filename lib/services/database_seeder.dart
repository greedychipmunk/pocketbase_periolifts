import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import 'workout_service.dart';

class DatabaseSeeder {
  final WorkoutService workoutService;
  final String userId;

  DatabaseSeeder({required this.workoutService, required this.userId});

  /// Seeds all collections with test data
  Future<void> seedAll() async {
    print('🌱 Starting database seeding...');

    try {
      // Clear existing data first (optional)
      await clearAllData();

      // Seed in order: exercises first, then workout plans, then workouts
      final exercises = await seedExercises();
      print('✅ Seeded ${exercises.length} exercises');

      final workoutPlans = await seedWorkoutPlans();
      print('✅ Seeded ${workoutPlans.length} workout plans');

      final workouts = await seedWorkouts(exercises);
      print('✅ Seeded ${workouts.length} workouts');

      print('🎉 Database seeding completed successfully!');
    } catch (e) {
      print('❌ Error seeding database: $e');
      rethrow;
    }
  }

  /// Seeds the exercises collection with common exercises
  Future<List<Exercise>> seedExercises() async {
    final exercises = _generateSampleExercises();
    final createdExercises = <Exercise>[];

    for (final exercise in exercises) {
      try {
        final created = await workoutService.createExercise(exercise);
        createdExercises.add(created);
      } catch (e) {
        print('Warning: Could not create exercise ${exercise.name}: $e');
      }
    }

    return createdExercises;
  }

  /// Seeds the workout plans collection
  Future<List<WorkoutPlan>> seedWorkoutPlans() async {
    final workoutPlans = _generateSampleWorkoutPlans();
    final createdPlans = <WorkoutPlan>[];

    for (final plan in workoutPlans) {
      try {
        final created = await workoutService.createWorkoutPlan(plan);
        createdPlans.add(created);
      } catch (e) {
        print('Warning: Could not create workout plan ${plan.name}: $e');
      }
    }

    return createdPlans;
  }

  /// Seeds the workouts collection
  Future<List<Workout>> seedWorkouts(List<Exercise> exercises) async {
    final workouts = _generateSampleWorkouts(exercises);
    final createdWorkouts = <Workout>[];

    for (final workout in workouts) {
      try {
        final created = await workoutService.createWorkout(workout);
        createdWorkouts.add(created);
      } catch (e) {
        print('Warning: Could not create workout ${workout.name}: $e');
      }
    }

    return createdWorkouts;
  }

  /// Clears all data from collections (use with caution!)
  Future<void> clearAllData() async {
    print('🧹 Clearing existing data...');

    try {
      // Clear workouts first (they depend on exercises)
      final workouts = await workoutService.getWorkouts();
      for (final workout in workouts) {
        await workoutService.deleteWorkout(workout.id);
      }

      // Clear workout plans
      final plans = await workoutService.getWorkoutPlans();
      for (final plan in plans) {
        await workoutService.deleteWorkoutPlan(plan.id);
      }

      // Clear exercises last
      final exercises = await workoutService.getExercises();
      for (final exercise in exercises) {
        await workoutService.deleteExercise(exercise.id);
      }
    } catch (e) {
      print('Warning: Error clearing data: $e');
    }
  }

  /// Generates sample exercises
  List<Exercise> _generateSampleExercises() {
    return [
      Exercise(
        id: '',
        name: 'Bench Press',
        description: 'Lie on a bench and press weight up from chest level',
        muscleGroups: ['chest', 'shoulders', 'triceps'],
        videoUrl: 'https://example.com/bench-press',
      ),
      Exercise(
        id: '',
        name: 'Squats',
        description:
            'Stand with feet shoulder-width apart, lower body as if sitting',
        muscleGroups: ['quadriceps', 'glutes', 'hamstrings'],
        videoUrl: 'https://example.com/squats',
      ),
      Exercise(
        id: '',
        name: 'Deadlift',
        description: 'Lift weight from floor to hip level with straight back',
        muscleGroups: ['hamstrings', 'glutes', 'back', 'traps'],
        videoUrl: 'https://example.com/deadlift',
      ),
      Exercise(
        id: '',
        name: 'Overhead Press',
        description: 'Press weight overhead from shoulder level',
        muscleGroups: ['shoulders', 'triceps', 'core'],
        videoUrl: 'https://example.com/overhead-press',
      ),
      Exercise(
        id: '',
        name: 'Pull-ups',
        description: 'Pull body up until chin is above the bar',
        muscleGroups: ['lats', 'biceps', 'rhomboids'],
        videoUrl: 'https://example.com/pull-ups',
      ),
      Exercise(
        id: '',
        name: 'Rows',
        description: 'Pull weight towards torso from arms extended position',
        muscleGroups: ['lats', 'rhomboids', 'rear-delts', 'biceps'],
        videoUrl: 'https://example.com/rows',
      ),
      Exercise(
        id: '',
        name: 'Dips',
        description: 'Lower body by bending arms, then push back up',
        muscleGroups: ['triceps', 'chest', 'shoulders'],
        videoUrl: 'https://example.com/dips',
      ),
      Exercise(
        id: '',
        name: 'Lunges',
        description: 'Step forward into lunge position, alternate legs',
        muscleGroups: ['quadriceps', 'glutes', 'hamstrings'],
        videoUrl: 'https://example.com/lunges',
      ),
      Exercise(
        id: '',
        name: 'Planks',
        description: 'Hold body in straight line from head to heels',
        muscleGroups: ['core', 'shoulders', 'glutes'],
        videoUrl: 'https://example.com/planks',
      ),
      Exercise(
        id: '',
        name: 'Bicep Curls',
        description: 'Curl weights up to shoulder level, focusing on biceps',
        muscleGroups: ['biceps'],
        videoUrl: 'https://example.com/bicep-curls',
      ),
    ];
  }

  /// Generates sample workout plans
  List<WorkoutPlan> _generateSampleWorkoutPlans() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);

    return [
      WorkoutPlan(
        id: '',
        userId: userId,
        name: 'Push Pull Legs',
        description:
            'Classic 3-day split focusing on push, pull, and leg movements',
        createdAt: now,
        startDate: startDate,
        schedule: {}, // Simplified for seeding
        isActive: true,
      ),
      WorkoutPlan(
        id: '',
        userId: userId,
        name: 'Full Body Beginner',
        description: 'Full body workout for beginners, 3 times per week',
        createdAt: now,
        startDate: startDate,
        schedule: {}, // Simplified for seeding
        isActive: true,
      ),
      WorkoutPlan(
        id: '',
        userId: userId,
        name: 'Upper Lower Split',
        description: '4-day upper/lower body split',
        createdAt: now,
        startDate: startDate,
        schedule: {}, // Simplified for seeding
        isActive: false,
      ),
    ];
  }

  /// Generates sample workouts
  List<Workout> _generateSampleWorkouts(List<Exercise> exercises) {
    final now = DateTime.now();
    final workouts = <Workout>[];

    // Create workouts for the next 2 weeks
    for (int i = 0; i < 14; i++) {
      final workoutDate = now.add(Duration(days: i));

      // Skip weekends for some variety
      if (workoutDate.weekday == 6 || workoutDate.weekday == 7) continue;

      final workout = _createSampleWorkout(
        workoutDate,
        exercises,
        i % 3, // Rotate between different workout types
      );

      if (workout != null) {
        workouts.add(workout);
      }
    }

    return workouts;
  }

  /// Creates a sample workout based on type
  Workout? _createSampleWorkout(
    DateTime date,
    List<Exercise> exercises,
    int workoutType,
  ) {
    if (exercises.isEmpty) return null;

    final workoutNames = ['Push Day', 'Pull Day', 'Leg Day'];

    final workoutDescriptions = [
      'Focus on pushing movements - chest, shoulders, triceps',
      'Focus on pulling movements - back, biceps',
      'Focus on legs - quads, hamstrings, glutes',
    ];

    // Select exercises based on workout type
    List<Exercise> selectedExercises;
    switch (workoutType) {
      case 0: // Push
        selectedExercises = exercises
            .where(
              (e) => e.muscleGroups.any(
                (mg) => ['chest', 'shoulders', 'triceps'].contains(mg),
              ),
            )
            .take(4)
            .toList();
        break;
      case 1: // Pull
        selectedExercises = exercises
            .where(
              (e) => e.muscleGroups.any(
                (mg) => ['lats', 'biceps', 'rhomboids', 'back'].contains(mg),
              ),
            )
            .take(4)
            .toList();
        break;
      case 2: // Legs
        selectedExercises = exercises
            .where(
              (e) => e.muscleGroups.any(
                (mg) => ['quadriceps', 'glutes', 'hamstrings'].contains(mg),
              ),
            )
            .take(4)
            .toList();
        break;
      default:
        selectedExercises = exercises.take(4).toList();
    }

    if (selectedExercises.isEmpty) {
      selectedExercises = exercises.take(4).toList();
    }

    final workoutExercises = selectedExercises.map((exercise) {
      return WorkoutExercise(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        sets: _generateSampleSets(exercise),
      );
    }).toList();

    return Workout(
      id: '',
      userId: userId,
      name: workoutNames[workoutType],
      description: workoutDescriptions[workoutType],
      scheduledDate: date,
      exercises: workoutExercises,
      isCompleted:
          date.isBefore(DateTime.now()) &&
          DateTime.now().difference(date).inDays <
              7, // Mark recent past workouts as completed
      completedDate: date.isBefore(DateTime.now()) ? date : null,
    );
  }

  /// Generates sample sets for an exercise
  List<WorkoutSet> _generateSampleSets(Exercise exercise) {
    final isBodyweight =
        exercise.muscleGroups.contains('core') ||
        exercise.name.toLowerCase().contains('pull-up') ||
        exercise.name.toLowerCase().contains('dip');

    if (isBodyweight) {
      return [
        WorkoutSet(reps: 8, weight: 0, restTime: Duration(minutes: 1)),
        WorkoutSet(reps: 6, weight: 0, restTime: Duration(minutes: 1)),
        WorkoutSet(reps: 5, weight: 0, restTime: Duration(minutes: 1)),
      ];
    }

    // Generate realistic weights based on exercise type
    double baseWeight = 50.0;
    if (exercise.muscleGroups.contains('chest')) baseWeight = 80.0;
    if (exercise.muscleGroups.contains('back')) baseWeight = 70.0;
    if (exercise.muscleGroups.contains('quadriceps')) baseWeight = 100.0;
    if (exercise.muscleGroups.contains('shoulders')) baseWeight = 40.0;

    return [
      WorkoutSet(reps: 8, weight: baseWeight, restTime: Duration(minutes: 2)),
      WorkoutSet(
        reps: 6,
        weight: baseWeight + 10,
        restTime: Duration(minutes: 2),
      ),
      WorkoutSet(
        reps: 4,
        weight: baseWeight + 20,
        restTime: Duration(minutes: 2),
      ),
    ];
  }
}
