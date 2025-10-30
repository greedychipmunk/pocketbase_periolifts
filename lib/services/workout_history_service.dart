import 'dart:typed_data';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:collection/collection.dart';
import '../models/workout_history.dart';

class WorkoutHistoryService {
  final Databases databases;
  final Account account;
  final String databaseId;
  final String workoutHistoryCollectionId;
  final String workoutStatsCollectionId;

  WorkoutHistoryService({
    required this.databases,
    required Client client,
    this.databaseId = '685884d800152b208c1a',
    this.workoutHistoryCollectionId = 'workout-history', // New collection
    this.workoutStatsCollectionId = 'workout-stats', // New collection
  }) : account = Account(client);

  /// GET /workout-history/documents - Get user's workout history with filtering and pagination
  Future<List<WorkoutHistoryEntry>> getWorkoutHistory({
    DateTime? startDate,
    DateTime? endDate,
    WorkoutHistoryStatus? status,
    String? exerciseName,
    String? workoutName,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final currentUser = await account.get();
      List<String> queries = [];
      
      // Filter by current user
      queries.add(Query.equal('userId', currentUser.$id));
      
      // Date range filtering
      if (startDate != null) {
        queries.add(Query.greaterThanEqual('completedAt', startDate.toIso8601String()));
      }
      if (endDate != null) {
        queries.add(Query.lessThanEqual('completedAt', endDate.toIso8601String()));
      }
      
      // Status filtering
      if (status != null) {
        queries.add(Query.equal('status', status.name));
      }
      
      // Workout name search
      if (workoutName != null && workoutName.isNotEmpty) {
        queries.add(Query.search('name', workoutName));
      }
      
      // Pagination
      queries.add(Query.limit(limit));
      queries.add(Query.offset(offset));
      
      // Order by completion date descending (most recent first)
      queries.add(Query.orderDesc('completedAt'));

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: workoutHistoryCollectionId,
        queries: queries,
      );

      List<WorkoutHistoryEntry> entries = response.documents
          .map((doc) => WorkoutHistoryEntry.fromJson(doc.data))
          .toList();
          
      // Client-side exercise filtering if needed
      if (exerciseName != null && exerciseName.isNotEmpty) {
        entries = entries.where((entry) {
          return entry.exercises.any((exercise) =>
              exercise.exerciseName.toLowerCase().contains(exerciseName.toLowerCase()));
        }).toList();
      }

      return entries;
    } on AppwriteException catch (e) {
      if (e.code == 401 || (e.message?.contains('user_unauthorized') ?? false)) {
        return [];
      }
      print('Error fetching workout history: $e');
      rethrow;
    } catch (e) {
      if (e.toString().contains('user_unauthorized') || e.toString().contains('401')) {
        return [];
      }
      print('Error fetching workout history: $e');
      rethrow;
    }
  }

  /// POST /workout-history/documents - Create new workout history entry
  Future<WorkoutHistoryEntry> createWorkoutHistory(WorkoutHistoryEntry entry) async {
    try {
      final currentUser = await account.get();
      final entryWithUser = entry.copyWith(
        userId: currentUser.$id,
      );
      
      final data = entryWithUser.toJson();
      
      final document = await databases.createDocument(
        databaseId: databaseId,
        collectionId: workoutHistoryCollectionId,
        documentId: ID.unique(),
        data: data,
      );

      return WorkoutHistoryEntry.fromJson(document.data);
    } catch (e) {
      print('Error creating workout history: $e');
      rethrow;
    }
  }

  /// PUT /workout-history/documents/{historyId} - Update workout history
  Future<WorkoutHistoryEntry> updateWorkoutHistory(WorkoutHistoryEntry entry) async {
    try {
      final data = entry.toJson();
      
      final document = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: workoutHistoryCollectionId,
        documentId: entry.id,
        data: data,
      );

      return WorkoutHistoryEntry.fromJson(document.data);
    } catch (e) {
      print('Error updating workout history: $e');
      rethrow;
    }
  }

  /// GET /workout-history/documents/{historyId} - Get specific workout history entry
  Future<WorkoutHistoryEntry?> getWorkoutHistoryEntry(String historyId) async {
    try {
      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: workoutHistoryCollectionId,
        documentId: historyId,
      );
      
      return WorkoutHistoryEntry.fromJson(document.data);
    } catch (e) {
      print('Error fetching workout history entry: $e');
      return null;
    }
  }

  /// GET /workout-stats/documents - Get workout statistics for date range
  Future<WorkoutHistoryStats> getWorkoutStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final currentUser = await account.get();
      
      // Set default date range if not provided
      final now = DateTime.now();
      final effectiveStartDate = startDate ?? DateTime(now.year, now.month, 1);
      final effectiveEndDate = endDate ?? now;
      
      // Get workout history for the date range
      final workouts = await getWorkoutHistory(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
        limit: 1000, // Get all workouts in range for accurate stats
      );
      
      // Calculate statistics from workout history
      return _calculateStatsFromWorkouts(
        currentUser.$id,
        workouts,
        effectiveStartDate,
        effectiveEndDate,
      );
    } catch (e) {
      print('Error fetching workout stats: $e');
      rethrow;
    }
  }

  /// Calculate comprehensive statistics from workout history
  WorkoutHistoryStats _calculateStatsFromWorkouts(
    String userId,
    List<WorkoutHistoryEntry> workouts,
    DateTime startDate,
    DateTime endDate,
  ) {
    final completedWorkouts = workouts.where((w) => w.isCompleted).toList();
    
    // Calculate basic metrics
    final totalWorkouts = workouts.length;
    final completedCount = completedWorkouts.length;
    
    // Calculate total duration
    Duration totalDuration = Duration.zero;
    for (final workout in completedWorkouts) {
      if (workout.duration != null) {
        totalDuration += workout.duration!;
      }
    }
    
    // Calculate total weight lifted
    double totalWeightLifted = 0.0;
    for (final workout in completedWorkouts) {
      totalWeightLifted += workout.totalWeightLifted;
    }
    
    // Calculate exercise frequency
    Map<String, int> exerciseFrequency = {};
    List<ExerciseProgressData> exerciseProgress = [];
    Map<String, List<WorkoutHistoryExercise>> exerciseMap = {};
    
    // Group exercises by name for analysis
    for (final workout in completedWorkouts) {
      for (final exercise in workout.exercises) {
        exerciseFrequency[exercise.exerciseName] = 
            (exerciseFrequency[exercise.exerciseName] ?? 0) + 1;
            
        if (!exerciseMap.containsKey(exercise.exerciseName)) {
          exerciseMap[exercise.exerciseName] = [];
        }
        exerciseMap[exercise.exerciseName]!.add(exercise);
      }
    }
    
    // Calculate exercise progress data
    exerciseMap.forEach((exerciseName, exercises) {
      if (exercises.isNotEmpty) {
        final exerciseId = exercises.first.exerciseId;
        
        // Calculate max weight across all exercises
        double maxWeight = 0.0;
        double totalWeight = 0.0;
        int totalReps = 0;
        double totalVolume = 0.0;
        int completedSetsCount = 0;
        
        for (final exercise in exercises) {
          for (final set in exercise.sets) {
            if (set.completed) {
              maxWeight = set.weight > maxWeight ? set.weight : maxWeight;
              totalWeight += set.weight;
              totalReps += set.reps;
              totalVolume += set.volume;
              completedSetsCount++;
            }
          }
        }
        
        final avgWeight = completedSetsCount > 0 ? totalWeight / completedSetsCount : 0.0;
        
        exerciseProgress.add(ExerciseProgressData(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          maxWeight: maxWeight,
          avgWeight: avgWeight,
          totalReps: totalReps,
          totalVolume: totalVolume,
        ));
      }
    });
    
    // Sort exercise progress by total volume descending
    exerciseProgress.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
    
    return WorkoutHistoryStats(
      userId: userId,
      periodStart: startDate,
      periodEnd: endDate,
      totalWorkouts: totalWorkouts,
      completedWorkouts: completedCount,
      totalDuration: totalDuration,
      totalWeightLifted: totalWeightLifted,
      exerciseFrequency: exerciseFrequency,
      exerciseProgress: exerciseProgress,
    );
  }

  /// Delete a workout history entry
  Future<void> deleteWorkoutHistory(String historyId) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: workoutHistoryCollectionId,
        documentId: historyId,
      );
    } catch (e) {
      print('Error deleting workout history: $e');
      rethrow;
    }
  }

  /// Get recent workout history (last 10 workouts)
  Future<List<WorkoutHistoryEntry>> getRecentWorkoutHistory() async {
    return getWorkoutHistory(
      status: WorkoutHistoryStatus.completed,
      limit: 10,
      offset: 0,
    );
  }

  /// Get workout streaks and patterns
  Future<Map<String, dynamic>> getWorkoutPatterns({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final workouts = await getWorkoutHistory(
      startDate: startDate,
      endDate: endDate,
      status: WorkoutHistoryStatus.completed,
      limit: 365, // Get up to a year of data
    );
    
    // Calculate current streak
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    
    final now = DateTime.now();
    final sortedWorkouts = workouts
        .where((w) => w.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    
    // Calculate streaks based on consecutive days with workouts
    Set<String> workoutDates = {};
    for (final workout in sortedWorkouts) {
      if (workout.completedAt != null) {
        final dateKey = _formatDateKey(workout.completedAt!);
        workoutDates.add(dateKey);
      }
    }
    
    // Check for current streak
    DateTime checkDate = now;
    while (workoutDates.contains(_formatDateKey(checkDate))) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    // Calculate longest streak
    final sortedDates = workoutDates.toList()..sort();
    for (int i = 0; i < sortedDates.length; i++) {
      if (i == 0 || _isConsecutiveDay(sortedDates[i-1], sortedDates[i])) {
        tempStreak++;
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
      } else {
        tempStreak = 1;
      }
    }
    
    // Calculate weekly patterns
    Map<int, int> weeklyPattern = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (final workout in sortedWorkouts) {
      if (workout.completedAt != null) {
        final weekday = workout.completedAt!.weekday;
        weeklyPattern[weekday] = (weeklyPattern[weekday] ?? 0) + 1;
      }
    }
    
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'weeklyPattern': weeklyPattern,
      'totalWorkoutDays': workoutDates.length,
    };
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isConsecutiveDay(String date1, String date2) {
    final d1 = DateTime.parse(date1);
    final d2 = DateTime.parse(date2);
    return d2.difference(d1).inDays == 1;
  }
}