import '../models/workout.dart';
import '../models/workout_history.dart';
import '../models/workout_session.dart';
import '../state/workout_tracking_state.dart';

/// Utility class to convert between Workout and WorkoutHistoryEntry models
class WorkoutConverter {
  
  /// Converts a completed Workout to WorkoutHistoryEntry
  static WorkoutHistoryEntry convertToHistoryEntry(
    Workout workout,
    WorkoutTrackingState trackingState,
    Duration workoutDuration,
  ) {
    final completedAt = DateTime.now();
    final startedAt = completedAt.subtract(workoutDuration);
    
    // Convert exercises with actual completed data
    final historyExercises = workout.exercises.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value;
      
      // Get completed sets data from tracking state
      final completedSets = index < trackingState.completedSets.length
          ? trackingState.completedSets[index]
          : <bool>[];
          
      final modifiedSets = index < trackingState.modifiedSets.length
          ? trackingState.modifiedSets[index]
          : <WorkoutSet>[];
      
      // Convert sets with completion status
      final historySets = exercise.sets.asMap().entries.map((setEntry) {
        final setIndex = setEntry.key;
        final originalSet = setEntry.value;
        
        // Get modified set data if available
        final modifiedSet = setIndex < modifiedSets.length 
            ? modifiedSets[setIndex] 
            : originalSet;
            
        final isCompleted = setIndex < completedSets.length 
            ? completedSets[setIndex] 
            : false;
        
        return WorkoutHistorySet(
          reps: modifiedSet.reps,
          weight: modifiedSet.weight,
          restTime: modifiedSet.restTime,
          completed: isCompleted,
        );
      }).toList();
      
      return WorkoutHistoryExercise(
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.exerciseName,
        sets: historySets,
      );
    }).toList();
    
    // Calculate totals
    final totalSets = historyExercises.fold(0, (sum, ex) => sum + ex.totalSets);
    final totalReps = historyExercises.fold(0, (sum, ex) => 
        sum + ex.sets.where((set) => set.completed).fold(0, (reps, set) => reps + set.reps));
    final totalWeightLifted = historyExercises.fold(0.0, (sum, ex) => sum + ex.totalVolume);
    
    return WorkoutHistoryEntry(
      id: '', // Will be set by the service when created
      userId: workout.userId,
      name: workout.name,
      status: trackingState.isWorkoutCompleted 
          ? WorkoutHistoryStatus.completed 
          : WorkoutHistoryStatus.inProgress,
      scheduledDate: workout.scheduledDate,
      startedAt: startedAt,
      completedAt: trackingState.isWorkoutCompleted ? completedAt : null,
      duration: workoutDuration,
      exercises: historyExercises,
      totalSets: totalSets,
      totalReps: totalReps,
      totalWeightLifted: totalWeightLifted,
      notes: '', // Can be added later via the detail screen
    );
  }
  
  /// Converts WorkoutHistoryEntry back to Workout (for editing or continuing)
  static Workout convertFromHistoryEntry(WorkoutHistoryEntry entry) {
    // Convert exercises back to Workout format
    final workoutExercises = entry.exercises.map((historyExercise) {
      final sets = historyExercise.sets.map((historySet) {
        return WorkoutSet(
          reps: historySet.reps,
          weight: historySet.weight,
          restTime: historySet.restTime,
        );
      }).toList();
      
      return WorkoutExercise(
        exerciseId: historyExercise.exerciseId,
        exerciseName: historyExercise.exerciseName,
        sets: sets,
      );
    }).toList();
    
    return Workout(
      id: entry.id,
      userId: entry.userId,
      name: entry.name,
      description: entry.notes,
      scheduledDate: entry.scheduledDate ?? DateTime.now(),
      exercises: workoutExercises,
      isCompleted: entry.isCompleted,
      completedDate: entry.completedAt,
    );
  }
  
  /// Converts WorkoutSession to Workout for compatibility with WorkoutTrackingScreenRiverpod
  static Workout convertFromWorkoutSession(WorkoutSession session) {
    // Convert workout session exercises to workout exercises
    final workoutExercises = session.exercises.map((sessionExercise) {
      // Convert session sets to workout sets
      final workoutSets = sessionExercise.sets.map((sessionSet) {
        return WorkoutSet(
          reps: sessionSet.targetReps,
          weight: sessionSet.targetWeight,
          restTime: sessionSet.restTime,
        );
      }).toList();
      
      return WorkoutExercise(
        exerciseId: sessionExercise.exerciseId,
        exerciseName: sessionExercise.exerciseName,
        sets: workoutSets,
      );
    }).toList();
    
    return Workout(
      id: session.sessionId,
      userId: session.userId,
      name: session.name,
      description: session.description,
      scheduledDate: session.scheduledDate ?? DateTime.now(),
      exercises: workoutExercises,
      isCompleted: session.status == WorkoutSessionStatus.completed,
      completedDate: session.completedAt,
      isInProgress: session.status == WorkoutSessionStatus.inProgress,
    );
  }

  /// Creates a progress object from WorkoutHistoryEntry for resuming workouts
  static WorkoutProgress? createProgressFromHistory(WorkoutHistoryEntry entry) {
    if (entry.isCompleted) return null;
    
    // Find current exercise and set indices
    int currentExerciseIndex = 0;
    int currentSetIndex = 0;
    bool foundIncomplete = false;
    
    for (int exerciseIndex = 0; exerciseIndex < entry.exercises.length; exerciseIndex++) {
      final exercise = entry.exercises[exerciseIndex];
      
      for (int setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
        if (!exercise.sets[setIndex].completed) {
          currentExerciseIndex = exerciseIndex;
          currentSetIndex = setIndex;
          foundIncomplete = true;
          break;
        }
      }
      
      if (foundIncomplete) break;
    }
    
    // Build completed sets structure
    final completedSets = entry.exercises.map((exercise) {
      return exercise.sets.map((set) => set.completed).toList();
    }).toList();
    
    // Build modified sets structure
    final modifiedSets = entry.exercises.map((exercise) {
      return exercise.sets.map((set) {
        return WorkoutSet(
          reps: set.reps,
          weight: set.weight,
          restTime: set.restTime,
        );
      }).toList();
    }).toList();
    
    return WorkoutProgress(
      currentExerciseIndex: currentExerciseIndex,
      currentSetIndex: currentSetIndex,
      completedSets: completedSets,
      modifiedSets: modifiedSets,
      lastSavedAt: DateTime.now(),
    );
  }
}