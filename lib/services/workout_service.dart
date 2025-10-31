import 'package:pocketbase/pocketbase.dart';
import '../models/workout.dart';
import '../utils/error_handler.dart';
import '../utils/result.dart';
import 'base_pocketbase_service.dart';

/// Service for handling workout template operations with PocketBase
///
/// Provides comprehensive workout template functionality including:
/// - CRUD operations for workout templates
/// - Retrieval of user's custom workout templates
/// - Workout template search and filtering
/// - WorkoutExercise relationship management
/// - User-specific workout template management
///
/// Performance Requirements:
/// - All operations must complete within 500ms
/// - Paginated results for optimal performance
/// - Efficient filtering and search
class WorkoutService extends BasePocketBaseService {
  static const String _collection = 'workouts';

  /// Get workout templates with optional filtering and pagination
  ///
  /// [searchQuery] Search in workout name and description (optional)
  /// [page] Page number (1-based, default: 1)
  /// [perPage] Items per page (default: 50, max: 100)
  /// [includeUserOnly] Include only current user's custom workouts when true
  ///
  /// Returns Result<List<Workout>> with workout templates or error state
  /// Performance: <500ms per operation
  Future<Result<List<Workout>>> getWorkouts({
    String? searchQuery,
    int page = 1,
    int perPage = 50,
    bool includeUserOnly = false,
  }) async {
    try {
      // Validate pagination parameters
      if (page < 1) {
        return Result.error(
          AppError.validation(
            message: 'Page number must be greater than 0',
            details: {'field': 'page', 'value': page},
          ),
        );
      }

      if (perPage < 1 || perPage > 100) {
        return Result.error(
          AppError.validation(
            message: 'Items per page must be between 1 and 100',
            details: {'field': 'perPage', 'value': perPage},
          ),
        );
      }

      // Build filter conditions
      final filters = <String>[];

      // Add user filter if requested
      if (includeUserOnly) {
        if (!isAuthenticated) {
          return Result.error(
            AppError.authentication(message: 'Authentication required'),
          );
        }
        filters.add(createUserFilter(userField: 'user_id'));
      }

      // Add search filter if provided
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final sanitizedQuery = _sanitizeSearchQuery(searchQuery.trim());
        filters.add(
          '(name ~ "${sanitizedQuery}" || description ~ "${sanitizedQuery}")',
        );
      }

      final records = await pb
          .collection(_collection)
          .getList(
            page: page,
            perPage: perPage,
            filter: filters.isNotEmpty ? filters.join(' && ') : null,
            sort: '-created',
          );

      final workouts = records.items.map<Workout>((RecordModel record) {
        return Workout.fromJson(record.toJson());
      }).toList();

      return Result.success(workouts);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Get a specific workout template by ID
  ///
  /// [id] Workout template ID to retrieve
  ///
  /// Returns Result<Workout> with workout template or error state
  /// Performance: <500ms per operation
  Future<Result<Workout>> getWorkoutById(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Workout ID cannot be empty',
            details: {'field': 'id'},
          ),
        );
      }

      final record = await pb.collection(_collection).getOne(id);
      final workout = Workout.fromJson(record.toJson());

      return Result.success(workout);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Create a new workout template
  ///
  /// [workout] Workout template data to create
  ///
  /// Returns Result<Workout> with created workout template or error state
  /// Performance: <500ms per operation
  Future<Result<Workout>> createWorkout(Workout workout) async {
    try {
      // Validate workout data
      final validation = _validateWorkout(workout);
      if (validation.isError) {
        return Result.error(validation.error!);
      }

      // Ensure user is authenticated
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'Authentication required'),
        );
      }

      // Set user_id for the workout
      final workoutData = workout.toJson();
      workoutData['user_id'] = currentUserId;

      final record = await pb.collection(_collection).create(body: workoutData);
      final createdWorkout = Workout.fromJson(record.toJson());

      return Result.success(createdWorkout);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Update an existing workout template
  ///
  /// [id] Workout template ID to update
  /// [workout] Updated workout template data
  ///
  /// Returns Result<Workout> with updated workout template or error state
  /// Performance: <500ms per operation
  Future<Result<Workout>> updateWorkout(String id, Workout workout) async {
    try {
      if (id.trim().isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Workout ID cannot be empty',
            details: {'field': 'id'},
          ),
        );
      }

      // Validate workout data
      final validation = _validateWorkout(workout);
      if (validation.isError) {
        return Result.error(validation.error!);
      }

      // Ensure user is authenticated
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'Authentication required'),
        );
      }

      // Check if workout exists and user owns it
      final existingResult = await getWorkoutById(id);
      if (existingResult.isError) {
        return Result.error(existingResult.error!);
      }

      final existingWorkout = existingResult.data!;
      if (existingWorkout.userId != currentUserId) {
        return Result.error(
          AppError.permission(
            message: 'Cannot update workout owned by another user',
          ),
        );
      }

      final record = await pb
          .collection(_collection)
          .update(id, body: workout.toJson());
      final updatedWorkout = Workout.fromJson(record.toJson());

      return Result.success(updatedWorkout);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Delete a workout template
  ///
  /// [id] Workout template ID to delete
  ///
  /// Returns Result<void> indicating success or error state
  /// Performance: <500ms per operation
  Future<Result<void>> deleteWorkout(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Workout ID cannot be empty',
            details: {'field': 'id'},
          ),
        );
      }

      // Ensure user is authenticated
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'Authentication required'),
        );
      }

      // Check if workout exists and user owns it
      final existingResult = await getWorkoutById(id);
      if (existingResult.isError) {
        return Result.error(existingResult.error!);
      }

      final existingWorkout = existingResult.data!;
      if (existingWorkout.userId != currentUserId) {
        return Result.error(
          AppError.permission(
            message: 'Cannot delete workout owned by another user',
          ),
        );
      }

      await pb.collection(_collection).delete(id);
      return Result.success(null);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Get workouts for the current user
  ///
  /// [page] Page number (1-based, default: 1)
  /// [perPage] Items per page (default: 50, max: 100)
  /// [searchQuery] Search in workout name and description (optional)
  ///
  /// Returns Result<List<Workout>> with user's workout templates or error state
  /// Performance: <500ms per operation
  Future<Result<List<Workout>>> getUserWorkouts({
    int page = 1,
    int perPage = 50,
    String? searchQuery,
  }) async {
    return getWorkouts(
      page: page,
      perPage: perPage,
      searchQuery: searchQuery,
      includeUserOnly: true,
    );
  }

  /// Get popular workout templates
  ///
  /// [limit] Maximum number of workouts to return (default: 10, max: 50)
  ///
  /// Returns Result<List<Workout>> with popular workout templates or error state
  /// Performance: <500ms per operation
  Future<Result<List<Workout>>> getPopularWorkouts({int limit = 10}) async {
    try {
      if (limit < 1 || limit > 50) {
        return Result.error(
          AppError.validation(
            message: 'Limit must be between 1 and 50',
            details: {'field': 'limit', 'value': limit},
          ),
        );
      }

      // For now, return recent workouts as a proxy for popular
      // In the future, this could be enhanced with usage statistics
      final records = await pb
          .collection(_collection)
          .getList(page: 1, perPage: limit, sort: '-created');

      final workouts = records.items.map<Workout>((RecordModel record) {
        return Workout.fromJson(record.toJson());
      }).toList();

      return Result.success(workouts);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Validate workout data before creation or update
  Result<void> _validateWorkout(Workout workout) {
    // Validate workout name
    if (workout.name.trim().isEmpty) {
      return Result.error(
        AppError.validation(
          message: 'Workout name cannot be empty',
          details: {'field': 'name'},
        ),
      );
    }

    if (workout.name.length > 100) {
      return Result.error(
        AppError.validation(
          message: 'Workout name cannot exceed 100 characters',
          details: {'field': 'name', 'maxLength': 100},
        ),
      );
    }

    // Validate description
    if (workout.description != null && workout.description!.length > 500) {
      return Result.error(
        AppError.validation(
          message: 'Workout description cannot exceed 500 characters',
          details: {'field': 'description', 'maxLength': 500},
        ),
      );
    }

    // Validate exercises
    if (workout.exercises.isEmpty) {
      return Result.error(
        AppError.validation(
          message: 'Workout must have at least one exercise',
          details: {'field': 'exercises'},
        ),
      );
    }

    if (workout.exercises.length > 20) {
      return Result.error(
        AppError.validation(
          message: 'Workout cannot have more than 20 exercises',
          details: {'field': 'exercises', 'maxCount': 20},
        ),
      );
    }

    // Validate each exercise
    for (int i = 0; i < workout.exercises.length; i++) {
      final exerciseValidation = _validateWorkoutExercise(
        workout.exercises[i],
        i,
      );
      if (exerciseValidation.isError) {
        return Result.error(exerciseValidation.error!);
      }
    }

    return Result.success(null);
  }

  /// Validate individual workout exercise data
  Result<void> _validateWorkoutExercise(WorkoutExercise exercise, int index) {
    // Validate exercise ID
    if (exercise.exerciseId.trim().isEmpty) {
      return Result.error(
        AppError.validation(
          message: 'Exercise ID cannot be empty',
          details: {'field': 'exercises[$index].exerciseId'},
        ),
      );
    }

    // Validate exercise name
    if (exercise.exerciseName.trim().isEmpty) {
      return Result.error(
        AppError.validation(
          message: 'Exercise name cannot be empty',
          details: {'field': 'exercises[$index].exerciseName'},
        ),
      );
    }

    // Validate sets count
    if (exercise.sets < 1 || exercise.sets > 20) {
      return Result.error(
        AppError.validation(
          message: 'Exercise must have between 1 and 20 sets',
          details: {'field': 'exercises[$index].sets', 'value': exercise.sets},
        ),
      );
    }

    // Validate reps count
    if (exercise.reps < 1 || exercise.reps > 100) {
      return Result.error(
        AppError.validation(
          message: 'Exercise reps must be between 1 and 100',
          details: {'field': 'exercises[$index].reps', 'value': exercise.reps},
        ),
      );
    }

    // Validate weight if provided
    if (exercise.weight != null && exercise.weight! < 0) {
      return Result.error(
        AppError.validation(
          message: 'Exercise weight cannot be negative',
          details: {'field': 'exercises[$index].weight'},
        ),
      );
    }

    // Validate rest time if provided
    if (exercise.restTime != null && exercise.restTime! < 0) {
      return Result.error(
        AppError.validation(
          message: 'Rest time cannot be negative',
          details: {'field': 'exercises[$index].restTime'},
        ),
      );
    }

    return Result.success(null);
  }

  /// Sanitize search query to prevent injection attacks
  String _sanitizeSearchQuery(String query) {
    // Remove special characters that could be used for injection
    return query.replaceAll(RegExp(r'["\\\r\n]'), '');
  }
}
