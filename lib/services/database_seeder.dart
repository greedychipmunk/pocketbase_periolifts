import '../models/exercise.dart';
import '../models/workout.dart';
import 'exercise_service.dart';
import 'workout_service.dart';

class DatabaseSeeder {
  final WorkoutService workoutService;
  final ExerciseService exerciseService;
  final String userId;

  DatabaseSeeder({
    required this.workoutService,
    required this.exerciseService,
    required this.userId,
  });

  /// Seeds all collections with test data
  Future<void> seedAll() async {
    print('🌱 Starting database seeding...');

    try {
      // Clear existing data first (optional)
      await clearAllData();

      // Seed in order: exercises first, then workouts
      final exercises = await seedExercises();
      print('✅ Seeded ${exercises.length} exercises');

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
        final result = await exerciseService.createExercise(exercise);
        if (result.isSuccess) {
          createdExercises.add(result.data!);
        } else {
          print(
            'Warning: Could not create exercise ${exercise.name}: ${result.error!.message}',
          );
        }
      } catch (e) {
        print('Warning: Could not create exercise ${exercise.name}: $e');
      }
    }

    return createdExercises;
  }

  /// Seeds the workouts collection
  Future<List<Workout>> seedWorkouts(List<Exercise> exercises) async {
    final workouts = _generateSampleWorkouts(exercises);
    final createdWorkouts = <Workout>[];

    for (final workout in workouts) {
      try {
        final result = await workoutService.createWorkout(workout);
        if (result.isSuccess) {
          createdWorkouts.add(result.data!);
        } else {
          print(
            'Warning: Could not create workout ${workout.name}: ${result.error!.message}',
          );
        }
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
      final workoutsResult = await workoutService.getWorkouts();
      if (workoutsResult.isSuccess) {
        for (final workout in workoutsResult.data!) {
          await workoutService.deleteWorkout(workout.id);
        }
      }

      // Clear exercises
      final exercisesResult = await exerciseService.getExercises();
      if (exercisesResult.isSuccess) {
        for (final exercise in exercisesResult.data!) {
          await exerciseService.deleteExercise(exercise.id);
        }
      }
    } catch (e) {
      print('Warning: Error clearing data: $e');
    }
  }

  /// Generates sample exercises
  List<Exercise> _generateSampleExercises() {
    final now = DateTime.now();
    return [
      Exercise(
        id: '',
        created: now,
        updated: now,
        name: 'Bench Press',
        category: 'strength',
        description: 'Lie on a bench and press weight up from chest level',
        muscleGroups: ['chest', 'shoulders', 'triceps'],
        videoUrl: 'https://example.com/bench-press',
        isCustom: false,
        userId: '',
      ),
      Exercise(
        id: '',
        created: now,
        updated: now,
        name: 'Squats',
        category: 'strength',
        description:
            'Stand with feet shoulder-width apart, lower body as if sitting',
        muscleGroups: ['quadriceps', 'glutes', 'hamstrings'],
        videoUrl: 'https://example.com/squats',
        isCustom: false,
        userId: '',
      ),
      Exercise(
        id: '',
        created: now,
        updated: now,
        name: 'Deadlift',
        category: 'strength',
        description: 'Lift weight from floor to hip level with straight back',
        muscleGroups: ['hamstrings', 'glutes', 'back', 'traps'],
        videoUrl: 'https://example.com/deadlift',
        isCustom: false,
        userId: '',
      ),
      Exercise(
        id: '',
        created: now,
        updated: now,
        name: 'Overhead Press',
        category: 'strength',
        description: 'Press weight overhead from shoulder level',
        muscleGroups: ['shoulders', 'triceps', 'core'],
        videoUrl: 'https://example.com/overhead-press',
        isCustom: false,
        userId: '',
      ),
      Exercise(
        id: '',
        created: now,
        updated: now,
        name: 'Pull-ups',
        category: 'strength',
        description: 'Pull body up until chin is above the bar',
        muscleGroups: ['lats', 'biceps', 'rhomboids'],
        videoUrl: 'https://example.com/pull-ups',
        isCustom: false,
        userId: '',
      ),
      Exercise(
        id: '',
        created: now,
        updated: now,
        name: 'Rows',
        category: 'strength',
        description: 'Pull weight towards torso from arms extended position',
        muscleGroups: ['lats', 'rhomboids', 'rear-delts', 'biceps'],
        videoUrl: 'https://example.com/rows',
        isCustom: false,
        userId: '',
      ),
      Exercise(
        id: '',
        created: now,
        updated: now,
        name: 'Dips',
        category: 'strength',
        description: 'Lower body by bending arms, then push back up',
        muscleGroups: ['triceps', 'chest', 'shoulders'],
        videoUrl: 'https://example.com/dips',
        isCustom: false,
        userId: '',
      ),
      Exercise(
        id: '',
        created: now,
        updated: now,
        name: 'Lunges',
        category: 'strength',
        description: 'Step forward into lunge position, alternate legs',
        muscleGroups: ['quadriceps', 'glutes', 'hamstrings'],
        videoUrl: 'https://example.com/lunges',
        isCustom: false,
        userId: '',
      ),
      Exercise(
        id: '',
        created: now,
        updated: now,
        name: 'Planks',
        category: 'core',
        description: 'Hold body in straight line from head to heels',
        muscleGroups: ['core', 'shoulders', 'glutes'],
        videoUrl: 'https://example.com/planks',
        isCustom: false,
        userId: '',
      ),
      Exercise(
        id: '',
        created: now,
        updated: now,
        name: 'Bicep Curls',
        category: 'strength',
        description: 'Curl weights up to shoulder level, focusing on biceps',
        muscleGroups: ['biceps'],
        videoUrl: 'https://example.com/bicep-curls',
        isCustom: false,
        userId: '',
      ),
    ];
  }

  /// Generates sample workouts
  List<Workout> _generateSampleWorkouts(List<Exercise> exercises) {
    final now = DateTime.now();
    final workouts = <Workout>[];

    // Create 3 basic workout templates
    if (exercises.isNotEmpty) {
      workouts.addAll([
        _createPushWorkout(exercises, now),
        _createPullWorkout(exercises, now),
        _createLegWorkout(exercises, now),
      ]);
    }

    return workouts;
  }

  /// Creates a push workout template
  Workout _createPushWorkout(List<Exercise> exercises, DateTime now) {
    final pushExercises = exercises
        .where(
          (e) => e.muscleGroups.any(
            (mg) => ['chest', 'shoulders', 'triceps'].contains(mg),
          ),
        )
        .take(4)
        .map(
          (exercise) => WorkoutExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: 3,
            reps: 10,
            weight: 50.0,
            restTime: 120, // 2 minutes
          ),
        )
        .toList();

    return Workout(
      id: '',
      created: now,
      updated: now,
      name: 'Push Day Workout',
      description: 'Focus on pushing movements - chest, shoulders, triceps',
      estimatedDuration: 60,
      exercises: pushExercises,
      userId: userId,
    );
  }

  /// Creates a pull workout template
  Workout _createPullWorkout(List<Exercise> exercises, DateTime now) {
    final pullExercises = exercises
        .where(
          (e) => e.muscleGroups.any(
            (mg) => ['lats', 'biceps', 'rhomboids', 'back'].contains(mg),
          ),
        )
        .take(4)
        .map(
          (exercise) => WorkoutExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: 3,
            reps: 10,
            weight: 40.0,
            restTime: 120, // 2 minutes
          ),
        )
        .toList();

    return Workout(
      id: '',
      created: now,
      updated: now,
      name: 'Pull Day Workout',
      description: 'Focus on pulling movements - back, biceps',
      estimatedDuration: 60,
      exercises: pullExercises,
      userId: userId,
    );
  }

  /// Creates a leg workout template
  Workout _createLegWorkout(List<Exercise> exercises, DateTime now) {
    final legExercises = exercises
        .where(
          (e) => e.muscleGroups.any(
            (mg) => ['quadriceps', 'glutes', 'hamstrings'].contains(mg),
          ),
        )
        .take(4)
        .map(
          (exercise) => WorkoutExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: 3,
            reps: 12,
            weight: 80.0,
            restTime: 180, // 3 minutes
          ),
        )
        .toList();

    return Workout(
      id: '',
      created: now,
      updated: now,
      name: 'Leg Day Workout',
      description: 'Focus on legs - quads, hamstrings, glutes',
      estimatedDuration: 75,
      exercises: legExercises,
      userId: userId,
    );
  }
}
