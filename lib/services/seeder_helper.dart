import 'database_seeder.dart';
import 'exercise_service.dart';
import 'workout_service.dart';

class SeederHelper {
  static Future<void> runSeeder() async {
    try {
      // Initialize services
      final workoutService = WorkoutService();
      final exerciseService = ExerciseService();

      // Use a placeholder user ID - in a real app this would come from authentication
      const userId = 'seeder-user-id';

      print('🚀 Starting database seeding for user: $userId');

      // Initialize and run seeder
      final seeder = DatabaseSeeder(
        workoutService: workoutService,
        exerciseService: exerciseService,
        userId: userId,
      );

      await seeder.seedAll();

      print('✅ Database seeding completed successfully!');
    } catch (e) {
      print('❌ Error running seeder: $e');
      rethrow;
    }
  }

  /// Quick seed without clearing existing data
  static Future<void> quickSeed() async {
    try {
      final workoutService = WorkoutService();
      final exerciseService = ExerciseService();
      const userId = 'seeder-user-id';

      final seeder = DatabaseSeeder(
        workoutService: workoutService,
        exerciseService: exerciseService,
        userId: userId,
      );

      print('🌱 Quick seeding (without clearing existing data)...');

      final exercises = await seeder.seedExercises();
      print('✅ Seeded ${exercises.length} exercises');

      final workouts = await seeder.seedWorkouts(exercises);
      print('✅ Seeded ${workouts.length} workouts');

      print('🎉 Quick seeding completed!');
    } catch (e) {
      print('❌ Error in quick seed: $e');
      rethrow;
    }
  }

  /// Seed only exercises
  static Future<void> seedExercisesOnly() async {
    try {
      final exerciseService = ExerciseService();
      const userId = 'seeder-user-id';

      final seeder = DatabaseSeeder(
        workoutService: WorkoutService(),
        exerciseService: exerciseService,
        userId: userId,
      );

      final exercises = await seeder.seedExercises();
      print('✅ Seeded ${exercises.length} exercises only');
    } catch (e) {
      print('❌ Error seeding exercises: $e');
      rethrow;
    }
  }

  /// Clear all data only
  static Future<void> clearAllData() async {
    try {
      final workoutService = WorkoutService();
      final exerciseService = ExerciseService();
      const userId = 'seeder-user-id';

      final seeder = DatabaseSeeder(
        workoutService: workoutService,
        exerciseService: exerciseService,
        userId: userId,
      );

      await seeder.clearAllData();
      print('🧹 All data cleared successfully');
    } catch (e) {
      print('❌ Error clearing data: $e');
      rethrow;
    }
  }
}
