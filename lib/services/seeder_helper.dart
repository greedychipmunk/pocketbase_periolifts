import 'package:appwrite/appwrite.dart';
import 'database_seeder.dart';
import 'workout_service.dart';

class SeederHelper {
  static Future<void> runSeeder() async {
    try {
      // Initialize Appwrite client
      final client = Client()
          .setEndpoint(
            'https://cloud.appwrite.io/v1',
          ) // Replace with your endpoint
          .setProject(
            '68571f9f001932310f27',
          ); // Your project ID from appwrite.json

      // Initialize services
      final workoutService = WorkoutService(
        databases: Databases(client),
        client: client,
      );

      // Get current user session
      final account = Account(client);
      final session = await account.getSession(sessionId: 'current');
      final userId = session.userId;

      print('🚀 Starting database seeding for user: $userId');

      // Initialize and run seeder
      final seeder = DatabaseSeeder(
        workoutService: workoutService,
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
      final client = Client()
          .setEndpoint('https://cloud.appwrite.io/v1')
          .setProject('68571f9f001932310f27');

      final workoutService = WorkoutService(
        databases: Databases(client),
        client: client,
      );

      final account = Account(client);
      final session = await account.getSession(sessionId: 'current');
      final userId = session.userId;

      final seeder = DatabaseSeeder(
        workoutService: workoutService,
        userId: userId,
      );

      print('🌱 Quick seeding (without clearing existing data)...');

      final exercises = await seeder.seedExercises();
      print('✅ Seeded ${exercises.length} exercises');

      final workoutPlans = await seeder.seedWorkoutPlans();
      print('✅ Seeded ${workoutPlans.length} workout plans');

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
      final client = Client()
          .setEndpoint('https://cloud.appwrite.io/v1')
          .setProject('68571f9f001932310f27');

      final workoutService = WorkoutService(
        databases: Databases(client),
        client: client,
      );

      final account = Account(client);
      final session = await account.getSession(sessionId: 'current');
      final userId = session.userId;

      final seeder = DatabaseSeeder(
        workoutService: workoutService,
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
      final client = Client()
          .setEndpoint('https://cloud.appwrite.io/v1')
          .setProject('68571f9f001932310f27');

      final workoutService = WorkoutService(
        databases: Databases(client),
        client: client,
      );

      final account = Account(client);
      final session = await account.getSession(sessionId: 'current');
      final userId = session.userId;

      final seeder = DatabaseSeeder(
        workoutService: workoutService,
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
