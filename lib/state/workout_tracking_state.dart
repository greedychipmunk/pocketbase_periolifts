import '../models/workout.dart';

/// Enum for different view states in workout tracking
enum WorkoutView { exerciseSelection, exerciseTracking }

/// Enum for exercise completion status
enum ExerciseStatus { notStarted, inProgress, completed }

/// Immutable state class for workout tracking
class WorkoutTrackingState {
  final Workout workout;
  final WorkoutView currentView;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final int? selectedExerciseIndex;
  final int? selectedSetIndex;
  final List<List<bool>> completedSets;
  final List<List<WorkoutSet>> modifiedSets;
  final List<ExerciseStatus> exerciseStatuses;
  final DateTime? workoutStartTime;
  final bool isWorkoutCompleted;
  final bool isLoading;
  final String? error;

  const WorkoutTrackingState({
    required this.workout,
    this.currentView = WorkoutView.exerciseSelection,
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.selectedExerciseIndex,
    this.selectedSetIndex,
    required this.completedSets,
    required this.modifiedSets,
    required this.exerciseStatuses,
    this.workoutStartTime,
    this.isWorkoutCompleted = false,
    this.isLoading = false,
    this.error,
  });

  /// Factory constructor to create initial state from a workout
  factory WorkoutTrackingState.initial(Workout workout) {
    final completedSets = workout.exercises
        .map((exercise) => List.filled(exercise.sets.length, false))
        .toList();

    final modifiedSets = workout.exercises
        .map((exercise) => exercise.sets
            .map((set) => WorkoutSet(
                  reps: set.reps,
                  weight: set.weight,
                  restTime: set.restTime,
                ))
            .toList())
        .toList();

    final exerciseStatuses = List.filled(
      workout.exercises.length,
      ExerciseStatus.notStarted,
    );

    return WorkoutTrackingState(
      workout: workout,
      completedSets: completedSets,
      modifiedSets: modifiedSets,
      exerciseStatuses: exerciseStatuses,
      workoutStartTime: DateTime.now(),
    );
  }

  /// Factory constructor to resume from saved progress
  factory WorkoutTrackingState.fromProgress(
    Workout workout,
    WorkoutProgress progress,
  ) {
    // Safely restore completed sets
    List<List<bool>> completedSets;
    try {
      completedSets = progress.completedSets
          .map((exerciseSets) => List<bool>.from(exerciseSets))
          .toList();
    } catch (e) {
      completedSets = workout.exercises
          .map((exercise) => List.filled(exercise.sets.length, false))
          .toList();
    }

    // Safely restore modified sets
    List<List<WorkoutSet>> modifiedSets;
    try {
      modifiedSets = progress.modifiedSets
          .map((exerciseSets) => exerciseSets
              .map((set) => WorkoutSet(
                    reps: set.reps,
                    weight: set.weight,
                    restTime: set.restTime,
                  ))
              .toList())
          .toList();
    } catch (e) {
      modifiedSets = workout.exercises
          .map((exercise) => exercise.sets
              .map((set) => WorkoutSet(
                    reps: set.reps,
                    weight: set.weight,
                    restTime: set.restTime,
                  ))
              .toList())
          .toList();
    }

    final exerciseStatuses = _calculateExerciseStatuses(
      workout.exercises.length,
      completedSets,
    );

    return WorkoutTrackingState(
      workout: workout,
      currentView: WorkoutView.exerciseTracking,
      currentExerciseIndex: progress.currentExerciseIndex,
      currentSetIndex: progress.currentSetIndex,
      selectedExerciseIndex: progress.currentExerciseIndex,
      completedSets: completedSets,
      modifiedSets: modifiedSets,
      exerciseStatuses: exerciseStatuses,
      workoutStartTime: DateTime.now(),
    );
  }

  /// Calculate exercise statuses based on completed sets
  static List<ExerciseStatus> _calculateExerciseStatuses(
    int exerciseCount,
    List<List<bool>> completedSets,
  ) {
    final statuses = <ExerciseStatus>[];
    
    for (int i = 0; i < exerciseCount; i++) {
      final exerciseCompletedSets = i < completedSets.length 
          ? completedSets[i] 
          : <bool>[];

      if (exerciseCompletedSets.isEmpty) {
        statuses.add(ExerciseStatus.notStarted);
      } else if (exerciseCompletedSets.every((completed) => completed)) {
        statuses.add(ExerciseStatus.completed);
      } else if (exerciseCompletedSets.any((completed) => completed)) {
        statuses.add(ExerciseStatus.inProgress);
      } else {
        statuses.add(ExerciseStatus.notStarted);
      }
    }
    
    return statuses;
  }

  /// Create a copy with updated fields
  WorkoutTrackingState copyWith({
    Workout? workout,
    WorkoutView? currentView,
    int? currentExerciseIndex,
    int? currentSetIndex,
    int? selectedExerciseIndex,
    int? selectedSetIndex,
    List<List<bool>>? completedSets,
    List<List<WorkoutSet>>? modifiedSets,
    List<ExerciseStatus>? exerciseStatuses,
    DateTime? workoutStartTime,
    bool? isWorkoutCompleted,
    bool? isLoading,
    String? error,
  }) {
    return WorkoutTrackingState(
      workout: workout ?? this.workout,
      currentView: currentView ?? this.currentView,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      selectedExerciseIndex: selectedExerciseIndex ?? this.selectedExerciseIndex,
      selectedSetIndex: selectedSetIndex ?? this.selectedSetIndex,
      completedSets: completedSets ?? this.completedSets,
      modifiedSets: modifiedSets ?? this.modifiedSets,
      exerciseStatuses: exerciseStatuses ?? this.exerciseStatuses,
      workoutStartTime: workoutStartTime ?? this.workoutStartTime,
      isWorkoutCompleted: isWorkoutCompleted ?? this.isWorkoutCompleted,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Helper methods for computed properties

  /// Get current exercise
  WorkoutExercise get currentExercise => workout.exercises[currentExerciseIndex];

  /// Get current set
  WorkoutSet get currentSet => modifiedSets[currentExerciseIndex][currentSetIndex];

  /// Check if current set is completed
  bool get isCurrentSetCompleted => 
      completedSets[currentExerciseIndex][currentSetIndex];

  /// Get total completed sets count
  int get totalCompletedSetsCount {
    return completedSets.fold(
      0,
      (sum, exerciseSets) =>
          sum + exerciseSets.where((completed) => completed).length,
    );
  }

  /// Get total sets count
  int get totalSetsCount {
    return workout.exercises.fold(
      0,
      (sum, exercise) => sum + exercise.sets.length,
    );
  }

  /// Get workout progress as percentage
  double get workoutProgress {
    return totalSetsCount > 0 ? totalCompletedSetsCount / totalSetsCount : 0.0;
  }

  /// Check if all exercises are completed
  bool get areAllExercisesCompleted {
    // Primary check using exercise statuses
    if (!exerciseStatuses.every((status) => status == ExerciseStatus.completed)) {
      return false;
    }
    
    // Double-check by directly validating completedSets to prevent race conditions
    return _validateAllSetsCompleted();
  }

  /// Validate that all sets in all exercises are actually completed
  bool _validateAllSetsCompleted() {
    // Check if we have the right number of exercise completion arrays
    if (completedSets.length != workout.exercises.length) {
      print('Validation failed: completedSets length (${completedSets.length}) != exercises length (${workout.exercises.length})');
      return false;
    }
    
    for (int i = 0; i < workout.exercises.length; i++) {
      final exercise = workout.exercises[i];
      final exerciseCompletedSets = completedSets[i];
      
      // Check if we have completion data for all sets in this exercise
      if (exerciseCompletedSets.length != exercise.sets.length) {
        print('Validation failed: Exercise $i (${exercise.exerciseName}) has ${exerciseCompletedSets.length} completion records but ${exercise.sets.length} sets');
        return false;
      }
      
      // Check if every set in this exercise is completed
      if (!exerciseCompletedSets.every((setCompleted) => setCompleted)) {
        final incompleteSetIndex = exerciseCompletedSets.indexWhere((setCompleted) => !setCompleted);
        print('Validation failed: Exercise $i (${exercise.exerciseName}) has incomplete set at index $incompleteSetIndex');
        print('  Completed sets: $exerciseCompletedSets');
        return false;
      }
    }
    
    print('All sets validation passed: All ${workout.exercises.length} exercises with ${totalSetsCount} total sets are completed');
    return true;
  }

  /// Convert to WorkoutProgress for persistence
  WorkoutProgress toWorkoutProgress() {
    return WorkoutProgress(
      currentExerciseIndex: currentExerciseIndex,
      currentSetIndex: currentSetIndex,
      completedSets: completedSets,
      modifiedSets: modifiedSets,
      lastSavedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'WorkoutTrackingState('
        'workout: ${workout.name}, '
        'currentView: $currentView, '
        'currentExercise: $currentExerciseIndex, '
        'currentSet: $currentSetIndex, '
        'isCompleted: $isWorkoutCompleted, '
        'progress: ${(workoutProgress * 100).toStringAsFixed(1)}%'
        ')';
  }
}