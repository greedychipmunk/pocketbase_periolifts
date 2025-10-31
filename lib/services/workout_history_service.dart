import 'package:pocketbase/pocketbase.dart';
import '../models/workout_history.dart';
import '../utils/result.dart';
import '../utils/error_handler.dart';
import 'base_pocketbase_service.dart';

/// Service for managing workout history and session data using PocketBase
///
/// Handles workout session management, progress tracking, and performance analytics.
/// All operations require user authentication and follow constitutional performance
/// requirements (<500ms operations).
class WorkoutHistoryService extends BasePocketBaseService {
  static const String _collectionName = 'workout_history';

  WorkoutHistoryService() : super();

  /// Get user's workout history with filtering and pagination
  ///
  /// Supports filtering by date range, status, exercise name, and workout name.
  /// Returns paginated results with constitutional performance requirements.
  ///
  /// Parameters:
  /// - [page]: Page number (must be > 0)
  /// - [perPage]: Items per page (1-100)
  /// - [startDate]: Filter entries after this date
  /// - [endDate]: Filter entries before this date
  /// - [status]: Filter by workout status
  /// - [exerciseName]: Filter by exercise name (partial match)
  /// - [workoutName]: Filter by workout name (partial match)
  Future<Result<List<WorkoutHistoryEntry>>> getWorkoutHistory({
    int page = 1,
    int perPage = 20,
    DateTime? startDate,
    DateTime? endDate,
    WorkoutHistoryStatus? status,
    String? exerciseName,
    String? workoutName,
  }) async {
    try {
      // Validate pagination parameters
      if (page < 1) {
        return Result.error(
          AppError.validation(message: 'Page number must be greater than 0'),
        );
      }
      if (perPage < 1 || perPage > 100) {
        return Result.error(
          AppError.validation(
            message: 'Items per page must be between 1 and 100',
          ),
        );
      }

      // Check authentication
      if (!pb.authStore.isValid) {
        return Result.error(
          AppError.authentication(
            message: 'Authentication required to access workout history',
          ),
        );
      }

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        return Result.error(
          AppError.authentication(message: 'User ID not available'),
        );
      }

      // Build filter query
      final filters = <String>['user_id = "$userId"'];

      // Date range filtering
      if (startDate != null) {
        filters.add('started_at >= "${startDate.toIso8601String()}"');
      }
      if (endDate != null) {
        filters.add('completed_at <= "${endDate.toIso8601String()}"');
      }

      // Status filtering
      if (status != null) {
        filters.add('status = "${status.name}"');
      }

      // Exercise name filtering (partial match)
      if (exerciseName != null && exerciseName.trim().isNotEmpty) {
        final sanitizedExerciseName = _sanitizeSearchQuery(exerciseName);
        filters.add('exercises ~ "$sanitizedExerciseName"');
      }

      // Workout name filtering (partial match)
      if (workoutName != null && workoutName.trim().isNotEmpty) {
        final sanitizedWorkoutName = _sanitizeSearchQuery(workoutName);
        filters.add('name ~ "$sanitizedWorkoutName"');
      }

      final filter = filters.join(' && ');

      final records = await pb
          .collection(_collectionName)
          .getList(
            page: page,
            perPage: perPage,
            filter: filter,
            sort: '-completed_at,-started_at,-created',
          );

      final entries = records.items
          .map((record) => WorkoutHistoryEntry.fromJson(record.toJson()))
          .toList();

      return Result.success(entries);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(message: 'Failed to fetch workout history: $e'),
      );
    }
  }

  /// Get a specific workout history entry by ID
  ///
  /// Returns the workout history entry if found and user has access.
  /// Enforces ownership validation for security.
  Future<Result<WorkoutHistoryEntry>> getWorkoutHistoryById(
    String historyId,
  ) async {
    try {
      // Validate input
      if (historyId.trim().isEmpty) {
        return Result.error(
          AppError.validation(message: 'History ID cannot be empty'),
        );
      }

      // Check authentication
      if (!pb.authStore.isValid) {
        return Result.error(
          AppError.authentication(
            message: 'Authentication required to access workout history',
          ),
        );
      }

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        return Result.error(
          AppError.authentication(message: 'User ID not available'),
        );
      }

      final record = await pb.collection(_collectionName).getOne(historyId);

      // Verify ownership after retrieving
      if (record.data['user_id'] != userId) {
        return Result.error(
          AppError.permission(
            message: 'You can only access your own workout history',
          ),
        );
      }

      final entry = WorkoutHistoryEntry.fromJson(record.toJson());
      return Result.success(entry);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(message: 'Failed to fetch workout history entry: $e'),
      );
    }
  }

  /// Create a new workout history entry
  ///
  /// Validates the entry data and creates a new workout session record.
  /// Automatically sets the user ID and creation timestamp.
  Future<Result<WorkoutHistoryEntry>> createWorkoutHistory(
    WorkoutHistoryEntry entry,
  ) async {
    try {
      // Check authentication
      if (!pb.authStore.isValid) {
        return Result.error(
          AppError.authentication(
            message: 'Authentication required to create workout history',
          ),
        );
      }

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        return Result.error(
          AppError.authentication(message: 'User ID not available'),
        );
      }

      // Validate entry data
      final validationResult = _validateWorkoutHistoryEntry(entry);
      if (validationResult.isError) {
        return Result.error(validationResult.error!);
      }

      // Prepare data for creation
      final entryData = entry.toJson();
      entryData['user_id'] = userId; // Ensure correct user association
      entryData.remove('id'); // Remove ID for creation

      final record = await pb
          .collection(_collectionName)
          .create(body: entryData);

      final createdEntry = WorkoutHistoryEntry.fromJson(record.toJson());
      return Result.success(createdEntry);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(message: 'Failed to create workout history: $e'),
      );
    }
  }

  /// Update an existing workout history entry
  ///
  /// Validates ownership and updates the workout session data.
  /// Only the owner can update their workout history entries.
  Future<Result<WorkoutHistoryEntry>> updateWorkoutHistory(
    String historyId,
    WorkoutHistoryEntry entry,
  ) async {
    try {
      // Validate input
      if (historyId.trim().isEmpty) {
        return Result.error(
          AppError.validation(message: 'History ID cannot be empty'),
        );
      }

      // Check authentication
      if (!pb.authStore.isValid) {
        return Result.error(
          AppError.authentication(
            message: 'Authentication required to update workout history',
          ),
        );
      }

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        return Result.error(
          AppError.authentication(message: 'User ID not available'),
        );
      }

      // Validate entry data
      final validationResult = _validateWorkoutHistoryEntry(entry);
      if (validationResult.isError) {
        return Result.error(validationResult.error!);
      }

      // Verify ownership before update
      final existingRecord = await pb
          .collection(_collectionName)
          .getOne(historyId);

      if (existingRecord.data['user_id'] != userId) {
        return Result.error(
          AppError.permission(
            message: 'You can only update your own workout history',
          ),
        );
      }

      // Prepare data for update
      final entryData = entry.toJson();
      entryData['user_id'] = userId; // Ensure user ID remains correct
      entryData.remove('id'); // Remove ID for update

      final record = await pb
          .collection(_collectionName)
          .update(historyId, body: entryData);

      final updatedEntry = WorkoutHistoryEntry.fromJson(record.toJson());
      return Result.success(updatedEntry);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(message: 'Failed to update workout history: $e'),
      );
    }
  }

  /// Delete a workout history entry
  ///
  /// Permanently removes the workout session data.
  /// Only the owner can delete their workout history entries.
  Future<Result<void>> deleteWorkoutHistory(String historyId) async {
    try {
      // Validate input
      if (historyId.trim().isEmpty) {
        return Result.error(
          AppError.validation(message: 'History ID cannot be empty'),
        );
      }

      // Check authentication
      if (!pb.authStore.isValid) {
        return Result.error(
          AppError.authentication(
            message: 'Authentication required to delete workout history',
          ),
        );
      }

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        return Result.error(
          AppError.authentication(message: 'User ID not available'),
        );
      }

      // Verify ownership before deletion
      final existingRecord = await pb
          .collection(_collectionName)
          .getOne(historyId);

      if (existingRecord.data['user_id'] != userId) {
        return Result.error(
          AppError.permission(
            message: 'You can only delete your own workout history',
          ),
        );
      }

      await pb.collection(_collectionName).delete(historyId);

      return Result.success(null);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(message: 'Failed to delete workout history: $e'),
      );
    }
  }

  /// Get user's workout statistics
  ///
  /// Returns aggregated statistics including completion rates, total workouts,
  /// and exercise progress data for analytics dashboard.
  Future<Result<WorkoutHistoryStats>> getUserWorkoutStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Check authentication
      if (!pb.authStore.isValid) {
        return Result.error(
          AppError.authentication(
            message: 'Authentication required to access workout statistics',
          ),
        );
      }

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        return Result.error(
          AppError.authentication(message: 'User ID not available'),
        );
      }

      // Build filter for statistics
      final filters = <String>['user_id = "$userId"'];

      // Date range filtering
      if (startDate != null) {
        filters.add('completed_at >= "${startDate.toIso8601String()}"');
      }
      if (endDate != null) {
        filters.add('completed_at <= "${endDate.toIso8601String()}"');
      }

      final filter = filters.join(' && ');

      // Get all workout history entries for statistics
      final records = await pb
          .collection(_collectionName)
          .getFullList(filter: filter, sort: '-completed_at');

      final entries = records
          .map((record) => WorkoutHistoryEntry.fromJson(record.toJson()))
          .toList();

      // Calculate statistics
      final stats = _calculateWorkoutStats(entries);
      return Result.success(stats);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(message: 'Failed to fetch workout statistics: $e'),
      );
    }
  }

  /// Get recent workout activities for dashboard
  ///
  /// Returns the most recent workout sessions for quick overview.
  /// Limited to recent activities for performance.
  Future<Result<List<WorkoutHistoryEntry>>> getRecentWorkouts({
    int limit = 10,
  }) async {
    try {
      // Validate input
      if (limit < 1 || limit > 50) {
        return Result.error(
          AppError.validation(message: 'Limit must be between 1 and 50'),
        );
      }

      // Check authentication
      if (!pb.authStore.isValid) {
        return Result.error(
          AppError.authentication(
            message: 'Authentication required to access recent workouts',
          ),
        );
      }

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        return Result.error(
          AppError.authentication(message: 'User ID not available'),
        );
      }

      final records = await pb
          .collection(_collectionName)
          .getList(
            page: 1,
            perPage: limit,
            filter: 'user_id = "$userId"',
            sort: '-completed_at,-started_at,-created',
          );

      final entries = records.items
          .map((record) => WorkoutHistoryEntry.fromJson(record.toJson()))
          .toList();

      return Result.success(entries);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(message: 'Failed to fetch recent workouts: $e'),
      );
    }
  }

  /// Private method to validate workout history entry data
  Result<void> _validateWorkoutHistoryEntry(WorkoutHistoryEntry entry) {
    // Validate workout name
    if (entry.name.trim().isEmpty) {
      return Result.error(
        AppError.validation(message: 'Workout name cannot be empty'),
      );
    }
    if (entry.name.length > 100) {
      return Result.error(
        AppError.validation(
          message: 'Workout name cannot exceed 100 characters',
        ),
      );
    }

    // Validate notes length
    if (entry.notes.length > 1000) {
      return Result.error(
        AppError.validation(message: 'Notes cannot exceed 1000 characters'),
      );
    }

    // Validate exercise data
    if (entry.exercises.isNotEmpty) {
      for (final exercise in entry.exercises) {
        final exerciseValidation = _validateWorkoutHistoryExercise(exercise);
        if (exerciseValidation.isError) {
          return exerciseValidation;
        }
      }
    }

    // Validate date logic
    if (entry.startedAt != null && entry.completedAt != null) {
      if (entry.completedAt!.isBefore(entry.startedAt!)) {
        return Result.error(
          AppError.validation(
            message: 'Completion time cannot be before start time',
          ),
        );
      }
    }

    // Validate scheduled date is not too far in the past
    if (entry.scheduledDate != null) {
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      if (entry.scheduledDate!.isBefore(oneYearAgo)) {
        return Result.error(
          AppError.validation(
            message: 'Scheduled date cannot be more than one year in the past',
          ),
        );
      }
    }

    return Result.success(null);
  }

  /// Private method to validate workout history exercise data
  Result<void> _validateWorkoutHistoryExercise(
    WorkoutHistoryExercise exercise,
  ) {
    // Validate exercise ID
    if (exercise.exerciseId.trim().isEmpty) {
      return Result.error(
        AppError.validation(message: 'Exercise ID cannot be empty'),
      );
    }

    // Validate exercise name
    if (exercise.exerciseName.trim().isEmpty) {
      return Result.error(
        AppError.validation(message: 'Exercise name cannot be empty'),
      );
    }

    // Validate sets data
    for (final set in exercise.sets) {
      if (set.reps < 0 || set.reps > 1000) {
        return Result.error(
          AppError.validation(message: 'Set reps must be between 0 and 1000'),
        );
      }
      if (set.weight < 0) {
        return Result.error(
          AppError.validation(message: 'Set weight cannot be negative'),
        );
      }
    }

    return Result.success(null);
  }

  /// Private method to sanitize search queries for PocketBase
  String _sanitizeSearchQuery(String query) {
    return query
        .replaceAll('"', '\\"')
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .trim();
  }

  /// Private method to calculate workout statistics from entries
  WorkoutHistoryStats _calculateWorkoutStats(
    List<WorkoutHistoryEntry> entries,
  ) {
    final userId = pb.authStore.model?.id?.toString() ?? '';
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final totalWorkouts = entries.length;
    final completedWorkouts = entries
        .where((e) => e.status == WorkoutHistoryStatus.completed)
        .length;

    final totalDuration = entries
        .where((e) => e.duration != null)
        .fold<Duration>(Duration.zero, (sum, e) => sum + e.duration!);

    final totalVolume = entries
        .where((e) => e.status == WorkoutHistoryStatus.completed)
        .fold<double>(0, (sum, e) => sum + e.totalWeightLifted);

    // Calculate exercise frequency (simplified)
    final exerciseFrequency = <String, int>{};
    final exerciseProgress = <ExerciseProgressData>[];

    for (final entry in entries) {
      if (entry.status == WorkoutHistoryStatus.completed) {
        for (final exercise in entry.exercises) {
          exerciseFrequency[exercise.exerciseName] =
              (exerciseFrequency[exercise.exerciseName] ?? 0) + 1;
        }
      }
    }

    return WorkoutHistoryStats(
      userId: userId,
      periodStart: startOfMonth,
      periodEnd: now,
      totalWorkouts: totalWorkouts,
      completedWorkouts: completedWorkouts,
      totalDuration: totalDuration,
      totalWeightLifted: totalVolume,
      exerciseFrequency: exerciseFrequency,
      exerciseProgress:
          exerciseProgress, // Could be calculated more extensively
    );
  }
}
