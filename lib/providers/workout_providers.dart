import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';

// Service provider
final workoutServiceProvider = Provider<WorkoutService>((ref) {
  return WorkoutService();
});

// Workout templates list provider with filtering and pagination
final workoutTemplatesProvider =
    StateNotifierProvider.family<
      WorkoutTemplatesNotifier,
      AsyncValue<List<Workout>>,
      WorkoutTemplatesFilter
    >((ref, filter) {
      final service = ref.watch(workoutServiceProvider);
      return WorkoutTemplatesNotifier(service, filter);
    });

class WorkoutTemplatesFilter {
  final String? searchQuery;
  final bool userOnly;
  final int page;
  final int perPage;

  const WorkoutTemplatesFilter({
    this.searchQuery,
    this.userOnly = true,
    this.page = 1,
    this.perPage = 50,
  });

  WorkoutTemplatesFilter copyWith({
    String? searchQuery,
    bool? userOnly,
    int? page,
    int? perPage,
  }) {
    return WorkoutTemplatesFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      userOnly: userOnly ?? this.userOnly,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutTemplatesFilter &&
        other.searchQuery == searchQuery &&
        other.userOnly == userOnly &&
        other.page == page &&
        other.perPage == perPage;
  }

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      userOnly.hashCode ^
      page.hashCode ^
      perPage.hashCode;
}

class WorkoutTemplatesNotifier
    extends StateNotifier<AsyncValue<List<Workout>>> {
  final WorkoutService _service;
  final WorkoutTemplatesFilter _filter;

  WorkoutTemplatesNotifier(this._service, this._filter)
    : super(const AsyncValue.loading()) {
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      final result = _filter.userOnly
          ? await _service.getUserWorkouts(
              page: _filter.page,
              perPage: _filter.perPage,
              searchQuery: _filter.searchQuery,
            )
          : await _service.getWorkouts(
              page: _filter.page,
              perPage: _filter.perPage,
              searchQuery: _filter.searchQuery,
              includeUserOnly: false,
            );

      if (result.isSuccess) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadWorkouts();
  }

  Future<void> createWorkout(Workout workout) async {
    try {
      final result = await _service.createWorkout(workout);
      if (result.isSuccess) {
        // Add the new workout to the current list
        state.whenData((workouts) {
          state = AsyncValue.data([...workouts, result.data!]);
        });
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateWorkout(String id, Workout workout) async {
    try {
      final result = await _service.updateWorkout(id, workout);
      if (result.isSuccess) {
        // Update the workout in the current list
        state.whenData((workouts) {
          final updatedWorkouts = workouts.map((w) {
            return w.id == id ? result.data! : w;
          }).toList();
          state = AsyncValue.data(updatedWorkouts);
        });
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteWorkout(String id) async {
    try {
      final result = await _service.deleteWorkout(id);
      if (result.isSuccess) {
        // Remove the workout from the current list
        state.whenData((workouts) {
          final filteredWorkouts = workouts.where((w) => w.id != id).toList();
          state = AsyncValue.data(filteredWorkouts);
        });
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Individual workout template provider
final workoutTemplateProvider =
    StateNotifierProvider.family<
      WorkoutTemplateNotifier,
      AsyncValue<Workout>,
      String
    >((ref, workoutId) {
      final service = ref.watch(workoutServiceProvider);
      return WorkoutTemplateNotifier(service, workoutId);
    });

class WorkoutTemplateNotifier extends StateNotifier<AsyncValue<Workout>> {
  final WorkoutService _service;
  final String _workoutId;

  WorkoutTemplateNotifier(this._service, this._workoutId)
    : super(const AsyncValue.loading()) {
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    try {
      final result = await _service.getWorkoutById(_workoutId);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadWorkout();
  }

  Future<void> updateWorkout(Workout workout) async {
    try {
      final result = await _service.updateWorkout(_workoutId, workout);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteWorkout() async {
    try {
      final result = await _service.deleteWorkout(_workoutId);
      if (result.isSuccess) {
        // Workout deleted successfully
        // Note: UI should handle navigation away from this screen
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// User workout templates provider (shortcut for user-only filter)
final userWorkoutTemplatesProvider =
    Provider<
      StateNotifierProvider<WorkoutTemplatesNotifier, AsyncValue<List<Workout>>>
    >((ref) {
      return workoutTemplatesProvider(
        const WorkoutTemplatesFilter(userOnly: true),
      );
    });

// Popular workout templates provider
final popularWorkoutTemplatesProvider = FutureProvider<List<Workout>>((
  ref,
) async {
  final service = ref.watch(workoutServiceProvider);
  final result = await service.getPopularWorkouts(limit: 20);
  if (result.isSuccess) {
    return result.data!;
  }
  throw result.error!;
});

// Workout template creation form state and provider
class WorkoutCreationFormState {
  final String name;
  final String? description;
  final int estimatedDuration;
  final List<WorkoutExercise> exercises;
  final bool isLoading;
  final String? error;

  const WorkoutCreationFormState({
    this.name = '',
    this.description,
    this.estimatedDuration = 60,
    this.exercises = const [],
    this.isLoading = false,
    this.error,
  });

  WorkoutCreationFormState copyWith({
    String? name,
    String? description,
    int? estimatedDuration,
    List<WorkoutExercise>? exercises,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutCreationFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isValid =>
      name.trim().isNotEmpty &&
      name.trim().length >= 2 &&
      name.trim().length <= 100 &&
      estimatedDuration > 0 &&
      estimatedDuration <= 480; // Max 8 hours

  Workout toWorkout(String userId) {
    final now = DateTime.now();
    return Workout(
      id: '', // Will be generated by the service
      created: now,
      updated: now,
      name: name.trim(),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      estimatedDuration: estimatedDuration,
      exercises: exercises,
      userId: userId,
    );
  }
}

class WorkoutCreationFormNotifier
    extends StateNotifier<WorkoutCreationFormState> {
  WorkoutCreationFormNotifier() : super(const WorkoutCreationFormState());

  void updateName(String name) {
    state = state.copyWith(name: name, error: null);
  }

  void updateDescription(String? description) {
    state = state.copyWith(description: description, error: null);
  }

  void updateEstimatedDuration(int duration) {
    state = state.copyWith(estimatedDuration: duration, error: null);
  }

  void addExercise(WorkoutExercise exercise) {
    final updatedExercises = [...state.exercises, exercise];
    state = state.copyWith(exercises: updatedExercises, error: null);
  }

  void updateExercise(int index, WorkoutExercise exercise) {
    if (index >= 0 && index < state.exercises.length) {
      final updatedExercises = [...state.exercises];
      updatedExercises[index] = exercise;
      state = state.copyWith(exercises: updatedExercises, error: null);
    }
  }

  void removeExercise(int index) {
    if (index >= 0 && index < state.exercises.length) {
      final updatedExercises = [...state.exercises];
      updatedExercises.removeAt(index);
      state = state.copyWith(exercises: updatedExercises, error: null);
    }
  }

  void reorderExercises(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final updatedExercises = [...state.exercises];
    final exercise = updatedExercises.removeAt(oldIndex);
    updatedExercises.insert(newIndex, exercise);
    state = state.copyWith(exercises: updatedExercises, error: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void reset() {
    state = const WorkoutCreationFormState();
  }

  void loadFromWorkout(Workout workout) {
    state = WorkoutCreationFormState(
      name: workout.name,
      description: workout.description,
      estimatedDuration: workout.estimatedDuration,
      exercises: [...workout.exercises],
      isLoading: false,
      error: null,
    );
  }
}

final workoutCreationFormProvider =
    StateNotifierProvider<
      WorkoutCreationFormNotifier,
      WorkoutCreationFormState
    >((ref) => WorkoutCreationFormNotifier());
