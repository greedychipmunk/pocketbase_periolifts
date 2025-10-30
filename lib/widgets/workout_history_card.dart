import 'package:flutter/material.dart';
import '../models/workout_history.dart';

class WorkoutHistoryCard extends StatelessWidget {
  final WorkoutHistoryEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const WorkoutHistoryCard({
    Key? key,
    required this.entry,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              if (entry.notes.isNotEmpty) ...[
                Text(
                  entry.notes,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              _buildMetrics(context),
              if (entry.exercises.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildExercisePreview(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(entry.completedAt ?? entry.scheduledDate ?? DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(context),
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            iconSize: 20,
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (entry.status) {
      case WorkoutHistoryStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Completed';
        break;
      case WorkoutHistoryStatus.inProgress:
        color = Colors.orange;
        icon = Icons.play_circle;
        label = 'In Progress';
        break;
      case WorkoutHistoryStatus.planned:
        color = Colors.blue;
        icon = Icons.schedule;
        label = 'Planned';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetric(
          context,
          'Duration',
          entry.duration != null ? _formatDuration(entry.duration!) : 'N/A',
          Icons.timer,
        ),
        _buildMetric(
          context,
          'Exercises',
          entry.exercises.length.toString(),
          Icons.fitness_center,
        ),
        _buildMetric(
          context,
          'Sets',
          entry.totalSets.toString(),
          Icons.repeat,
        ),
        _buildMetric(
          context,
          'Weight',
          '${entry.totalWeightLifted.toStringAsFixed(0)}kg',
          Icons.monitor_weight,
        ),
      ],
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildExercisePreview(BuildContext context) {
    final exerciseCount = entry.exercises.length;
    final displayCount = exerciseCount > 3 ? 3 : exerciseCount;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...entry.exercises.take(displayCount).map((exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${exercise.exerciseName} (${exercise.completedSets}/${exercise.totalSets} sets)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
          if (exerciseCount > 3) ...[
            const SizedBox(height: 4),
            Text(
              '... and ${exerciseCount - 3} more',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}