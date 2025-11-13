import 'package:pocketbase/pocketbase.dart';
import '../models/exercise.dart';
import '../utils/error_handler.dart';
import '../utils/result.dart';
import '../utils/validators.dart';
import 'base_pocketbase_service.dart';

/// Service for handling exercise operations with PocketBase
///
/// Provides comprehensive exercise functionality including:
/// - CRUD operations for custom exercises
/// - Retrieval of built-in and custom exercises
/// - Exercise search and filtering
/// - Category-based filtering
/// - User-specific exercise management
///
/// Performance Requirements:
/// - All operations must complete within 500ms
/// - Paginated results for optimal performance
/// - Efficient filtering and search
class ExerciseService extends BasePocketBaseService {
  static const String _collection = 'exercises';

  /// Get exercises with optional filtering and pagination
  ///
  /// [category] Filter by exercise category (optional)
  /// [isCustom] Filter by custom vs built-in exercises (optional)
  /// [muscleGroup] Filter by muscle group (optional)
  /// [searchQuery] Search in exercise name and description (optional)
  /// [page] Page number (1-based, default: 1)
  /// [perPage] Items per page (default: 50, max: 100)
  /// [includeUserOnly] Include only current user's custom exercises when true
  ///
  /// Returns Result<List<Exercise>> with exercises or error state
  /// Performance: <500ms per operation
  Future<Result<List<Exercise>>> getExercises({
    String? category,
    bool? isCustom,
    String? muscleGroup,
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

      // Build filter expressions
      final filters = <String>[];

      // Filter by category
      if (category != null && category.isNotEmpty) {
        filters.add('category = "$category"');
      }

      // Filter by muscle group
      if (muscleGroup != null && muscleGroup.isNotEmpty) {
        filters.add('muscle_groups ~ "$muscleGroup"');
      }

      // Filter by custom vs built-in
      if (isCustom != null) {
        if (isCustom) {
          // Show only custom exercises
          if (!isAuthenticated) {
            return Result.error(
              AppError.authentication(
                message: 'User must be authenticated to view custom exercises',
              ),
            );
          }
          filters.add(createUserFilter());
        } else {
          // Show only built-in exercises (no user_id)
          filters.add('user_id = ""');
        }
      } else if (includeUserOnly) {
        // Show only current user's custom exercises
        if (!isAuthenticated) {
          return Result.error(
            AppError.authentication(
              message:
                  'User must be authenticated to view user-specific exercises',
            ),
          );
        }
        filters.add(createUserFilter());
      }

      // Add search functionality
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final cleanQuery = searchQuery.trim();
        filters.add('(name ~ "$cleanQuery" || description ~ "$cleanQuery")');
      }

      // Combine filters
      final filterString = filters.isNotEmpty ? filters.join(' && ') : null;

      // Query parameters
      final params = getPaginationParams(
        page: page,
        perPage: perPage,
        filter: filterString,
        sort: 'name', // Always sort by name for consistency
      );

      // Execute query
      final response = await pb
          .collection(_collection)
          .getList(
            page: params['page'] as int,
            perPage: params['perPage'] as int,
            filter: params['filter'] as String?,
            sort: params['sort'] as String?,
          );

      // Convert records to Exercise models
      final exercises = response.items
          .map((record) => Exercise.fromJson(record.toJson()))
          .toList();

      return Result.success(exercises);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error retrieving exercises',
          details: {
            'originalError': e.toString(),
            'category': category,
            'isCustom': isCustom,
            'muscleGroup': muscleGroup,
            'searchQuery': searchQuery,
            'page': page,
            'perPage': perPage,
          },
        ),
      );
    }
  }

  // Batch load exercises to prevent N+1 queries
  Future<Result<Map<String, Exercise>>> getExercisesBatch(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return Result.success({});

    try {
      final filter = 'id in (${ids.map((id) => '"$id"').join(',')})';
      final result = await pb
          .collection('exercises')
          .getList(page: 1, perPage: ids.length, filter: filter);

      final exerciseMap = <String, Exercise>{};
      for (final record in result.items) {
        final exercise = Exercise.fromJson(record.toJson());
        exerciseMap[exercise.id] = exercise;
      }

      return Result.success(exerciseMap);
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Get a specific exercise by ID
  ///
  /// [exerciseId] The unique identifier of the exercise
  /// Returns Result<Exercise> with exercise data or error state
  /// Performance: <500ms per operation
  Future<Result<Exercise>> getExerciseById(String exerciseId) async {
    try {
      // Validate input
      if (exerciseId.isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Exercise ID cannot be empty',
            details: {'field': 'exerciseId'},
          ),
        );
      }

      // Retrieve exercise record
      final record = await pb.collection(_collection).getOne(exerciseId);

      // Convert to Exercise model
      final exercise = Exercise.fromJson(record.toJson());

      return Result.success(exercise);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error retrieving exercise',
          details: {'originalError': e.toString(), 'exerciseId': exerciseId},
        ),
      );
    }
  }

  /// Create a new custom exercise
  ///
  /// [exercise] Exercise data to create (without id, created, updated)
  /// Returns Result<Exercise> with created exercise data or error state
  /// Only authenticated users can create custom exercises
  /// Performance: <500ms per operation
  Future<Result<Exercise>> createExercise(Exercise exercise) async {
    try {
      // Validate authentication
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(
            message: 'User must be authenticated to create exercises',
          ),
        );
      }

      // Validate exercise data
      final validationResult = _validateExerciseData(exercise);
      if (validationResult.isError) {
        return Result.error((validationResult as Error).error);
      }

      // Prepare exercise data for creation
      final exerciseData = exercise.toJson();
      exerciseData['user_id'] = currentUserId; // Set current user as owner
      exerciseData['is_custom'] = true; // Mark as custom exercise

      // Remove PocketBase fields that should be auto-generated
      exerciseData.remove('id');
      exerciseData.remove('created');
      exerciseData.remove('updated');

      // Create exercise record
      final record = await pb
          .collection(_collection)
          .create(body: exerciseData);

      // Convert to Exercise model
      final createdExercise = Exercise.fromJson(record.toJson());

      return Result.success(createdExercise);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error creating exercise',
          details: {
            'originalError': e.toString(),
            'exerciseName': exercise.name,
          },
        ),
      );
    }
  }

  /// Update an existing custom exercise
  ///
  /// [exercise] Updated exercise data (must include valid id)
  /// Returns Result<Exercise> with updated exercise data or error state
  /// Only the owner can update their custom exercises
  /// Built-in exercises cannot be updated
  /// Performance: <500ms per operation
  Future<Result<Exercise>> updateExercise(Exercise exercise) async {
    try {
      // Validate authentication
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(
            message: 'User must be authenticated to update exercises',
          ),
        );
      }

      // Validate exercise ID
      if (exercise.id.isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Exercise ID is required for updates',
            details: {'field': 'id'},
          ),
        );
      }

      // Validate exercise data
      final validationResult = _validateExerciseData(exercise);
      if (validationResult.isError) {
        return Result.error((validationResult as Error).error);
      }

      // Check if exercise exists and is owned by current user
      final existingResult = await getExerciseById(exercise.id);
      if (existingResult.isError) {
        return Result.error((existingResult as Error).error);
      }

      final existingExercise = (existingResult as Success<Exercise>).data;

      // Verify ownership and custom status
      if (!existingExercise.isCustom) {
        return Result.error(
          AppError.permission(
            message: 'Built-in exercises cannot be updated',
            details: {'exerciseId': exercise.id},
          ),
        );
      }

      if (!existingExercise.belongsToUser(currentUserId)) {
        return Result.error(
          AppError.permission(
            message: 'You can only update your own custom exercises',
            details: {'exerciseId': exercise.id},
          ),
        );
      }

      // Prepare update data
      final updateData = exercise.toJson();
      updateData['user_id'] = currentUserId; // Ensure ownership is maintained
      updateData['is_custom'] = true; // Ensure custom status is maintained

      // Remove PocketBase fields that should not be updated manually
      updateData.remove('id');
      updateData.remove('created');
      updateData.remove('updated');

      // Update exercise record
      final record = await pb
          .collection(_collection)
          .update(exercise.id, body: updateData);

      // Convert to Exercise model
      final updatedExercise = Exercise.fromJson(record.toJson());

      return Result.success(updatedExercise);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error updating exercise',
          details: {
            'originalError': e.toString(),
            'exerciseId': exercise.id,
            'exerciseName': exercise.name,
          },
        ),
      );
    }
  }

  /// Delete a custom exercise
  ///
  /// [exerciseId] The ID of the exercise to delete
  /// Returns Result<void> indicating success or error state
  /// Only the owner can delete their custom exercises
  /// Built-in exercises cannot be deleted
  /// Performance: <500ms per operation
  Future<Result<void>> deleteExercise(String exerciseId) async {
    try {
      // Validate authentication
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(
            message: 'User must be authenticated to delete exercises',
          ),
        );
      }

      // Validate exercise ID
      if (exerciseId.isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Exercise ID cannot be empty',
            details: {'field': 'exerciseId'},
          ),
        );
      }

      // Check if exercise exists and is owned by current user
      final existingResult = await getExerciseById(exerciseId);
      if (existingResult.isError) {
        return Result.error((existingResult as Error).error);
      }

      final existingExercise = (existingResult as Success<Exercise>).data;

      // Verify ownership and custom status
      if (!existingExercise.isCustom) {
        return Result.error(
          AppError.permission(
            message: 'Built-in exercises cannot be deleted',
            details: {'exerciseId': exerciseId},
          ),
        );
      }

      if (!existingExercise.belongsToUser(currentUserId)) {
        return Result.error(
          AppError.permission(
            message: 'You can only delete your own custom exercises',
            details: {'exerciseId': exerciseId},
          ),
        );
      }

      // TODO: Check if exercise is used in any workouts before deletion
      // This would require querying workout collections for references
      // For now, we'll proceed with deletion and let referential integrity
      // be handled at the UI level

      // Delete exercise record
      await pb.collection(_collection).delete(exerciseId);

      return Result.success(null);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error deleting exercise',
          details: {'originalError': e.toString(), 'exerciseId': exerciseId},
        ),
      );
    }
  }

  /// Get exercises by category with built-in and custom exercises
  ///
  /// [category] The exercise category to filter by
  /// [page] Page number (1-based, default: 1)
  /// [perPage] Items per page (default: 50)
  ///
  /// Returns Result<List<Exercise>> with filtered exercises
  /// Includes both built-in and user's custom exercises
  /// Performance: <500ms per operation
  Future<Result<List<Exercise>>> getExercisesByCategory(
    String category, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Validate category
      if (category.isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Category cannot be empty',
            details: {'field': 'category'},
          ),
        );
      }

      // Get exercises filtered by category
      // This will include built-in exercises and user's custom exercises
      final filters = <String>['category = "$category"'];

      // Include built-in exercises (no user_id) and user's custom exercises
      if (isAuthenticated) {
        filters.add('(user_id = "" || user_id = "$currentUserId")');
      } else {
        filters.add(
          'user_id = ""',
        ); // Only built-in exercises for unauthenticated users
      }

      final filterString = filters.join(' && ');

      final params = getPaginationParams(
        page: page,
        perPage: perPage,
        filter: filterString,
        sort: 'name',
      );

      final resultList = await pb
          .collection('exercises')
          .getList(
            page: params['page'] as int,
            perPage: params['perPage'] as int,
            filter: params['filter'] as String?,
            sort: params['sort'] as String?,
          );

      final exercises = resultList.items
          .map((record) => Exercise.fromJson(record.toJson()))
          .toList();

      return Result.success(exercises);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error retrieving exercises by category',
          details: {
            'originalError': e.toString(),
            'category': category,
            'page': page,
            'perPage': perPage,
          },
        ),
      );
    }
  }

  /// Get exercises by muscle group
  ///
  /// [muscleGroup] The muscle group to filter by
  /// [page] Page number (1-based, default: 1)
  /// [perPage] Items per page (default: 50)
  ///
  /// Returns Result<List<Exercise>> with filtered exercises
  /// Searches within the muscle_groups array field
  /// Performance: <500ms per operation
  Future<Result<List<Exercise>>> getExercisesByMuscleGroup(
    String muscleGroup, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Validate muscle group
      if (muscleGroup.isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Muscle group cannot be empty',
            details: {'field': 'muscleGroup'},
          ),
        );
      }

      return await getExercises(
        muscleGroup: muscleGroup,
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error retrieving exercises by muscle group',
          details: {
            'originalError': e.toString(),
            'muscleGroup': muscleGroup,
            'page': page,
            'perPage': perPage,
          },
        ),
      );
    }
  }

  /// Search exercises by name or description
  ///
  /// [query] Search query string
  /// [page] Page number (1-based, default: 1)
  /// [perPage] Items per page (default: 50)
  ///
  /// Returns Result<List<Exercise>> with matching exercises
  /// Searches in exercise name and description fields
  /// Performance: <500ms per operation
  Future<Result<List<Exercise>>> searchExercises(
    String query, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Validate search query
      if (query.trim().isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Search query cannot be empty',
            details: {'field': 'query'},
          ),
        );
      }

      return await getExercises(
        searchQuery: query,
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error searching exercises',
          details: {
            'originalError': e.toString(),
            'query': query,
            'page': page,
            'perPage': perPage,
          },
        ),
      );
    }
  }

  /// Get all available exercise categories
  ///
  /// Returns Result<List<String>> with unique category names
  /// This is useful for populating category filters in the UI
  /// Performance: <500ms per operation
  Future<Result<List<String>>> getExerciseCategories() async {
    try {
      // Query all exercises and extract unique categories
      // Using a larger page size to get more comprehensive results
      final exercisesResult = await getExercises(perPage: 100);

      if (exercisesResult.isError) {
        return Result.error((exercisesResult as Error).error);
      }

      final exercises = (exercisesResult as Success<List<Exercise>>).data;

      // Extract unique categories
      final categories =
          exercises
              .map((exercise) => exercise.category)
              .where((category) => category.isNotEmpty)
              .toSet()
              .toList()
            ..sort(); // Sort alphabetically

      return Result.success(categories);
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error retrieving exercise categories',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Get all available muscle groups
  ///
  /// Returns Result<List<String>> with unique muscle group names
  /// This is useful for populating muscle group filters in the UI
  /// Performance: <500ms per operation
  Future<Result<List<String>>> getMuscleGroups() async {
    try {
      // Query all exercises and extract unique muscle groups
      final exercisesResult = await getExercises(perPage: 100);

      if (exercisesResult.isError) {
        return Result.error((exercisesResult as Error).error);
      }

      final exercises = (exercisesResult as Success<List<Exercise>>).data;

      // Extract unique muscle groups from all exercises
      final muscleGroups = <String>{};
      for (final exercise in exercises) {
        muscleGroups.addAll(exercise.muscleGroups);
      }

      // Convert to sorted list
      final sortedMuscleGroups = muscleGroups.toList()..sort();

      return Result.success(sortedMuscleGroups);
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error retrieving muscle groups',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }

  /// Private helper to validate exercise data
  ///
  /// [exercise] Exercise to validate
  /// Returns Result<void> indicating validation success or specific errors
  Result<void> _validateExerciseData(Exercise exercise) {
    // Validate name
    if (exercise.name.trim().isEmpty) {
      return Result.error(
        AppError.validation(
          message: 'Exercise name cannot be empty',
          details: {'field': 'name'},
        ),
      );
    }

    if (exercise.name.length > 100) {
      return Result.error(
        AppError.validation(
          message: 'Exercise name cannot exceed 100 characters',
          details: {
            'field': 'name',
            'maxLength': 100,
            'actualLength': exercise.name.length,
          },
        ),
      );
    }

    // Validate category
    if (exercise.category.trim().isEmpty) {
      return Result.error(
        AppError.validation(
          message: 'Exercise category cannot be empty',
          details: {'field': 'category'},
        ),
      );
    }

    // Validate muscle groups
    if (exercise.muscleGroups.isEmpty) {
      return Result.error(
        AppError.validation(
          message: 'At least one muscle group must be specified',
          details: {'field': 'muscleGroups'},
        ),
      );
    }

    // Validate description length if provided
    if (exercise.description.length > 1000) {
      return Result.error(
        AppError.validation(
          message: 'Exercise description is too long',
          details: {
            'field': 'description',
            'maxLength': 1000,
            'actualLength': exercise.description.length,
          },
        ),
      );
    }

    // Validate URLs if provided
    if (exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty) {
      if (!Validators.isValidUrl(exercise.imageUrl!)) {
        return Result.error(
          AppError.validation(
            message: 'Invalid image URL format',
            details: {'field': 'imageUrl', 'value': exercise.imageUrl},
          ),
        );
      }
    }

    if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty) {
      if (!Validators.isValidUrl(exercise.videoUrl!)) {
        return Result.error(
          AppError.validation(
            message: 'Invalid video URL format',
            details: {'field': 'videoUrl', 'value': exercise.videoUrl},
          ),
        );
      }
    }

    return Result.success(null);
  }
}
