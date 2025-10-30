import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../state/workout_tracking_state.dart';

/// Screen that displays a comprehensive summary after workout completion
class WorkoutSummaryScreen extends StatelessWidget {
  final Workout workout;
  final Duration workoutDuration;
  final WorkoutTrackingState trackingState;

  const WorkoutSummaryScreen({
    super.key,
    required this.workout,
    required this.workoutDuration,
    required this.trackingState,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // appBar: AppBar(
      //   title: const Text('Workout Complete'),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   automaticallyImplyLeading: false,
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildOverviewCard(context),
            const SizedBox(height: 16),
            _buildExerciseBreakdown(context),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final hours = workoutDuration.inHours;
    final minutes = workoutDuration.inMinutes.remainder(60);
    final seconds = workoutDuration.inSeconds.remainder(60);

    final durationText = hours > 0
        ? '${hours}h ${minutes}m ${seconds}s'
        : minutes > 0
        ? '${minutes}m ${seconds}s'
        : '${seconds}s';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.timer,
                    label: 'Duration',
                    value: durationText,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.fitness_center,
                    label: 'Exercises',
                    value: '${workout.exercises.length}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.done_all,
                    label: 'Sets Completed',
                    value: '${trackingState.totalCompletedSetsCount}',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.trending_up,
                    label: 'Completion',
                    value: '${(trackingState.workoutProgress * 100).toInt()}%',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseBreakdown(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercise Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...workout.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              final isCompleted =
                  trackingState.exerciseStatuses[index] ==
                  ExerciseStatus.completed;
              final completedSetsCount = trackingState.completedSets[index]
                  .where((completed) => completed)
                  .length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.fitness_center,
                        color: isCompleted ? Colors.white : Colors.grey,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.exerciseName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$completedSetsCount/${exercise.sets.length} sets completed',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Complete',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Return to the previous screen (likely calendar or workout list)
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.home),
            label: const Text('Back to Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
