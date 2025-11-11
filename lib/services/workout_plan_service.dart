import 'package:pocketbase/pocketbase.dart';
import '../models/workout_plan.dart';
import '../utils/error_handler.dart';
import '../utils/result.dart';
import 'base_pocketbase_service.dart';

/// Service for handling workout plan operations with PocketBase
///
/// Provides comprehensive workout plan functionality including:
/// - CRUD operations for workout plans
/// - User-specific plan management
/// - Schedule management and date operations
/// - Plan activation and deactivation
/// - Search and filtering capabilities
///
/// Performance Requirements:
/// - All operations must complete within 500ms
/// - Paginated results for optimal performance
/// - Efficient filtering and search
class WorkoutPlanService extends BasePocketBaseService {
  static const String _collection = 'workout_plans';

  /// Get workout plans with optional filtering and pagination
  ///
  /// [searchQuery] Search in plan name and description (optional)
  /// [page] Page number (1-based, default: 1)
  /// [perPage] Items per page (default: 50, max: 100)
  /// [activeOnly] Include only active plans when true
  /// [userId] Filter by specific user ID (defaults to current user)
  ///
  /// Returns Result<List<WorkoutPlan>> with workout plans or error state
  /// Performance: <500ms per operation
  Future<Result<List<WorkoutPlan>>> getWorkoutPlans({
    String? searchQuery,
    int page = 1,
    int perPage = 50,
    bool activeOnly = false,
    String? userId,
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

      // Add user filter (default to current user)
      if (userId != null) {
        filters.add('user_id = "$userId"');
      } else if (isAuthenticated) {
        filters.add(createUserFilter(userField: 'user_id'));
      } else {
        return Result.error(
          AppError.authentication(message: 'Authentication required'),
        );
      }

      // Add active filter if requested
      if (activeOnly) {
        filters.add('is_active = true');
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

      final plans = records.items.map<WorkoutPlan>((RecordModel record) {
        return WorkoutPlan.fromJson(record.toJson());
      }).toList();

      return Result.success(plans);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Get a specific workout plan by ID
  ///
  /// [id] The workout plan ID to retrieve
  /// [checkOwnership] Whether to verify the plan belongs to current user
  ///
  /// Returns Result<WorkoutPlan> with the plan or error state
  Future<Result<WorkoutPlan>> getWorkoutPlan(
    String id, {
    bool checkOwnership = true,
  }) async {
    try {
      if (id.trim().isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Workout plan ID cannot be empty',
            details: {'field': 'id'},
          ),
        );
      }

      final record = await pb
          .collection(_collection)
          .getOne(id);

      final plan = WorkoutPlan.fromJson(record.toJson());

      // Verify ownership if required
      if (checkOwnership && isAuthenticated) {
        if (plan.userId != currentUserId) {
          return Result.error(
            AppError.permission(
              message: 'You do not have permission to access this workout plan',
              details: {'planId': id},
            ),
          );
        }
      }

      return Result.success(plan);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Create a new workout plan
  ///
  /// [plan] The workout plan to create (ID will be ignored)
  ///
  /// Returns Result<WorkoutPlan> with the created plan or error state
  Future<Result<WorkoutPlan>> createWorkoutPlan(WorkoutPlan plan) async {
    try {
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'Authentication required'),
        );
      }

      // Validate plan data
      final validationErrors = _validateWorkoutPlan(plan);
      if (validationErrors.isNotEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Workout plan validation failed',
            details: {'errors': validationErrors},
          ),
        );
      }

      // Prepare data for creation (exclude ID and timestamps)
      final planData = plan.toJson();
      planData.remove('id');
      planData.remove('created');
      planData.remove('updated');

      // Ensure user_id is set to current user
      planData['user_id'] = currentUserId;

      final record = await pb.collection(_collection).create(body: planData);
      final createdPlan = WorkoutPlan.fromJson(record.toJson());

      return Result.success(createdPlan);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Update an existing workout plan
  ///
  /// [plan] The workout plan with updated data
  /// [checkOwnership] Whether to verify the plan belongs to current user
  ///
  /// Returns Result<WorkoutPlan> with the updated plan or error state
  Future<Result<WorkoutPlan>> updateWorkoutPlan(
    WorkoutPlan plan, {
    bool checkOwnership = true,
  }) async {
    try {
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'Authentication required'),
        );
      }

      if (plan.id.trim().isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Workout plan ID cannot be empty',
            details: {'field': 'id'},
          ),
        );
      }

      // Validate plan data
      final validationErrors = _validateWorkoutPlan(plan);
      if (validationErrors.isNotEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Workout plan validation failed',
            details: {'errors': validationErrors},
          ),
        );
      }

      // Check ownership if required
      if (checkOwnership) {
        final existingResult = await getWorkoutPlan(plan.id);
        if (existingResult.isError) {
          return Result.error((existingResult as Error).error);
        }
      }

      // Prepare data for update (exclude ID and timestamps)
      final planData = plan.toJson();
      planData.remove('id');
      planData.remove('created');
      planData.remove('updated');

      final record = await pb
          .collection(_collection)
          .update(plan.id, body: planData);

      final updatedPlan = WorkoutPlan.fromJson(record.toJson());
      return Result.success(updatedPlan);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Delete a workout plan
  ///
  /// [id] The workout plan ID to delete
  /// [checkOwnership] Whether to verify the plan belongs to current user
  ///
  /// Returns Result<void> indicating success or error state
  Future<Result<void>> deleteWorkoutPlan(
    String id, {
    bool checkOwnership = true,
  }) async {
    try {
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'Authentication required'),
        );
      }

      if (id.trim().isEmpty) {
        return Result.error(
          AppError.validation(
            message: 'Workout plan ID cannot be empty',
            details: {'field': 'id'},
          ),
        );
      }

      // Check ownership if required
      if (checkOwnership) {
        final existingResult = await getWorkoutPlan(id);
        if (existingResult.isError) {
          return Result.error((existingResult as Error).error);
        }
      }

      await pb.collection(_collection).delete(id);
      return Result.success(null);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Get active workout plans for the current user
  ///
  /// Returns Result<List<WorkoutPlan>> with active plans or error state
  Future<Result<List<WorkoutPlan>>> getActivePlans() async {
    return getWorkoutPlans(activeOnly: true);
  }

  /// Check if user has active programs with future scheduled workouts
  ///
  /// Returns Result<bool> indicating if user has active programs with future workouts
  /// A user has active programs if they have at least one workout_plan with:
  /// - user_id matching the authenticated user
  /// - is_active = true
  /// - at least one workout scheduled for a future date
  Future<Result<bool>> hasActiveProgramsWithFutureWorkouts() async {
    try {
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'Authentication required'),
        );
      }

      // Get all active plans for the user
      final plansResult = await getActivePlans();
      if (plansResult.isError) {
        return Result.error((plansResult as Error).error);
      }

      final activePlans = (plansResult as Success<List<WorkoutPlan>>).data;

      // Check if any active plan has future workouts
      final today = DateTime.now();
      final todayString = _formatDateKey(today);

      for (final plan in activePlans) {
        // Check each scheduled date in the plan
        for (final dateString in plan.schedule.keys) {
          // Compare date strings to check if date is in the future
          if (dateString.compareTo(todayString) > 0) {
            // Found a future workout
            return Result.success(true);
          }
        }
      }

      // No active plans with future workouts found
      return Result.success(false);
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Format date as string key for schedule map (YYYY-MM-DD)
  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Get workout plans scheduled for a specific date
  ///
  /// [date] The date to check for scheduled workouts
  ///
  /// Returns Result<List<WorkoutPlan>> with plans that have workouts on the date
  Future<Result<List<WorkoutPlan>>> getPlansForDate(DateTime date) async {
    try {
      if (!isAuthenticated) {
        return Result.error(
          AppError.authentication(message: 'Authentication required'),
        );
      }

      // Get all active plans for the user
      final plansResult = await getActivePlans();
      if (plansResult.isError) {
        return Result.error((plansResult as Error).error);
      }

      final allPlans = (plansResult as Success<List<WorkoutPlan>>).data;

      // Filter plans that have workouts on the specified date
      final plansForDate = allPlans
          .where((WorkoutPlan plan) => plan.getWorkoutsForDate(date).isNotEmpty)
          .toList();

      return Result.success(plansForDate);
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Activate a workout plan
  ///
  /// [id] The workout plan ID to activate
  ///
  /// Returns Result<WorkoutPlan> with the activated plan or error state
  Future<Result<WorkoutPlan>> activatePlan(String id) async {
    try {
      final planResult = await getWorkoutPlan(id);
      if (planResult.isError) {
        return Result.error((planResult as Error).error);
      }

      final plan = (planResult as Success<WorkoutPlan>).data;
      final activatedPlan = plan.activate();

      return updateWorkoutPlan(activatedPlan);
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Deactivate a workout plan
  ///
  /// [id] The workout plan ID to deactivate
  ///
  /// Returns Result<WorkoutPlan> with the deactivated plan or error state
  Future<Result<WorkoutPlan>> deactivatePlan(String id) async {
    try {
      final planResult = await getWorkoutPlan(id);
      if (planResult.isError) {
        return Result.error((planResult as Error).error);
      }

      final plan = (planResult as Success<WorkoutPlan>).data;
      final deactivatedPlan = plan.deactivate();

      return updateWorkoutPlan(deactivatedPlan);
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Add a workout to a specific date in a plan
  ///
  /// [planId] The workout plan ID
  /// [date] The date to add the workout to
  /// [workoutId] The workout ID to add
  ///
  /// Returns Result<WorkoutPlan> with the updated plan or error state
  Future<Result<WorkoutPlan>> addWorkoutToDate(
    String planId,
    DateTime date,
    String workoutId,
  ) async {
    try {
      final planResult = await getWorkoutPlan(planId);
      if (planResult.isError) {
        return Result.error((planResult as Error).error);
      }

      final plan = (planResult as Success<WorkoutPlan>).data;
      final updatedPlan = plan.addWorkoutToDate(date, workoutId);

      return updateWorkoutPlan(updatedPlan);
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Remove a workout from a specific date in a plan
  ///
  /// [planId] The workout plan ID
  /// [date] The date to remove the workout from
  /// [workoutId] The workout ID to remove
  ///
  /// Returns Result<WorkoutPlan> with the updated plan or error state
  Future<Result<WorkoutPlan>> removeWorkoutFromDate(
    String planId,
    DateTime date,
    String workoutId,
  ) async {
    try {
      final planResult = await getWorkoutPlan(planId);
      if (planResult.isError) {
        return Result.error((planResult as Error).error);
      }

      final plan = (planResult as Success<WorkoutPlan>).data;
      final updatedPlan = plan.removeWorkoutFromDate(date, workoutId);

      return updateWorkoutPlan(updatedPlan);
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Get workout IDs scheduled for a specific date across all active plans
  ///
  /// [date] The date to check for scheduled workouts
  ///
  /// Returns Result<List<String>> with workout IDs or error state
  Future<Result<List<String>>> getWorkoutIdsForDate(DateTime date) async {
    try {
      final plansResult = await getPlansForDate(date);
      if (plansResult.isError) {
        return Result.error((plansResult as Error).error);
      }

      final plans = (plansResult as Success<List<WorkoutPlan>>).data;
      final workoutIds = <String>[];

      for (final plan in plans) {
        workoutIds.addAll(plan.getWorkoutsForDate(date));
      }

      // Remove duplicates
      final uniqueWorkoutIds = workoutIds.toSet().toList();
      return Result.success(uniqueWorkoutIds);
    } catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    }
  }

  /// Private helper to sanitize search queries
  String _sanitizeSearchQuery(String query) {
    // Remove special characters that could interfere with PocketBase filters
    return query.replaceAll(RegExp(r'["\\\n\r\t]'), '');
  }

  /// Private helper to validate workout plan data
  List<String> _validateWorkoutPlan(WorkoutPlan plan) {
    final errors = <String>[];

    // Validate required fields
    if (plan.name.trim().isEmpty) {
      errors.add('Plan name cannot be empty');
    } else if (plan.name.trim().length < 2) {
      errors.add('Plan name must be at least 2 characters long');
    } else if (plan.name.trim().length > 100) {
      errors.add('Plan name cannot exceed 100 characters');
    }

    if (plan.description.length > 1000) {
      errors.add('Plan description cannot exceed 1000 characters');
    }

    if (plan.userId.trim().isEmpty) {
      errors.add('User ID cannot be empty');
    }

    // Validate start date is not too far in the past
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    if (plan.startDate.isBefore(oneYearAgo)) {
      errors.add('Start date cannot be more than one year in the past');
    }

    // Validate schedule format
    for (final entry in plan.schedule.entries) {
      // Validate date format
      if (DateTime.tryParse(entry.key) == null) {
        errors.add('Invalid date format in schedule: ${entry.key}');
      }

      // Validate workout IDs are not empty
      for (final workoutId in entry.value) {
        if (workoutId.trim().isEmpty) {
          errors.add(
            'Empty workout ID found in schedule for date: ${entry.key}',
          );
        }
      }
    }

    return errors;
  }
}
