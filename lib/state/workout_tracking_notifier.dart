import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import 'workout_tracking_state.dart';

/// Notifier for managing workout tracking state and business logic
class WorkoutTrackingNotifier extends StateNotifier<WorkoutTrackingState> {
  final WorkoutService _workoutService;
  final AuthService _authService;
  final void Function() _onAuthError;

  WorkoutTrackingNotifier({
    required Workout workout,
    required WorkoutService workoutService,
    required AuthService authService,
    required void Function() onAuthError,
  }) : _workoutService = workoutService,
       _authService = authService,
       _onAuthError = onAuthError,
       super(_initializeState(workout));

  /// Initialize state based on workout progress
  static WorkoutTrackingState _initializeState(Workout workout) {
    print('Initializing workout state for: ${workout.name}');
    print('  - isInProgress: ${workout.isInProgress}');
    print('  - has progress: ${workout.progress != null}');
    print('  - exercises: ${workout.exercises.length}');

    try {
      if (workout.isInProgress && workout.progress != null) {
        print('Creating state from existing progress');
        return WorkoutTrackingState.fromProgress(workout, workout.progress!);
      } else {
        print('Creating initial state');
        final state = WorkoutTrackingState.initial(workout);
        print('Initial state created successfully');
        return state;
      }
    } catch (e) {
      print('Error creating workout state: $e');
      rethrow;
    }
  }

  /// Update exercise statuses based on completed sets
  void _updateExerciseStatuses() {
    final newStatuses = <ExerciseStatus>[];

    for (int i = 0; i < state.workout.exercises.length; i++) {
      final exerciseCompletedSets = i < state.completedSets.length
          ? state.completedSets[i]
          : <bool>[];

      if (exerciseCompletedSets.isEmpty) {
        newStatuses.add(ExerciseStatus.notStarted);
      } else if (exerciseCompletedSets.every((completed) => completed)) {
        newStatuses.add(ExerciseStatus.completed);
      } else if (exerciseCompletedSets.any((completed) => completed)) {
        newStatuses.add(ExerciseStatus.inProgress);
      } else {
        newStatuses.add(ExerciseStatus.notStarted);
      }
    }

    state = state.copyWith(exerciseStatuses: newStatuses);
  }

  /// Select an exercise and switch to tracking view
  void selectExercise(int exerciseIndex) {
    print('=== Exercise Selection Debug ===');
    print('Selected exercise index: $exerciseIndex');

    if (exerciseIndex < 0 || exerciseIndex >= state.workout.exercises.length) {
      print(
        'Invalid exercise index: $exerciseIndex, workout has ${state.workout.exercises.length} exercises',
      );
      return;
    }

    final selectedExercise = state.workout.exercises[exerciseIndex];
    print('Selected exercise name: ${selectedExercise.exerciseName}');
    print(
      'Exercise details: exerciseId=${selectedExercise.exerciseId}, sets=${selectedExercise.sets.length}',
    );

    // Find the next incomplete set in the selected exercise
    int newSetIndex = 0;
    if (exerciseIndex < state.completedSets.length) {
      final exerciseSets = state.completedSets[exerciseIndex];
      final incompleteIndex = exerciseSets.indexWhere(
        (completed) => !completed,
      );
      newSetIndex = incompleteIndex == -1
          ? exerciseSets.length - 1
          : incompleteIndex;
    }

    print('Setting currentExerciseIndex to: $exerciseIndex');
    print('Setting currentSetIndex to: $newSetIndex');

    state = state.copyWith(
      selectedExerciseIndex: exerciseIndex,
      currentExerciseIndex: exerciseIndex,
      currentSetIndex: newSetIndex,
      currentView: WorkoutView.exerciseTracking,
      selectedSetIndex: null, // Clear set selection when changing exercises
    );

    print('After state update:');
    print('  currentExerciseIndex: ${state.currentExerciseIndex}');
    print('  currentExercise name: ${state.currentExercise.exerciseName}');
    print('=== End Exercise Selection Debug ===');
  }

  /// Return to exercise selection view
  void returnToExerciseSelection() {
    state = state.copyWith(
      currentView: WorkoutView.exerciseSelection,
      selectedExerciseIndex: null,
    );
  }

  /// Select/deselect a set for editing
  void selectSet(int setIndex) {
    final newSelectedIndex = state.selectedSetIndex == setIndex
        ? null
        : setIndex;
    state = state.copyWith(selectedSetIndex: newSelectedIndex);

    // Haptic feedback for selection
    HapticFeedback.selectionClick();
  }

  /// Update weight for current set
  void updateWeight(String value) {
    final weight = double.tryParse(value) ?? state.currentSet.weight;
    _updateCurrentSet(weight: weight);
  }

  /// Update reps for current set
  void updateReps(String value) {
    final reps = int.tryParse(value) ?? state.currentSet.reps;
    _updateCurrentSet(reps: reps);
  }

  /// Update weight for a specific set
  void updateWeightForSet(String value, int setIndex, {int? exerciseIndex}) {
    final targetExerciseIndex = exerciseIndex ?? state.currentExerciseIndex;
    final weight =
        double.tryParse(value) ??
        state.modifiedSets[targetExerciseIndex][setIndex].weight;
    _updateSetAtIndex(
      setIndex,
      weight: weight,
      exerciseIndex: targetExerciseIndex,
    );
  }

  /// Update reps for a specific set
  void updateRepsForSet(String value, int setIndex, {int? exerciseIndex}) {
    final targetExerciseIndex = exerciseIndex ?? state.currentExerciseIndex;
    final reps =
        int.tryParse(value) ??
        state.modifiedSets[targetExerciseIndex][setIndex].reps;
    _updateSetAtIndex(setIndex, reps: reps, exerciseIndex: targetExerciseIndex);
  }

  /// Adjust weight by a specific amount
  void adjustWeight(double adjustment) {
    final newWeight = (state.currentSet.weight + adjustment).clamp(0.0, 999.0);
    _updateCurrentSet(weight: newWeight);
    HapticFeedback.lightImpact();
  }

  /// Adjust reps by a specific amount
  void adjustReps(int adjustment) {
    final newReps = (state.currentSet.reps + adjustment).clamp(1, 999);
    _updateCurrentSet(reps: newReps);
    HapticFeedback.lightImpact();
  }

  /// Update current set with new values
  void _updateCurrentSet({int? reps, double? weight}) {
    final currentSet = state.currentSet;
    final newSet = WorkoutSet(
      reps: reps ?? currentSet.reps,
      weight: weight ?? currentSet.weight,
      restTime: currentSet.restTime,
    );

    final newModifiedSets = List<List<WorkoutSet>>.from(state.modifiedSets);
    newModifiedSets[state.currentExerciseIndex] = List<WorkoutSet>.from(
      newModifiedSets[state.currentExerciseIndex],
    );
    newModifiedSets[state.currentExerciseIndex][state.currentSetIndex] = newSet;

    state = state.copyWith(modifiedSets: newModifiedSets);
  }

  /// Update a specific set with new values
  void _updateSetAtIndex(
    int setIndex, {
    int? reps,
    double? weight,
    int? exerciseIndex,
  }) {
    final targetExerciseIndex = exerciseIndex ?? state.currentExerciseIndex;

    if (targetExerciseIndex < 0 ||
        targetExerciseIndex >= state.modifiedSets.length ||
        setIndex < 0 ||
        setIndex >= state.modifiedSets[targetExerciseIndex].length) {
      return;
    }

    final currentSet = state.modifiedSets[targetExerciseIndex][setIndex];
    final newSet = WorkoutSet(
      reps: reps ?? currentSet.reps,
      weight: weight ?? currentSet.weight,
      restTime: currentSet.restTime,
    );

    final newModifiedSets = List<List<WorkoutSet>>.from(state.modifiedSets);
    newModifiedSets[targetExerciseIndex] = List<WorkoutSet>.from(
      newModifiedSets[targetExerciseIndex],
    );
    newModifiedSets[targetExerciseIndex][setIndex] = newSet;

    state = state.copyWith(modifiedSets: newModifiedSets);
  }

  /// Complete the current set
  void completeSet() {
    // Safety checks
    if (state.currentExerciseIndex >= state.completedSets.length ||
        state.currentSetIndex >=
            state.completedSets[state.currentExerciseIndex].length) {
      return;
    }

    // Mark set as completed
    final newCompletedSets = List<List<bool>>.from(state.completedSets);
    newCompletedSets[state.currentExerciseIndex] = List<bool>.from(
      newCompletedSets[state.currentExerciseIndex],
    );
    newCompletedSets[state.currentExerciseIndex][state.currentSetIndex] = true;

    state = state.copyWith(completedSets: newCompletedSets);

    // Update exercise statuses
    _updateExerciseStatuses();

    // Move to next set or exercise
    _moveToNextSet();
  }

  /// Move to the next set or handle exercise completion
  void _moveToNextSet() {
    final currentExercise = state.currentExercise;
    final currentExerciseIndex = state.currentExerciseIndex;
    final currentSetIndex = state.currentSetIndex;

    if (currentSetIndex < currentExercise.sets.length - 1) {
      // Get values from the current (just completed) set to prefill the next set
      final currentSet = state.modifiedSets[currentExerciseIndex][currentSetIndex];
      final nextSetIndex = currentSetIndex + 1;
      
      // Prefill the next set with values from the current set
      _prefillNextSetWithValues(currentExerciseIndex, nextSetIndex, currentSet.reps, currentSet.weight);
      
      // Move to next set in current exercise
      state = state.copyWith(currentSetIndex: nextSetIndex);
    } else {
      // Exercise completed - check if all exercises are done
      print('Exercise completed. Checking if all exercises are finished...');
      print('Exercise statuses: ${state.exerciseStatuses}');

      if (state.areAllExercisesCompleted) {
        print('All exercises completed - finishing workout');
        // All exercises completed - finish workout
        completeWorkout();
      } else {
        print(
          'Some exercises still incomplete - returning to exercise selection',
        );
        // Return to exercise selection to choose next exercise
        returnToExerciseSelection();
      }
    }
  }

  /// Prefill the next set with weight and reps values from the previous set
  void _prefillNextSetWithValues(int exerciseIndex, int setIndex, int reps, double weight) {
    if (exerciseIndex < 0 ||
        exerciseIndex >= state.modifiedSets.length ||
        setIndex < 0 ||
        setIndex >= state.modifiedSets[exerciseIndex].length) {
      return;
    }

    final currentSet = state.modifiedSets[exerciseIndex][setIndex];
    final newSet = WorkoutSet(
      reps: reps,
      weight: weight,
      restTime: currentSet.restTime,
    );

    final newModifiedSets = List<List<WorkoutSet>>.from(state.modifiedSets);
    newModifiedSets[exerciseIndex] = List<WorkoutSet>.from(
      newModifiedSets[exerciseIndex],
    );
    newModifiedSets[exerciseIndex][setIndex] = newSet;

    state = state.copyWith(modifiedSets: newModifiedSets);
    
    print('Prefilled set $setIndex with values: $reps reps, ${weight}kg');
  }

  /// Navigate to a specific exercise via page change
  void onPageChanged(int exerciseIndex) {
    print('=== Page Changed Debug ===');
    print('PageView changed to index: $exerciseIndex');
    print('Previous currentExerciseIndex: ${state.currentExerciseIndex}');

    // Find the next incomplete set in the new exercise
    int newSetIndex = 0;
    if (exerciseIndex < state.completedSets.length) {
      final exerciseSets = state.completedSets[exerciseIndex];
      final incompleteIndex = exerciseSets.indexWhere(
        (completed) => !completed,
      );
      newSetIndex = incompleteIndex == -1
          ? exerciseSets.length - 1
          : incompleteIndex;
    }

    if (exerciseIndex < state.workout.exercises.length) {
      final exercise = state.workout.exercises[exerciseIndex];
      print('Exercise at page index $exerciseIndex: ${exercise.exerciseName}');
    }

    state = state.copyWith(
      currentExerciseIndex: exerciseIndex,
      currentSetIndex: newSetIndex,
      selectedSetIndex: null, // Clear set selection when switching exercises
    );

    print(
      'After page change: currentExerciseIndex=${state.currentExerciseIndex}',
    );
    print('=== End Page Changed Debug ===');
  }

  /// Save workout progress to backend
  Future<void> saveWorkoutProgress() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Update the workout exercises with any modifications made
      final updatedExercises = state.workout.exercises.asMap().entries.map((
        entry,
      ) {
        final index = entry.key;
        final exercise = entry.value;

        return WorkoutExercise(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          sets: state.modifiedSets[index],
        );
      }).toList();

      // Create workout with in-progress status and updated exercises
      final workoutToSave = state.workout.copyWith(
        exercises: updatedExercises,
        isInProgress: true,
        progress: state.toWorkoutProgress(),
      );

      // If workout has empty userId or doesn't exist in database, create it
      // Otherwise, update the existing document
      if (workoutToSave.userId.isEmpty) {
        // Empty userId means this was likely created from a program with missing userId
        // createWorkout will set the current user's ID automatically
        await _workoutService.createWorkout(workoutToSave);
      } else {
        try {
          // Try to update first
          await _workoutService.updateWorkout(workoutToSave);
        } catch (e) {
          // If update fails because document doesn't exist, create it instead
          if (e.toString().contains('document_not_found') ||
              e.toString().contains('404')) {
            await _workoutService.createWorkout(workoutToSave);
          } else {
            rethrow;
          }
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error saving progress: $e',
      );
      rethrow;
    }
  }

  /// Complete the entire workout
  ///
  /// [allowEarlyCompletion] - if true, allows completing the workout even if
  /// not all exercises are finished (useful for "End workout" functionality)
  Future<void> completeWorkout() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Create updated workout with modified sets and completion status
      final updatedExercises = state.workout.exercises.asMap().entries.map((
        entry,
      ) {
        final index = entry.key;
        final exercise = entry.value;

        return WorkoutExercise(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          sets: state.modifiedSets[index],
        );
      }).toList();

      // Ensure userId is set - if empty, this will be handled by createWorkout
      final completedWorkout = state.workout.copyWith(
        exercises: updatedExercises,
        isCompleted: true,
        completedDate: DateTime.now(),
        isInProgress: false,
        progress: null,
      );

      // If workout has empty userId or doesn't exist in database, create it
      // Otherwise, update the existing document
      if (completedWorkout.userId.isEmpty) {
        // Empty userId means this was likely created from a program with missing userId
        // createWorkout will set the current user's ID automatically
        await _workoutService.createWorkout(completedWorkout);
      } else {
        try {
          await _workoutService.updateWorkout(completedWorkout);
        } catch (e) {
          // If update fails because document doesn't exist, create it instead
          if (e.toString().contains('document_not_found') ||
              e.toString().contains('404')) {
            await _workoutService.createWorkout(completedWorkout);
          } else {
            rethrow;
          }
        }
      }

      state = state.copyWith(isWorkoutCompleted: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error saving workout: $e',
      );
      rethrow;
    }
  }

  /// Get workout duration
  Duration get workoutDuration {
    return state.workoutStartTime != null
        ? DateTime.now().difference(state.workoutStartTime!)
        : Duration.zero;
  }

  /// Reset error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}
