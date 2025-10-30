import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../state/workout_tracking_notifier.dart';
import '../state/workout_tracking_state.dart';
import '../state/rest_timer_state.dart';

/// Provider for the rest timer notifier
final restTimerProvider = StateNotifierProvider<RestTimerNotifier, RestTimerState>(
  (ref) => RestTimerNotifier(),
);

/// Family provider for workout tracking notifier
/// This allows us to create different instances for different workouts
final workoutTrackingProvider = StateNotifierProvider.family<
    WorkoutTrackingNotifier, 
    WorkoutTrackingState, 
    WorkoutTrackingParams
>(
  (ref, params) {
    return WorkoutTrackingNotifier(
      workout: params.workout,
      workoutService: params.workoutService,
      authService: params.authService,
      onAuthError: params.onAuthError,
    );
  },
);

/// Parameters for workout tracking provider
class WorkoutTrackingParams {
  final Workout workout;
  final WorkoutService workoutService;
  final AuthService authService;
  final void Function() onAuthError;

  const WorkoutTrackingParams({
    required this.workout,
    required this.workoutService,
    required this.authService,
    required this.onAuthError,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutTrackingParams &&
        other.workout.id == workout.id &&
        other.workoutService == workoutService &&
        other.authService == authService;
  }

  @override
  int get hashCode {
    return workout.id.hashCode ^
        workoutService.hashCode ^
        authService.hashCode;
  }
}

/// Computed providers for commonly used derived state

/// Provider for current exercise
final currentExerciseProvider = Provider.family<WorkoutExercise?, WorkoutTrackingParams>(
  (ref, params) {
    final state = ref.watch(workoutTrackingProvider(params));
    if (state.currentExerciseIndex < state.workout.exercises.length) {
      return state.workout.exercises[state.currentExerciseIndex];
    }
    return null;
  },
);

/// Provider for current set
final currentSetProvider = Provider.family<WorkoutSet?, WorkoutTrackingParams>(
  (ref, params) {
    final state = ref.watch(workoutTrackingProvider(params));
    if (state.currentExerciseIndex < state.modifiedSets.length &&
        state.currentSetIndex < state.modifiedSets[state.currentExerciseIndex].length) {
      return state.modifiedSets[state.currentExerciseIndex][state.currentSetIndex];
    }
    return null;
  },
);

/// Provider for workout progress percentage
final workoutProgressProvider = Provider.family<double, WorkoutTrackingParams>(
  (ref, params) {
    final state = ref.watch(workoutTrackingProvider(params));
    return state.workoutProgress;
  },
);

/// Provider for total completed sets count
final totalCompletedSetsProvider = Provider.family<int, WorkoutTrackingParams>(
  (ref, params) {
    final state = ref.watch(workoutTrackingProvider(params));
    return state.totalCompletedSetsCount;
  },
);

/// Provider for total sets count
final totalSetsProvider = Provider.family<int, WorkoutTrackingParams>(
  (ref, params) {
    final state = ref.watch(workoutTrackingProvider(params));
    return state.totalSetsCount;
  },
);

/// Provider for checking if all exercises are completed
final allExercisesCompletedProvider = Provider.family<bool, WorkoutTrackingParams>(
  (ref, params) {
    final state = ref.watch(workoutTrackingProvider(params));
    return state.areAllExercisesCompleted;
  },
);

/// Provider for current set completion status
final currentSetCompletedProvider = Provider.family<bool, WorkoutTrackingParams>(
  (ref, params) {
    final state = ref.watch(workoutTrackingProvider(params));
    return state.isCurrentSetCompleted;
  },
);

/// Provider for exercise completion status at a specific index
final exerciseStatusProvider = Provider.family<ExerciseStatus?, (WorkoutTrackingParams, int)>(
  (ref, data) {
    final (params, index) = data;
    final state = ref.watch(workoutTrackingProvider(params));
    if (index >= 0 && index < state.exerciseStatuses.length) {
      return state.exerciseStatuses[index];
    }
    return null;
  },
);

/// Provider for completed sets count for a specific exercise
final exerciseCompletedSetsProvider = Provider.family<int, (WorkoutTrackingParams, int)>(
  (ref, data) {
    final (params, index) = data;
    final state = ref.watch(workoutTrackingProvider(params));
    if (index >= 0 && index < state.completedSets.length) {
      return state.completedSets[index].where((completed) => completed).length;
    }
    return 0;
  },
);

/// Provider for checking if a specific set is completed
final setCompletedProvider = Provider.family<bool, (WorkoutTrackingParams, int, int)>(
  (ref, data) {
    final (params, exerciseIndex, setIndex) = data;
    final state = ref.watch(workoutTrackingProvider(params));
    if (exerciseIndex >= 0 && exerciseIndex < state.completedSets.length &&
        setIndex >= 0 && setIndex < state.completedSets[exerciseIndex].length) {
      return state.completedSets[exerciseIndex][setIndex];
    }
    return false;
  },
);

/// Provider for getting a specific set's data
final setDataProvider = Provider.family<WorkoutSet?, (WorkoutTrackingParams, int, int)>(
  (ref, data) {
    final (params, exerciseIndex, setIndex) = data;
    final state = ref.watch(workoutTrackingProvider(params));
    if (exerciseIndex >= 0 && exerciseIndex < state.modifiedSets.length &&
        setIndex >= 0 && setIndex < state.modifiedSets[exerciseIndex].length) {
      return state.modifiedSets[exerciseIndex][setIndex];
    }
    return null;
  },
);

/// Auto-start rest timer when a set is completed
final restTimerAutoStartProvider = Provider.family<void, WorkoutTrackingParams>(
  (ref, params) {
    final state = ref.watch(workoutTrackingProvider(params));
    final restTimerNotifier = ref.read(restTimerProvider.notifier);
    
    // Listen for set completion and automatically start rest timer
    ref.listen<WorkoutTrackingState>(
      workoutTrackingProvider(params),
      (previous, next) {
        // Check if a set was just completed (not just navigation change)
        // Only start rest timer when:
        // 1. A set was actually completed (not just navigation change)
        // 2. We're still on the same exercise and set (no page change)
        // 3. The set has a rest time configured
        if (previous != null && 
            !previous.isCurrentSetCompleted && 
            next.isCurrentSetCompleted &&
            previous.currentExerciseIndex == next.currentExerciseIndex &&
            previous.currentSetIndex == next.currentSetIndex) {
          final currentSet = next.currentSet;
          if (currentSet.restTime != null && 
              currentSet.restTime!.inSeconds > 0) {
            restTimerNotifier.startTimer(currentSet.restTime!);
          }
        }
      },
    );
  },
);

/// Error handling provider
final workoutTrackingErrorProvider = Provider.family<String?, WorkoutTrackingParams>(
  (ref, params) {
    final state = ref.watch(workoutTrackingProvider(params));
    return state.error;
  },
);

/// Loading state provider
final workoutTrackingLoadingProvider = Provider.family<bool, WorkoutTrackingParams>(
  (ref, params) {
    final state = ref.watch(workoutTrackingProvider(params));
    return state.isLoading;
  },
);