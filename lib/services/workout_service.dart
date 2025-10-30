import 'dart:typed_data';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => message;
}

class WorkoutService {
  final Databases databases;
  final Account account;
  final String databaseId;
  final String workoutsCollectionId;
  final String exercisesCollectionId;
  final String programsCollectionId;
  final Uuid _uuid = const Uuid();

  WorkoutService({
    required this.databases,
    required Client client,
    this.databaseId = '685884d800152b208c1a',
    this.workoutsCollectionId = '686072f4002040fc6b09',
    this.exercisesCollectionId = '68606f7100223566ddb8',
    this.programsCollectionId = 'workout-programs', // Programs collection ID
  }) : account = Account(client);

  // Programs
  Future<List<WorkoutPlan>> getPrograms() async {
    try {
      final currentUser = await account.get();
      print('Current user ID: ${currentUser.$id}');

      // First, try to get all documents to see the schema
      final allDocsResponse = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: programsCollectionId,
        queries: [Query.limit(5)], // Get first 5 documents to inspect
      );

      print('Sample documents from collection:');
      for (var doc in allDocsResponse.documents) {
        print('Document keys: ${doc.data.keys.toList()}');
        print('Document data: ${doc.data}');
        break; // Just print first document
      }

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: programsCollectionId,
        // queries: [Query.equal('userId', currentUser.$id)],
      );

      return response.documents
          .map((doc) => WorkoutPlan.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      // Don't treat database permission errors as authentication failures
      // Database permissions are separate from user authentication
      print('Error fetching workout plans: Database permission error - $e');
      // Return empty list instead of throwing auth exception
      return <WorkoutPlan>[];
    } catch (e) {
      // Don't print auth errors as they're expected during logout
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('401')) {
        return [];
      }
      print('Error fetching workout plans: $e');
      rethrow;
    }
  }

  // Backward compatibility alias
  Future<List<WorkoutPlan>> getWorkoutPlans() async => getPrograms();

  Future<WorkoutPlan> createProgram(WorkoutPlan plan) async {
    try {
      final document = await databases.createDocument(
        databaseId: databaseId,
        collectionId: programsCollectionId,
        documentId: ID.unique(),
        data: plan.toJson(),
      );

      return WorkoutPlan.fromJson(document.data);
    } catch (e) {
      print('Error creating workout plan: $e');
      rethrow;
    }
  }

  // Backward compatibility alias
  Future<WorkoutPlan> createWorkoutPlan(WorkoutPlan plan) async =>
      createProgram(plan);

  Future<void> updateProgram(WorkoutPlan plan) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: programsCollectionId,
        documentId: plan.id,
        data: plan.toJson(),
      );
    } catch (e) {
      print('Error updating workout plan: $e');
      rethrow;
    }
  }

  // Backward compatibility alias
  Future<void> updateWorkoutPlan(WorkoutPlan plan) async => updateProgram(plan);

  Future<void> deleteProgram(String planId) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: programsCollectionId,
        documentId: planId,
      );
    } catch (e) {
      print('Error deleting workout plan: $e');
      rethrow;
    }
  }

  // Backward compatibility alias
  Future<void> deleteWorkoutPlan(String planId) async => deleteProgram(planId);

  // Get the active program for the current user
  Future<WorkoutPlan?> getActiveProgram() async {
    try {
      final currentUser = await account.get();

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: programsCollectionId,
        queries: [Query.equal('isActive', true), Query.limit(1)],
      );

      if (response.documents.isEmpty) {
        return null;
      }

      return WorkoutPlan.fromJson(response.documents.first.data);
    } catch (e) {
      // Don't print auth errors as they're expected during logout
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('401')) {
        return null;
      }
      print('Error fetching active program: $e');
      return null;
    }
  }

  // Get next three workouts from the active program
  Future<List<Workout>> getNextThreeWorkouts() async {
    try {
      final activeProgram = await getActiveProgram();
      if (activeProgram == null) {
        return [];
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get real workout documents from past 7 days to present + next 30 days
      final realWorkouts = await getWorkouts(
        startDate: today.subtract(const Duration(days: 7)),
        endDate: today.add(const Duration(days: 30)),
      );

      List<Workout> prioritizedWorkouts = [];

      // Generate schedule from workoutDays if schedule is empty
      Map<String, List<String>> schedule = activeProgram.schedule;
      if (schedule.isEmpty) {
        schedule = await _generateScheduleFromWorkoutDays(activeProgram, today);
      }

      // First, check for incomplete workouts from today and previous days (up to 7 days back)
      for (int i = -7; i <= 0; i++) {
        if (prioritizedWorkouts.length >= 3) break;

        final checkDate = today.add(Duration(days: i));
        final dateKey = _formatDateKey(checkDate);

        if (schedule.containsKey(dateKey)) {
          final workoutIds = schedule[dateKey]!;

          for (String workoutId in workoutIds) {
            if (prioritizedWorkouts.length >= 3) break;

            // Check if we have a real workout document for this date
            Workout? existingWorkout;
            try {
              existingWorkout = realWorkouts.firstWhere(
                (w) =>
                    w.scheduledDate.year == checkDate.year &&
                    w.scheduledDate.month == checkDate.month &&
                    w.scheduledDate.day == checkDate.day &&
                    w.name == _generateWorkoutNameFromId(workoutId),
              );
            } catch (e) {
              existingWorkout = null;
            }

            // For past/today dates, only include if incomplete or if no real workout exists
            if (existingWorkout != null) {
              // If the workout exists and is completed, skip it
              if (existingWorkout.isCompleted) {
                continue;
              }
              // If it exists but is not completed, prioritize it
              prioritizedWorkouts.add(existingWorkout);
            } else {
              // No real workout exists for this scheduled date, so it's incomplete
              final workout = await _createWorkoutFromProgram(
                activeProgram,
                workoutId,
                checkDate,
              );
              prioritizedWorkouts.add(workout);
            }
          }
        }
      }

      // Then, add future scheduled workouts to fill up to 3 total
      for (int i = 1; i <= 30 && prioritizedWorkouts.length < 3; i++) {
        final checkDate = today.add(Duration(days: i));
        final dateKey = _formatDateKey(checkDate);

        if (schedule.containsKey(dateKey)) {
          final workoutIds = schedule[dateKey]!;

          for (String workoutId in workoutIds) {
            if (prioritizedWorkouts.length >= 3) break;

            // Check if we have a real workout document for this date
            Workout? existingWorkout;
            try {
              existingWorkout = realWorkouts.firstWhere(
                (w) =>
                    w.scheduledDate.year == checkDate.year &&
                    w.scheduledDate.month == checkDate.month &&
                    w.scheduledDate.day == checkDate.day &&
                    w.name == _generateWorkoutNameFromId(workoutId),
              );
            } catch (e) {
              existingWorkout = null;
            }

            // Use existing workout or create placeholder
            final workout =
                existingWorkout ??
                await _createWorkoutFromProgram(
                  activeProgram,
                  workoutId,
                  checkDate,
                );

            prioritizedWorkouts.add(workout);
          }
        }
      }

      // Sort by date but keep incomplete past/today workouts at the top
      prioritizedWorkouts.sort((a, b) {
        final aDate = DateTime(
          a.scheduledDate.year,
          a.scheduledDate.month,
          a.scheduledDate.day,
        );
        final bDate = DateTime(
          b.scheduledDate.year,
          b.scheduledDate.month,
          b.scheduledDate.day,
        );

        // If both are past/today and incomplete, sort by date (oldest first)
        if (aDate.isBefore(today.add(const Duration(days: 1))) &&
            bDate.isBefore(today.add(const Duration(days: 1)))) {
          return aDate.compareTo(bDate);
        }
        // If only a is past/today and incomplete, prioritize it
        if (aDate.isBefore(today.add(const Duration(days: 1)))) {
          return -1;
        }
        // If only b is past/today and incomplete, prioritize it
        if (bDate.isBefore(today.add(const Duration(days: 1)))) {
          return 1;
        }
        // Both are future, sort by date
        return aDate.compareTo(bDate);
      });

      return prioritizedWorkouts;
    } catch (e) {
      // Don't print auth errors as they're expected during logout
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('401')) {
        return [];
      }
      print('Error fetching next three workouts: $e');
      return [];
    }
  }

  // Get the date of the most recently completed workout
  Future<DateTime?> getLastCompletedWorkoutDate() async {
    try {
      final currentUser = await account.get();
      
      // Get completed workouts, ordered by completion date descending
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: workoutsCollectionId,
        queries: [
          Query.equal('userId', currentUser.$id),
          Query.equal('isCompleted', true),
          Query.isNotNull('completedDate'),
          Query.orderDesc('completedDate'),
          Query.limit(1), // Only need the most recent
        ],
      );

      if (response.documents.isNotEmpty) {
        final workout = Workout.fromJson(response.documents.first.data);
        return workout.completedDate;
      }
      return null;
    } catch (e) {
      // Don't print auth errors as they're expected during logout
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('401')) {
        return null;
      }
      print('Error fetching last completed workout date: $e');
      return null;
    }
  }

  // Helper method to generate workout names from workout ID patterns
  String _generateWorkoutNameFromId(String workoutId) {
    if (workoutId.startsWith('push-workout')) {
      return 'Push Day';
    } else if (workoutId.startsWith('pull-workout')) {
      return 'Pull Day';
    } else if (workoutId.startsWith('legs-workout')) {
      return 'Leg Day';
    } else if (workoutId.startsWith('upper-workout')) {
      return 'Upper Body';
    } else if (workoutId.startsWith('lower-workout')) {
      return 'Lower Body';
    } else if (workoutId.startsWith('fullbody-workout')) {
      return 'Full Body';
    } else {
      return 'Workout';
    }
  }

  // Helper method to generate realistic exercises for workout types
  List<WorkoutExercise> _generateExercisesForWorkoutType(String workoutId) {
    if (workoutId.startsWith('push-workout')) {
      return [
        WorkoutExercise(
          exerciseId: 'bench-press',
          exerciseName: 'Bench Press',
          sets: [
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 120)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'overhead-press',
          exerciseName: 'Overhead Press',
          sets: [
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 90)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 90)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 90)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'dips',
          exerciseName: 'Dips',
          sets: [
            WorkoutSet(reps: 10, weight: 0.0, restTime: Duration(seconds: 60)),
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 60)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 60)),
          ],
        ),
      ];
    } else if (workoutId.startsWith('pull-workout')) {
      return [
        WorkoutExercise(
          exerciseId: 'pull-ups',
          exerciseName: 'Pull-ups',
          sets: [
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 90)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 90)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 90)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'barbell-rows',
          exerciseName: 'Barbell Rows',
          sets: [
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 120)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'bicep-curls',
          exerciseName: 'Bicep Curls',
          sets: [
            WorkoutSet(reps: 12, weight: 0.0, restTime: Duration(seconds: 60)),
            WorkoutSet(reps: 10, weight: 0.0, restTime: Duration(seconds: 60)),
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 60)),
          ],
        ),
      ];
    } else if (workoutId.startsWith('legs-workout')) {
      return [
        WorkoutExercise(
          exerciseId: 'squats',
          exerciseName: 'Squats',
          sets: [
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 180)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 180)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 180)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'romanian-deadlifts',
          exerciseName: 'Romanian Deadlifts',
          sets: [
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 120)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'lunges',
          exerciseName: 'Lunges',
          sets: [
            WorkoutSet(reps: 12, weight: 0.0, restTime: Duration(seconds: 90)),
            WorkoutSet(reps: 10, weight: 0.0, restTime: Duration(seconds: 90)),
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 90)),
          ],
        ),
      ];
    } else if (workoutId.startsWith('upper-workout')) {
      return [
        WorkoutExercise(
          exerciseId: 'bench-press',
          exerciseName: 'Bench Press',
          sets: [
            WorkoutSet(reps: 5, weight: 0.0, restTime: Duration(seconds: 180)),
            WorkoutSet(reps: 3, weight: 0.0, restTime: Duration(seconds: 180)),
            WorkoutSet(reps: 1, weight: 0.0, restTime: Duration(seconds: 180)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'pull-ups',
          exerciseName: 'Pull-ups',
          sets: [
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 2, weight: 0.0, restTime: Duration(seconds: 120)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'overhead-press',
          exerciseName: 'Overhead Press',
          sets: [
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 2, weight: 0.0, restTime: Duration(seconds: 120)),
          ],
        ),
      ];
    } else if (workoutId.startsWith('lower-workout')) {
      return [
        WorkoutExercise(
          exerciseId: 'deadlifts',
          exerciseName: 'Deadlifts',
          sets: [
            WorkoutSet(reps: 5, weight: 0.0, restTime: Duration(seconds: 240)),
            WorkoutSet(reps: 3, weight: 0.0, restTime: Duration(seconds: 240)),
            WorkoutSet(reps: 1, weight: 0.0, restTime: Duration(seconds: 240)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'squats',
          exerciseName: 'Squats',
          sets: [
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 180)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 180)),
            WorkoutSet(reps: 2, weight: 0.0, restTime: Duration(seconds: 180)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'leg-curls',
          exerciseName: 'Leg Curls',
          sets: [
            WorkoutSet(reps: 12, weight: 0.0, restTime: Duration(seconds: 60)),
            WorkoutSet(reps: 10, weight: 0.0, restTime: Duration(seconds: 60)),
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 60)),
          ],
        ),
      ];
    } else if (workoutId.startsWith('fullbody-workout')) {
      return [
        WorkoutExercise(
          exerciseId: 'squats',
          exerciseName: 'Squats',
          sets: [
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 120)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'bench-press',
          exerciseName: 'Bench Press',
          sets: [
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 120)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 120)),
          ],
        ),
        WorkoutExercise(
          exerciseId: 'rows',
          exerciseName: 'Rows',
          sets: [
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 90)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 90)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 90)),
          ],
        ),
      ];
    } else {
      // Default fallback
      return [
        WorkoutExercise(
          exerciseId: 'compound-exercise',
          exerciseName: 'Compound Exercise',
          sets: [
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 90)),
            WorkoutSet(reps: 6, weight: 0.0, restTime: Duration(seconds: 90)),
            WorkoutSet(reps: 4, weight: 0.0, restTime: Duration(seconds: 90)),
          ],
        ),
      ];
    }
  }

  // Helper method to format date as string key
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Generate a schedule from workoutDays data by fetching the program data again
  Future<Map<String, List<String>>> _generateScheduleFromWorkoutDays(
    WorkoutPlan program,
    DateTime startDate,
  ) async {
    Map<String, List<String>> schedule = {};

    try {
      // Get the raw program data from the database to access workoutDays
      final response = await databases.getDocument(
        databaseId: databaseId,
        collectionId: programsCollectionId,
        documentId: program.id,
      );

      final rawData = response.data;
      final workoutDaysJson = rawData['workoutDays'] as String?;

      if (workoutDaysJson == null || workoutDaysJson.isEmpty) {
        return {};
      }

      List<dynamic> workoutDays = jsonDecode(workoutDaysJson);

      if (workoutDays.isEmpty) {
        return {};
      }

      // Create a repeating schedule starting from today
      final today = DateTime(startDate.year, startDate.month, startDate.day);

      // Schedule workouts for the next 4 weeks, cycling through the workout days
      for (int week = 0; week < 4; week++) {
        for (int dayIndex = 0; dayIndex < workoutDays.length; dayIndex++) {
          final workoutDay = workoutDays[dayIndex];
          final workoutDate = today.add(Duration(days: week * 7 + dayIndex));
          final dateKey = _formatDateKey(workoutDate);

          // Use the workout day ID as the workout ID
          final workoutId = workoutDay['id'] ?? 'workout-$dayIndex';
          schedule[dateKey] = [workoutId];
        }
      }

      return schedule;
    } catch (e) {
      print('Error generating schedule from workoutDays: $e');
      return {};
    }
  }

  // Create a workout from program data
  Future<Workout> _createWorkoutFromProgram(
    WorkoutPlan program,
    String workoutId,
    DateTime scheduledDate,
  ) async {
    try {
      // Get the raw program data from the database to access workoutDays
      final response = await databases.getDocument(
        databaseId: databaseId,
        collectionId: programsCollectionId,
        documentId: program.id,
      );

      final rawData = response.data;
      final workoutDaysJson = rawData['workoutDays'] as String?;

      List<dynamic> workoutDays = [];
      if (workoutDaysJson != null && workoutDaysJson.isNotEmpty) {
        workoutDays = jsonDecode(workoutDaysJson);
      }

      // Find the matching workout day
      Map<String, dynamic>? workoutDay;
      try {
        workoutDay = workoutDays.firstWhere((day) => day['id'] == workoutId);
      } catch (e) {
        workoutDay = null;
      }

      String workoutName =
          workoutDay?['name'] ?? _generateWorkoutNameFromId(workoutId);
      List<WorkoutExercise> exercises = [];

      // Convert exercises from the program format to WorkoutExercise format
      if (workoutDay != null && workoutDay['exercises'] is List) {
        exercises = (workoutDay['exercises'] as List).map((exerciseData) {
          return WorkoutExercise(
            exerciseId: exerciseData['id'] ?? exerciseData['name'],
            exerciseName: exerciseData['name'] ?? 'Exercise',
            sets: _createSetsFromExerciseData(exerciseData),
          );
        }).toList();
      } else {
        // Fallback to generated exercises
        exercises = _generateExercisesForWorkoutType(workoutId);
      }

      return Workout(
        id: _uuid.v4(), // Generate a UUID for the workout
        userId: program.userId,
        name: workoutName,
        description: 'Workout from ${program.name}',
        scheduledDate: scheduledDate,
        exercises: exercises,
      );
    } catch (e) {
      print('Error creating workout from program: $e');
      // Fallback to basic workout
      return Workout(
        id: _uuid.v4(), // Generate a UUID for the fallback workout
        userId: program.userId,
        name: _generateWorkoutNameFromId(workoutId),
        description: 'Workout from ${program.name}',
        scheduledDate: scheduledDate,
        exercises: _generateExercisesForWorkoutType(workoutId),
      );
    }
  }

  // Create sets from exercise data in the program
  List<WorkoutSet> _createSetsFromExerciseData(
    Map<String, dynamic> exerciseData,
  ) {
    try {
      int sets = exerciseData['sets'] ?? 3;
      String repsData = exerciseData['reps'] ?? '8-12';
      String restTime = exerciseData['restTime'] ?? '60 seconds';

      // Parse rest time
      Duration rest = Duration(seconds: 60);
      if (restTime.contains('seconds')) {
        int seconds =
            int.tryParse(restTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 60;
        rest = Duration(seconds: seconds);
      } else if (restTime.contains('minutes')) {
        int minutes =
            int.tryParse(restTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
        rest = Duration(minutes: minutes);
      }

      // Parse reps (handle ranges like "8-12")
      int targetReps = 8;
      if (repsData.contains('-')) {
        final parts = repsData.split('-');
        targetReps = int.tryParse(parts[0]) ?? 8;
      } else {
        targetReps =
            int.tryParse(repsData.replaceAll(RegExp(r'[^0-9]'), '')) ?? 8;
      }

      // Create the sets
      return List.generate(
        sets,
        (index) => WorkoutSet(reps: targetReps, weight: 0.0, restTime: rest),
      );
    } catch (e) {
      // Fallback to basic sets
      return List.generate(
        3,
        (index) =>
            WorkoutSet(reps: 8, weight: 0.0, restTime: Duration(seconds: 60)),
      );
    }
  }

  // Workouts
  Future<List<Workout>> getWorkouts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final currentUser = await account.get();
      List<String> queries = [];
      // Filter workouts by current user
      queries.add(Query.equal('userId', currentUser.$id));

      if (startDate != null) {
        queries.add(
          Query.greaterThanEqual('scheduledDate', startDate.toIso8601String()),
        );
      }
      if (endDate != null) {
        queries.add(
          Query.lessThanEqual('scheduledDate', endDate.toIso8601String()),
        );
      }

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: workoutsCollectionId,
        queries: queries,
      );

      return response.documents
          .map((doc) => Workout.fromJson(doc.data))
          .toList();
    } catch (e) {
      // Don't print auth errors as they're expected during logout
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('401')) {
        return [];
      }
      print('Error fetching workouts: $e');
      rethrow;
    }
  }

  Future<Workout> createWorkout(Workout workout) async {
    Workout? workoutWithUser; // Declare outside try block for error logging
    try {
      // Ensure the workout has the current user ID and a proper UUID
      final currentUser = await account.get();

      // Always generate a new UUID for workout IDs to ensure uniqueness
      final documentId = _uuid.v4();

      workoutWithUser = workout.copyWith(
        id: documentId,
        userId: currentUser.$id, // Always ensure current user ID is set
      );

      final data = workoutWithUser.toJson();

      final document = await databases.createDocument(
        databaseId: databaseId,
        collectionId: workoutsCollectionId,
        documentId: documentId, // Use the UUID for both document and data
        data: data,
      );

      return Workout.fromJson(document.data);
    } catch (e) {
      // Don't print auth errors as they're expected during logout
      if (e.toString().contains('user_unauthorized') ||
          e.toString().contains('401')) {
        rethrow;
      }
      print('Error creating workout: $e');
      if (workoutWithUser != null) {
        print('Workout data structure: ${workoutWithUser.toJson()}');
      } else {
        print('Original workout data: ${workout.toJson()}');
      }
      rethrow;
    }
  }

  Future<void> updateWorkout(Workout workout) async {
    final data = workout.toJson(); // Declare at function scope

    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: workoutsCollectionId,
        documentId: workout.id,
        data: data,
      );
    } catch (e) {
      print('Error updating workout: $e');
      print('Update data: $data');

      // If the error is about unknown attributes, try updating without the problematic fields
      if (e.toString().contains('Unknown attribute')) {
        print('Attempting to update without new attributes...');
        try {
          final basicData = {
            'id': workout.id,
            'userId': workout.userId,
            'name': workout.name,
            'description': workout.description,
            'scheduledDate': workout.scheduledDate.toIso8601String(),
            'exercises': workout.exercises.map((exercise) {
              final exerciseJson = jsonEncode(exercise.toJson());
              if (exerciseJson.length > 2048) {
                print('Warning: Exercise JSON too long, truncating...');
                return exerciseJson.substring(0, 2045) + '...';
              }
              return exerciseJson;
            }).toList(),
            'isCompleted': workout.isCompleted,
          };

          if (workout.completedDate != null) {
            basicData['completedDate'] = workout.completedDate!
                .toIso8601String();
          }

          await databases.updateDocument(
            databaseId: databaseId,
            collectionId: workoutsCollectionId,
            documentId: workout.id,
            data: basicData,
          );

          print('Updated workout with basic fields only');
        } catch (fallbackError) {
          print('Fallback update also failed: $fallbackError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: workoutsCollectionId,
        documentId: workoutId,
      );
    } catch (e) {
      print('Error deleting workout: $e');
      rethrow;
    }
  }

  Future<Workout?> getWorkout(String workoutId) async {
    try {
      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: workoutsCollectionId,
        documentId: workoutId,
      );
      return Workout.fromJson(document.data);
    } catch (e) {
      print('Error fetching workout: $e');
      return null;
    }
  }

  Future<WorkoutPlan> updateWorkoutPlanSchedule(
    String planId,
    Map<String, List<String>> schedule,
  ) async {
    try {
      final document = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: programsCollectionId,
        documentId: planId,
        data: {'schedule': schedule},
      );
      return WorkoutPlan.fromJson(document.data);
    } catch (e) {
      print('Error updating workout plan schedule: $e');
      rethrow;
    }
  }

  // Exercises
  Future<List<Exercise>> getExercises() async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: exercisesCollectionId,
      );

      return response.documents
          .map((doc) => Exercise.fromJson(doc.data))
          .toList();
    } catch (e) {
      print('Error fetching exercises: $e');
      rethrow;
    }
  }

  Future<Exercise> createExercise(Exercise exercise) async {
    try {
      final document = await databases.createDocument(
        databaseId: databaseId,
        collectionId: exercisesCollectionId,
        documentId: ID.unique(),
        data: exercise.toJson(),
      );

      return Exercise.fromJson(document.data);
    } catch (e) {
      print('Error creating exercise: $e');
      rethrow;
    }
  }

  Future<void> deleteExercise(String exerciseId) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: exercisesCollectionId,
        documentId: exerciseId,
      );
    } catch (e) {
      print('Error deleting exercise: $e');
      rethrow;
    }
  }
}