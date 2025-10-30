import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../providers/workout_tracking_providers.dart';
import '../providers/units_provider.dart';
import '../providers/rest_time_settings_provider.dart';
import '../state/workout_tracking_state.dart';
import '../widgets/base_layout.dart';
import 'workout_summary_screen.dart';

/// WorkoutTrackingScreenRiverpod - Workout tracking screen using Riverpod for state management
class WorkoutTrackingScreenRiverpod extends ConsumerStatefulWidget {
  final Workout workout;
  final WorkoutService workoutService;
  final AuthService authService;
  final VoidCallback onAuthError;

  const WorkoutTrackingScreenRiverpod({
    super.key,
    required this.workout,
    required this.workoutService,
    required this.authService,
    required this.onAuthError,
  });

  @override
  ConsumerState<WorkoutTrackingScreenRiverpod> createState() =>
      _WorkoutTrackingScreenRiverpodState();
}

class _WorkoutTrackingScreenRiverpodState
    extends ConsumerState<WorkoutTrackingScreenRiverpod> {
  PageController? _pageController;
  late WorkoutTrackingParams _params;
  int _currentPageIndex = 0; // Track PageView's current page

  @override
  void initState() {
    super.initState();

    _params = WorkoutTrackingParams(
      workout: widget.workout,
      workoutService: widget.workoutService,
      authService: widget.authService,
      onAuthError: widget.onAuthError,
    );

    // Initialize the current page index to match the initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = ref.read(workoutTrackingProvider(_params));
        setState(() {
          _currentPageIndex = state.currentExerciseIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(
      'Building WorkoutTrackingScreenRiverpod for workout: ${widget.workout.name}',
    );

    // Safely watch the provider with error handling
    final providerState = ref.watch(workoutTrackingProvider(_params));

    // Add a listener for state changes (like workout completion)
    ref.listen<WorkoutTrackingState>(workoutTrackingProvider(_params), (
      previous,
      next,
    ) {
      // Only proceed if widget is still mounted
      if (!mounted) return;

      if (next.isWorkoutCompleted) {
        _showCompletionDialog();
      }

      // Handle errors
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    // Debug state information
    print(
      'Riverpod state - isLoading: ${providerState.isLoading}, view: ${providerState.currentView}',
    );

    // Show loading state if needed
    if (providerState.isLoading) {
      return BaseLayout(
        workoutService: widget.workoutService,
        authService: widget.authService,
        onAuthError: widget.onAuthError,
        currentIndex: 0, // Home tab during workout
        title: 'Loading...',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show appropriate view based on current state with rest timer overlay
    return Stack(
      children: [
        // Main content view
        providerState.currentView == WorkoutView.exerciseSelection
            ? _buildExerciseSelectionView(providerState)
            : _buildExerciseTrackingView(providerState),

        // Rest timer overlay that persists across all views
        _buildRestTimerOverlay(),
      ],
    );
  }

  Widget _buildExerciseSelectionView(WorkoutTrackingState state) {
    return BaseLayout(
      workoutService: widget.workoutService,
      authService: widget.authService,
      onAuthError: widget.onAuthError,
      currentIndex: 0, // Home tab during workout
      title: state.workout.name,
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        children: [
          // Progress header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Workout Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.totalCompletedSetsCount} of ${state.totalSetsCount} sets completed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: state.workoutProgress,
                  backgroundColor: Colors.grey[300],
                ),
              ],
            ),
          ),
          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.workout.exercises.length,
              itemBuilder: (context, index) {
                final exercise = state.workout.exercises[index];
                final status = index < state.exerciseStatuses.length
                    ? state.exerciseStatuses[index]
                    : ExerciseStatus.notStarted;
                final completedSetsCount = index < state.completedSets.length
                    ? state.completedSets[index]
                          .where((completed) => completed)
                          .length
                    : 0;

                print(
                  'Building exercise card: index=$index, name=${exercise.exerciseName}',
                );
                return _buildExerciseCard(
                  exercise,
                  index,
                  status,
                  completedSetsCount,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildExerciseSelectionAppBar() {
    final state = ref.watch(workoutTrackingProvider(_params));

    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      title: Text(
        state.workout.name,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showExitDialog,
          tooltip: 'End Workout',
        ),
      ],
    );
  }

  Widget _buildWorkoutProgressHeader() {
    final totalSets = ref.watch(totalSetsProvider(_params));
    final completedSets = ref.watch(totalCompletedSetsProvider(_params));
    final progress = ref.watch(workoutProgressProvider(_params));
    final state = ref.watch(workoutTrackingProvider(_params));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise ${state.currentExerciseIndex + 1} of ${state.workout.exercises.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedSets of $totalSets sets completed',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    WorkoutExercise exercise,
    int index,
    ExerciseStatus status,
    int completedSetsCount,
  ) {
    final totalSets = exercise.sets.length;
    final progress = totalSets > 0 ? completedSetsCount / totalSets : 0.0;

    Color cardColor;
    Color progressColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case ExerciseStatus.notStarted:
        cardColor = Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3);
        progressColor = Theme.of(context).colorScheme.outline.withOpacity(0.3);
        statusIcon = Icons.play_circle_outline;
        statusText = 'Not Started';
        break;
      case ExerciseStatus.inProgress:
        cardColor = Theme.of(
          context,
        ).colorScheme.primaryContainer.withOpacity(0.3);
        progressColor = Theme.of(context).colorScheme.primary;
        statusIcon = Icons.pause_circle_outline;
        statusText = 'In Progress';
        break;
      case ExerciseStatus.completed:
        cardColor = Theme.of(
          context,
        ).colorScheme.tertiaryContainer.withOpacity(0.5);
        progressColor = Theme.of(context).colorScheme.tertiary;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: progressColor.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: () {
          print(
            'Exercise card tapped: index=$index, exercise=${exercise.exerciseName}',
          );

          // First switch to exercise tracking view
          ref
              .read(workoutTrackingProvider(_params).notifier)
              .selectExercise(index);

          // Then navigate the PageView to the correct page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController != null && _pageController!.hasClients) {
              setState(() {
                _currentPageIndex = index;
              });
              _pageController!.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: progressColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$totalSets sets',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              statusText,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: progressColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
              if (status == ExerciseStatus.completed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$completedSetsCount/$totalSets',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseTrackingView(WorkoutTrackingState providerState) {
    // Initialize PageController if not already done
    if (_pageController == null) {
      print('=== PageController Init Debug ===');
      print(
        'Initializing PageController with page: ${providerState.currentExerciseIndex}',
      );
      print(
        'Current exercise name: ${providerState.currentExercise.exerciseName}',
      );
      print(
        'Setting _currentPageIndex to: ${providerState.currentExerciseIndex}',
      );
      print('=== End PageController Init Debug ===');

      // Ensure PageView index is in sync with the state
      _currentPageIndex = providerState.currentExerciseIndex;
      _pageController = PageController(
        initialPage: providerState.currentExerciseIndex,
      );
    }

    // Use PageView's current page index instead of state's currentExerciseIndex
    final displayExerciseIndex = _currentPageIndex;
    final displayExercise = providerState.workout.exercises[displayExerciseIndex];

    return BaseLayout(
      workoutService: widget.workoutService,
      authService: widget.authService,
      onAuthError: widget.onAuthError,
      currentIndex: 0, // Home tab during workout
      title: 'PerioLifts',
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref
              .read(workoutTrackingProvider(_params).notifier)
              .returnToExerciseSelection(),
          tooltip: 'Back to Exercises',
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showExitDialog,
          tooltip: 'End Workout',
        ),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final state = providerState;

          return PageView.builder(
            itemCount: state.workout.exercises.length,
            controller: _pageController!,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
              ref
                  .read(workoutTrackingProvider(_params).notifier)
                  .onPageChanged(index);
            },
            itemBuilder: (context, index) {
              return _buildExerciseTrackingContent(index);
            },
          );
        },
      ),
    );
  }



  Widget _buildExerciseTrackingContent(int exerciseIndex) {
    final state = ref.watch(workoutTrackingProvider(_params));
    final exercise = state.workout.exercises[exerciseIndex];

    // Debug logging to track exercise data isolation
    print('=== Exercise Tracking Content Debug ===');
    print('PageView exerciseIndex: $exerciseIndex');
    print('Exercise name: ${exercise.exerciseName}');
    print('State currentExerciseIndex: ${state.currentExerciseIndex}');
    print('Exercise has ${exercise.sets.length} sets');
    print('=== End Debug ===');

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewPadding.bottom + 8, // Account for bottom navigation bar
      ),
      child: Column(
        children: [
          // Exercise name header (ensure it uses the correct exercise)
          _buildExerciseNameHeader(exercise),
          const SizedBox(height: 20),

          // All sets list
          Expanded(child: _buildAllSetsList(exercise, exerciseIndex)),
          const SizedBox(height: 12),

          // Navigation and secondary actions
          _buildBottomNavigation(),
          const SizedBox(height: 16), // Space for floating button
        ],
      ),
    );
  }

  Widget _buildExerciseNameHeader(WorkoutExercise exercise) {
    // Debug to ensure we're showing the right exercise name
    print('Building exercise header for: ${exercise.exerciseName}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            exercise.exerciseName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${exercise.sets.length} Sets Total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllSetsList(WorkoutExercise exercise, int exerciseIndex) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      itemCount: exercise.sets.length,
      itemBuilder: (context, setIndex) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildSetCard(exerciseIndex, setIndex),
        );
      },
    );
  }

  Widget _buildSetCard(int exerciseIndex, int setIndex) {
    final state = ref.watch(workoutTrackingProvider(_params));
    final setData = ref.watch(
      setDataProvider((_params, exerciseIndex, setIndex)),
    );
    final isCompleted = ref.watch(
      setCompletedProvider((_params, exerciseIndex, setIndex)),
    );

    if (setData == null) return const SizedBox.shrink();

    final isCurrent =
        exerciseIndex == state.currentExerciseIndex &&
        setIndex == state.currentSetIndex;
    final isSelected = state.selectedSetIndex == setIndex;
    // For sets in different exercises, only disable if the current exercise hasn't been reached
    // For sets in the current exercise, use the existing logic
    final isDisabled = exerciseIndex != state.currentExerciseIndex
        ? false // Allow editing any set in non-current exercises
        : (!isCompleted && !isCurrent && setIndex > state.currentSetIndex);

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () => ref
                .read(workoutTrackingProvider(_params).notifier)
                .selectSet(setIndex),
      child: Card(
        elevation: isDisabled ? 1 : (isSelected ? 6 : (isCurrent ? 4 : 2)),
        shadowColor: isDisabled
            ? Colors.black.withOpacity(0.05)
            : isSelected
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.4)
            : isCurrent
            ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
            : Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDisabled
              ? BorderSide.none
              : isSelected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 2,
                )
              : isCurrent
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDisabled
                ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
                : isSelected
                ? Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withOpacity(0.4)
                : isCompleted
                ? Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer.withOpacity(0.5)
                : isCurrent
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Set header
                _buildSetHeader(setIndex, isCompleted, isCurrent, isDisabled),
                const SizedBox(height: 12),

                // Set details
                if (isSelected || (!isCompleted && isCurrent)) ...[
                  // Editable set details for selected (including completed) or current set
                  _buildEditableSetDetails(setData, setIndex, exerciseIndex),
                ] else ...[
                  // Read-only set details for non-selected completed/future sets
                  _buildReadOnlySetDetails(setData, isDisabled),
                ],

                // Complete button for current set
                if (!isCompleted && isCurrent) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(workoutTrackingProvider(_params).notifier)
                          .completeSet(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Complete Set'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                // Update button for completed sets
                if (isCompleted && !isSelected) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => ref
                          .read(workoutTrackingProvider(_params).notifier)
                          .selectSet(setIndex),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Update Set'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.tertiary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                // Save changes button for selected completed sets
                if (isCompleted && isSelected) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Simply deselect the set without saving changes
                            ref
                                .read(workoutTrackingProvider(_params).notifier)
                                .selectSet(setIndex);
                          },
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.outline,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Save the workout progress and deselect the set
                            try {
                              await ref
                                  .read(workoutTrackingProvider(_params).notifier)
                                  .saveWorkoutProgress();
                              ref
                                  .read(workoutTrackingProvider(_params).notifier)
                                  .selectSet(setIndex); // Deselect the set
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Set updated successfully'),
                                      ],
                                    ),
                                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text('Failed to update set: $e')),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.tertiary,
                            foregroundColor: Theme.of(context).colorScheme.onTertiary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetHeader(
    int setIndex,
    bool isCompleted,
    bool isCurrent,
    bool isDisabled,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDisabled
                ? Theme.of(context).colorScheme.outline.withOpacity(0.1)
                : isCompleted
                ? Theme.of(context).colorScheme.tertiary
                : isCurrent
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check_rounded,
                    color: Theme.of(context).colorScheme.onTertiary,
                    size: 16,
                  )
                : Text(
                    '${setIndex + 1}',
                    style: TextStyle(
                      color: isDisabled
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3)
                          : isCurrent
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Set ${setIndex + 1}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDisabled
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                : isCompleted
                ? Theme.of(context).colorScheme.tertiary
                : isCurrent
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        const Spacer(),
        if (isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'COMPLETED',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit,
                  size: 12,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
          )
        else if (isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'CURRENT',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditableSetDetails(
    WorkoutSet set,
    int setIndex,
    int exerciseIndex,
  ) {
    return Column(
      children: [
        // Weight section
        _buildWeightEditor(set, setIndex, exerciseIndex),
        const SizedBox(height: 16),

        // Reps section
        _buildRepsEditor(set, setIndex, exerciseIndex),
      ],
    );
  }

  Widget _buildWeightEditor(WorkoutSet set, int setIndex, int exerciseIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Weight label with icon
        Row(
          children: [
            Icon(
              Icons.fitness_center,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Weight',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),

        // Weight text field
        provider.Consumer<UnitsProvider>(
          builder: (context, unitsProvider, child) {
            return Container(
              width: 140,
              child: TextFormField(
                initialValue: set.weight > 0 ? set.weight.toString() : '',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  suffixText: unitsProvider.getWeightUnit(),
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  suffixStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
                onChanged: (value) {
                  // Convert empty string to '0' for consistency
                  final weightValue = value.isEmpty ? '0' : value;
                  ref
                      .read(workoutTrackingProvider(_params).notifier)
                      .updateWeightForSet(
                        weightValue,
                        setIndex,
                        exerciseIndex: exerciseIndex,
                      );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRepsEditor(WorkoutSet set, int setIndex, int exerciseIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Reps label with icon
        Row(
          children: [
            Icon(
              Icons.repeat,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Reps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),

        // Reps text field
        Container(
          width: 140,
          child: TextFormField(
            initialValue: set.reps.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              suffixText: 'reps',
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              suffixStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
            onChanged: (value) {
              // Convert empty string to '0' for consistency
              final repsValue = value.isEmpty ? '0' : value;
              ref
                  .read(workoutTrackingProvider(_params).notifier)
                  .updateRepsForSet(
                    repsValue,
                    setIndex,
                    exerciseIndex: exerciseIndex,
                  );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlySetDetails(WorkoutSet set, bool isDisabled) {
    return Row(
      children: [
        // Weight
        Icon(
          Icons.fitness_center,
          size: 16,
          color: isDisabled
              ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 4),
        provider.Consumer<UnitsProvider>(
          builder: (context, unitsProvider, child) {
            return Text(
              unitsProvider.formatWeight(set.weight),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isDisabled
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                    : null,
              ),
            );
          },
        ),
        const SizedBox(width: 16),

        // Reps
        Icon(
          Icons.repeat,
          size: 16,
          color: isDisabled
              ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          '${set.reps} reps',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isDisabled
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRestTimerOverlay() {
    return Consumer(
      builder: (context, ref, child) {
        final restTimerState = ref.watch(restTimerProvider);

        // Auto-start timer when set is completed
        ref.listen<WorkoutTrackingState>(workoutTrackingProvider(_params), (
          previous,
          next,
        ) {
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
            
            // Get effective rest time based on settings
            final restTimeProvider = provider.Provider.of<RestTimeSettingsProvider>(context, listen: false);
            restTimeProvider.getEffectiveRestTime(currentSet.restTime).then((effectiveRestTime) {
              if (effectiveRestTime.inSeconds > 0) {
                ref
                    .read(restTimerProvider.notifier)
                    .startTimer(effectiveRestTime);
              }
            });
          }
        });

        if (!restTimerState.isResting) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: GestureDetector(
            onTap: () => ref.read(restTimerProvider.notifier).skipRest(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Rest Time',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        restTimerState.formattedTime,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to skip',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    final allCompleted = ref.watch(allExercisesCompletedProvider(_params));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Workout completion button (if all exercises are done)
        if (allCompleted)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => ref
                  .read(workoutTrackingProvider(_params).notifier)
                  .completeWorkout(),
              icon: const Icon(Icons.celebration),
              label: const Text('Complete Workout'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }

  void _showCompletionDialog() {
    final notifier = ref.read(workoutTrackingProvider(_params).notifier);
    final workoutDuration = notifier.workoutDuration;
    final state = ref.read(workoutTrackingProvider(_params));

    // Navigate to comprehensive workout summary screen instead of showing dialog
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryScreen(
          workout: state.workout,
          workoutDuration: workoutDuration,
          trackingState: state,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Workout?'),
        content: const Text(
          'What would you like to do with your current progress?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(88, 48),
            ),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              try {
                // Show loading indicator
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Completing workout...'),
                        ],
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                // Complete workout (allow early completion)
                await ref
                    .read(workoutTrackingProvider(_params).notifier)
                    .completeWorkout();

                // Success: The state listener will handle navigation to completion dialog
                // Do NOT access context here as the widget may be deactivated after navigation
              } catch (e) {
                // Only show error message if widget is still mounted
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Failed to complete workout: $e'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(88, 48),
            ),
            child: const Text('End workout'),
          ),
        ],
      ),
    );
  }
}
