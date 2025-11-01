import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../models/workout_history.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../services/workout_history_service.dart';
import '../state/workout_tracking_state.dart';
import '../utils/workout_converter.dart';

/// Parameters for the enhanced workout tracking provider
class EnhancedWorkoutTrackingParams {
  final Workout workout;
  final WorkoutService workoutService;
  final WorkoutHistoryService workoutHistoryService;
  final AuthService authService;
  final VoidCallback onAuthError;

  EnhancedWorkoutTrackingParams({
    required this.workout,
    required this.workoutService,
    required this.workoutHistoryService,
    required this.authService,
    required this.onAuthError,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnhancedWorkoutTrackingParams &&
        other.workout.id == workout.id;
  }

  @override
  int get hashCode => workout.id.hashCode;
}

/// Enhanced workout tracking provider that saves to workout history
final enhancedWorkoutTrackingProvider =
    StateNotifierProvider.family<
      EnhancedWorkoutTrackingNotifier,
      AsyncValue<WorkoutTrackingState>,
      EnhancedWorkoutTrackingParams
    >((ref, params) {
      return EnhancedWorkoutTrackingNotifier(
        params.workout,
        params.workoutHistoryService,
      );
    });

/// Enhanced workout tracking notifier with history saving capabilities
class EnhancedWorkoutTrackingNotifier
    extends StateNotifier<AsyncValue<WorkoutTrackingState>> {
  final Workout _originalWorkout;
  final WorkoutHistoryService _workoutHistoryService;

  // Track workout timing
  DateTime? _workoutStartTime;
  DateTime? _workoutEndTime;

  // Internal state for workout tracking
  late WorkoutTrackingState _currentState;

  EnhancedWorkoutTrackingNotifier(
    this._originalWorkout,
    this._workoutHistoryService,
  ) : super(const AsyncValue.loading()) {
    _initializeWorkout();
  }

  void _initializeWorkout() {
    try {
      _workoutStartTime = DateTime.now();

      // Initialize with first exercise selected and exercise selection view
      final initialCompletedSets = _originalWorkout.exercises
          .map((exercise) => List<bool>.filled(exercise.sets.length, false))
          .toList();

      final initialModifiedSets = _originalWorkout.exercises
          .map(
            (exercise) => exercise.sets.map((set) => WorkoutSet(
              reps: set.reps,
              weight: set.weight,
              restTime: set.restTime,
            )).toList(),
          )
          .toList();

      _currentState = WorkoutTrackingState(
        workout: _originalWorkout,
        currentView: WorkoutView.exerciseSelection,
        currentExerciseIndex: 0,
        currentSetIndex: 0,
        selectedSetIndex: 0,
        completedSets: initialCompletedSets,
        modifiedSets: initialModifiedSets,
        isLoading: false,
        isWorkoutCompleted: false,
        error: null,
        exerciseStatuses: List.filled(
          _originalWorkout.exercises.length,
          ExerciseStatus.notStarted,
        ),
      );

      state = AsyncValue.data(_currentState);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Get current workout duration
  Duration get workoutDuration {
    if (_workoutStartTime == null) return Duration.zero;
    final endTime = _workoutEndTime ?? DateTime.now();
    return endTime.difference(_workoutStartTime!);
  }

  // Select exercise and switch to tracking view
  void selectExercise(int exerciseIndex) {
    state.whenData((currentState) {
      final nextSetIndex = _findNextIncompleteSet(exerciseIndex);

      _currentState = currentState.copyWith(
        currentView: WorkoutView.exerciseTracking,
        currentExerciseIndex: exerciseIndex,
        currentSetIndex: nextSetIndex,
        selectedSetIndex: nextSetIndex,
      );
      state = AsyncValue.data(_currentState);

      // If this is the first set of the exercise (no completed sets), prefill from history
      final hasCompletedSets = currentState.completedSets[exerciseIndex].any(
        (completed) => completed,
      );
      if (!hasCompletedSets && nextSetIndex == 0) {
        // Run prefill asynchronously without blocking the UI
        _prefillNextSet(exerciseIndex, nextSetIndex, null).then((_) {
          state = AsyncValue.data(_currentState);
        });
      }
    });
  }

  // Return to exercise selection view
  void returnToExerciseSelection() {
    state.whenData((currentState) {
      _currentState = currentState.copyWith(
        currentView: WorkoutView.exerciseSelection,
      );
      state = AsyncValue.data(_currentState);
    });
  }

  // Select a specific set
  void selectSet(int setIndex) {
    state.whenData((currentState) {
      _currentState = currentState.copyWith(selectedSetIndex: setIndex);
      state = AsyncValue.data(_currentState);
    });
  }

  // Handle page changes in exercise tracking
  void onPageChanged(int exerciseIndex) {
    state.whenData((currentState) {
      final nextSetIndex = _findNextIncompleteSet(exerciseIndex);

      _currentState = currentState.copyWith(
        currentExerciseIndex: exerciseIndex,
        currentSetIndex: nextSetIndex,
        selectedSetIndex: nextSetIndex,
      );
      state = AsyncValue.data(_currentState);

      // If this is the first set of the exercise (no completed sets), prefill from history
      final hasCompletedSets = currentState.completedSets[exerciseIndex].any(
        (completed) => completed,
      );
      if (!hasCompletedSets && nextSetIndex == 0) {
        // Run prefill asynchronously without blocking the UI
        _prefillNextSet(exerciseIndex, nextSetIndex, null).then((_) {
          state = AsyncValue.data(_currentState);
        });
      }
    });
  }

  // Complete current set and save progress
  Future<void> completeSet() async {
    await state.when(
      data: (currentState) async {
        try {
          final exerciseIndex = currentState.currentExerciseIndex;
          final setIndex = currentState.currentSetIndex;

          // Mark set as completed
          final newCompletedSets = List<List<bool>>.from(
            _currentState.completedSets,
          );
          newCompletedSets[exerciseIndex][setIndex] = true;

          // Move to next incomplete set
          final nextSetIndex = _findNextIncompleteSetAfter(
            exerciseIndex,
            setIndex,
            newCompletedSets,
          );

          _currentState = _currentState.copyWith(
            completedSets: newCompletedSets,
            currentSetIndex: nextSetIndex,
            selectedSetIndex: nextSetIndex,
          );

          state = AsyncValue.data(_currentState);

          // Prefill the next set if it's different from current (meaning there is a next set)
          if (nextSetIndex != setIndex) {
            await _prefillNextSet(exerciseIndex, nextSetIndex, setIndex);
            // Update state after prefilling
            state = AsyncValue.data(_currentState);
          }

          // Auto-save progress to history (as in-progress workout)
          await _saveProgressToHistory();
        } catch (e) {
          _currentState = _currentState.copyWith(
            error: 'Failed to complete set: $e',
          );
          state = AsyncValue.data(_currentState);
        }
      },
      loading: () async {},
      error: (error, stackTrace) async {},
    );
  }

  // Complete entire workout and save to history
  Future<void> completeWorkout({bool allowEarlyCompletion = false}) async {
    await state.when(
      data: (currentState) async {
        try {
          _workoutEndTime = DateTime.now();

          _currentState = currentState.copyWith(
            isWorkoutCompleted: true,
            isLoading: true,
          );
          state = AsyncValue.data(_currentState);

          // Save completed workout to history
          await _saveCompletedWorkoutToHistory();

          _currentState = _currentState.copyWith(isLoading: false);
          state = AsyncValue.data(_currentState);
        } catch (e) {
          _currentState = currentState.copyWith(
            error: 'Failed to save workout: $e',
            isLoading: false,
          );
          state = AsyncValue.data(_currentState);
          rethrow;
        }
      },
      loading: () async {},
      error: (error, stackTrace) async {},
    );
  }

  // Update weight for a specific set
  void updateWeightForSet(
    String weightStr,
    int setIndex, {
    int? exerciseIndex,
  }) {
    state.whenData((currentState) {
      final targetExerciseIndex =
          exerciseIndex ?? currentState.currentExerciseIndex;
      final weight = double.tryParse(weightStr) ?? 0.0;

      final newModifiedSets = List<List<WorkoutSet>>.from(
        _currentState.modifiedSets,
      );
      newModifiedSets[targetExerciseIndex][setIndex] =
          newModifiedSets[targetExerciseIndex][setIndex].copyWith(
            weight: weight,
          );

      _currentState = _currentState.copyWith(modifiedSets: newModifiedSets);
      state = AsyncValue.data(_currentState);
    });
  }

  // Update reps for a specific set
  void updateRepsForSet(String repsStr, int setIndex, {int? exerciseIndex}) {
    state.whenData((currentState) {
      final targetExerciseIndex =
          exerciseIndex ?? currentState.currentExerciseIndex;
      final reps = int.tryParse(repsStr) ?? 0;

      final newModifiedSets = List<List<WorkoutSet>>.from(
        _currentState.modifiedSets,
      );
      newModifiedSets[targetExerciseIndex][setIndex] =
          newModifiedSets[targetExerciseIndex][setIndex].copyWith(reps: reps);

      _currentState = _currentState.copyWith(modifiedSets: newModifiedSets);
      state = AsyncValue.data(_currentState);
    });
  }

  // Adjust weight for current set
  void adjustWeight(double delta) {
    state.whenData((currentState) {
      final exerciseIndex = currentState.currentExerciseIndex;
      final setIndex = currentState.currentSetIndex;

      final currentWeight =
          _currentState.modifiedSets[exerciseIndex][setIndex].weight;
      final newWeight = (currentWeight + delta).clamp(0.0, 999.0);

      updateWeightForSet(
        newWeight.toString(),
        setIndex,
        exerciseIndex: exerciseIndex,
      );
    });
  }

  // Adjust reps for current set
  void adjustReps(int delta) {
    state.whenData((currentState) {
      final exerciseIndex = currentState.currentExerciseIndex;
      final setIndex = currentState.currentSetIndex;

      final currentReps =
          _currentState.modifiedSets[exerciseIndex][setIndex].reps;
      final newReps = (currentReps + delta).clamp(1, 999);

      updateRepsForSet(
        newReps.toString(),
        setIndex,
        exerciseIndex: exerciseIndex,
      );
    });
  }

  // Save workout progress to history (in-progress state)
  Future<void> _saveProgressToHistory() async {
    try {
      final historyEntry = WorkoutConverter.convertToHistoryEntry(
        _originalWorkout,
        _currentState,
        workoutDuration,
      );

      // Check if entry already exists (update) or create new
      final existingEntriesResult = await _workoutHistoryService
          .getWorkoutHistory(
            workoutName: _originalWorkout.name,
            startDate: _workoutStartTime?.subtract(const Duration(hours: 1)),
            endDate: DateTime.now(),
            page: 1,
            perPage: 1,
          );

      final existingEntries = existingEntriesResult.getOrThrow();

      if (existingEntries.isNotEmpty &&
          existingEntries.first.status == WorkoutHistoryStatus.inProgress) {
        // Update existing in-progress workout
        final updatedEntry = existingEntries.first.copyWith(
          duration: workoutDuration,
          exercises: historyEntry.exercises,
          totalSets: historyEntry.totalSets,
          totalReps: historyEntry.totalReps,
          totalWeightLifted: historyEntry.totalWeightLifted,
        );
        await _workoutHistoryService.updateWorkoutHistory(
          updatedEntry.id,
          updatedEntry,
        );
      } else {
        // Create new in-progress workout
        await _workoutHistoryService.createWorkoutHistory(historyEntry);
      }
    } catch (e) {
      print('Error saving workout progress: $e');
      // Don't throw error for progress saves to avoid disrupting user experience
    }
  }

  // Save completed workout to history
  Future<void> _saveCompletedWorkoutToHistory() async {
    try {
      final historyEntry = WorkoutConverter.convertToHistoryEntry(
        _originalWorkout,
        _currentState,
        workoutDuration,
      );

      // Check if an in-progress version exists
      final existingEntriesResult = await _workoutHistoryService
          .getWorkoutHistory(
            workoutName: _originalWorkout.name,
            startDate: _workoutStartTime?.subtract(const Duration(hours: 1)),
            endDate: DateTime.now(),
            page: 1,
            perPage: 1,
          );

      final existingEntries = existingEntriesResult.getOrThrow();

      if (existingEntries.isNotEmpty &&
          existingEntries.first.status == WorkoutHistoryStatus.inProgress) {
        // Update existing in-progress workout to completed
        final completedEntry = existingEntries.first.copyWith(
          status: WorkoutHistoryStatus.completed,
          completedAt: DateTime.now(),
          duration: workoutDuration,
          exercises: historyEntry.exercises,
          totalSets: historyEntry.totalSets,
          totalReps: historyEntry.totalReps,
          totalWeightLifted: historyEntry.totalWeightLifted,
        );
        await _workoutHistoryService.updateWorkoutHistory(
          completedEntry.id,
          completedEntry,
        );
      } else {
        // Create new completed workout entry
        await _workoutHistoryService.createWorkoutHistory(historyEntry);
      }

      // Note: Workout model doesn't track completion status, only the workout history does
      // The workout template remains unchanged regardless of completion
    } catch (e) {
      print('Error saving completed workout: $e');
      throw Exception('Failed to save workout to history: $e');
    }
  }

  // Helper methods
  int _findNextIncompleteSet(int exerciseIndex) {
    final completedSets = _currentState.completedSets;
    if (exerciseIndex >= completedSets.length) return 0;

    for (int i = 0; i < completedSets[exerciseIndex].length; i++) {
      if (!completedSets[exerciseIndex][i]) return i;
    }
    return completedSets[exerciseIndex].length - 1;
  }

  /// Get the last completed values for an exercise from workout history
  Future<Map<String, dynamic>?> _getLastExerciseValues(
    String exerciseId,
    String exerciseName,
  ) async {
    try {
      // Get recent workout history entries
      final historyEntriesResult = await _workoutHistoryService
          .getWorkoutHistory(
            page: 1,
            perPage: 20,
            status: WorkoutHistoryStatus.completed,
          );

      final historyEntries = historyEntriesResult.getOrThrow();

      // Find the most recent entry that contains this exercise with completed sets
      for (final entry in historyEntries) {
        try {
          final exerciseHistory = entry.exercises.firstWhere(
            (WorkoutHistoryExercise ex) =>
                ex.exerciseId == exerciseId || ex.exerciseName == exerciseName,
          );

          // Find the last completed set
          final completedSets = exerciseHistory.sets
              .where((WorkoutHistorySet set) => set.completed)
              .toList();
          if (completedSets.isNotEmpty) {
            final lastSet = completedSets.last;
            return {'reps': lastSet.reps, 'weight': lastSet.weight};
          }
        } catch (e) {
          // Exercise not found in this entry, continue to next entry
          continue;
        }
      }
    } catch (e) {
      // If any error occurs, return null
      print('Could not fetch last exercise values for $exerciseName: $e');
    }
    return null;
  }

  /// Prefill a set with weight and reps values
  void _prefillSet(int exerciseIndex, int setIndex, int reps, double weight) {
    final newModifiedSets = List<List<WorkoutSet>>.from(
      _currentState.modifiedSets,
    );

    if (exerciseIndex < newModifiedSets.length &&
        setIndex < newModifiedSets[exerciseIndex].length) {
      final currentSet = newModifiedSets[exerciseIndex][setIndex];
      newModifiedSets[exerciseIndex] = List<WorkoutSet>.from(
        newModifiedSets[exerciseIndex],
      );
      newModifiedSets[exerciseIndex][setIndex] = WorkoutSet(
        reps: reps,
        weight: weight,
        restTime: currentSet.restTime,
      );

      _currentState = _currentState.copyWith(modifiedSets: newModifiedSets);
    }
  }

  /// Prefill the next set with values from last completed set or workout history
  Future<void> _prefillNextSet(
    int exerciseIndex,
    int nextSetIndex,
    int? lastCompletedSetIndex,
  ) async {
    if (exerciseIndex >= _currentState.workout.exercises.length) return;

    final exercise = _currentState.workout.exercises[exerciseIndex];
    int? prefilledReps;
    double? prefilledWeight;

    // First, try to get values from the last completed set in current workout
    if (lastCompletedSetIndex != null && lastCompletedSetIndex >= 0) {
      final lastCompletedSet =
          _currentState.modifiedSets[exerciseIndex][lastCompletedSetIndex];
      prefilledReps = lastCompletedSet.reps;
      prefilledWeight = lastCompletedSet.weight;
      print(
        'Prefilling set $nextSetIndex with values from last completed set: $prefilledReps reps, ${prefilledWeight}kg',
      );
    } else {
      // If it's the first set of the exercise, get values from workout history
      final lastValues = await _getLastExerciseValues(
        exercise.exerciseId,
        exercise.exerciseName,
      );
      if (lastValues != null) {
        prefilledReps = lastValues['reps'] as int?;
        prefilledWeight = lastValues['weight'] as double?;
        print(
          'Prefilling first set with values from workout history: $prefilledReps reps, ${prefilledWeight}kg',
        );
      }
    }

    // Apply the prefilled values if we found any
    if (prefilledReps != null && prefilledWeight != null) {
      _prefillSet(exerciseIndex, nextSetIndex, prefilledReps, prefilledWeight);
    }
  }

  int _findNextIncompleteSetAfter(
    int exerciseIndex,
    int currentSetIndex,
    List<List<bool>> completedSets,
  ) {
    if (exerciseIndex >= completedSets.length) return 0;

    for (
      int i = currentSetIndex + 1;
      i < completedSets[exerciseIndex].length;
      i++
    ) {
      if (!completedSets[exerciseIndex][i]) return i;
    }

    // All sets completed in this exercise, return last set index
    return completedSets[exerciseIndex].length - 1;
  }
}

// Helper providers for the enhanced tracking
final enhancedWorkoutProgressProvider =
    Provider.family<double, EnhancedWorkoutTrackingParams>((ref, params) {
      return ref
          .watch(enhancedWorkoutTrackingProvider(params))
          .when(
            data: (state) {
              final totalSets = state.workout.exercises.fold(
                0,
                (sum, exercise) => sum + exercise.sets.length,
              );
              if (totalSets == 0) return 0.0;

              final completedSets = state.completedSets.fold(
                0,
                (sum, exerciseSets) =>
                    sum + exerciseSets.where((completed) => completed).length,
              );

              return completedSets / totalSets;
            },
            loading: () => 0.0,
            error: (_, __) => 0.0,
          );
    });

final enhancedWorkoutAllExercisesCompletedProvider =
    Provider.family<bool, EnhancedWorkoutTrackingParams>((ref, params) {
      return ref
          .watch(enhancedWorkoutTrackingProvider(params))
          .when(
            data: (state) {
              return state.completedSets.every(
                (exerciseSets) => exerciseSets.every((completed) => completed),
              );
            },
            loading: () => false,
            error: (_, __) => false,
          );
    });

final enhancedWorkoutDurationProvider =
    Provider.family<Duration, EnhancedWorkoutTrackingParams>((ref, params) {
      return ref
          .watch(enhancedWorkoutTrackingProvider(params))
          .when(
            data: (state) {
              final notifier = ref.read(
                enhancedWorkoutTrackingProvider(params).notifier,
              );
              return notifier.workoutDuration;
            },
            loading: () => Duration.zero,
            error: (_, __) => Duration.zero,
          );
    });
