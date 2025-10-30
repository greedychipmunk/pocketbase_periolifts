import 'package:flutter/material.dart';
import '../models/workout.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onStartWorkout;
  final bool isStartable;

  const WorkoutCard({
    Key? key,
    required this.workout,
    this.onTap,
    this.onToggleComplete,
    this.onStartWorkout,
    this.isStartable = true, // Default to true for backward compatibility
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: workout.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(workout.scheduledDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getDateColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  _buildStatusChip(context),
                  const SizedBox(width: 8),
                  // Complete/Uncomplete button
                  IconButton(
                    onPressed: onToggleComplete,
                    icon: Icon(
                      workout.isCompleted 
                        ? Icons.check_circle 
                        : Icons.radio_button_unchecked,
                      color: workout.isCompleted 
                        ? Colors.green 
                        : Colors.grey,
                    ),
                    tooltip: workout.isCompleted 
                      ? 'Mark as incomplete' 
                      : 'Mark as complete',
                  ),
                ],
              ),
              
              if (workout.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  workout.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Exercise count and completion info
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${workout.exercises.length} exercise${workout.exercises.length != 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  if (workout.isCompleted && workout.completedDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.event_available,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Completed ${_formatCompletedDate(workout.completedDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ],
              ),
              
              // Exercise preview (first few exercises)
              if (workout.exercises.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercises:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...workout.exercises.take(3).map((exercise) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Text(
                                '• ${exercise.exerciseName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${exercise.sets.length} set${exercise.sets.length != 1 ? 's' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (workout.exercises.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '... and ${workout.exercises.length - 3} more',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              // Progress indicator for in-progress workouts
              if (workout.isInProgress) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.orange[600]),
                          const SizedBox(width: 4),
                          Text(
                            'In Progress',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workout.progress != null
                            ? 'Exercise ${workout.progress!.currentExerciseIndex + 1}/${workout.exercises.length} • Set ${workout.progress!.currentSetIndex + 1}'
                            : 'Workout in progress',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                        ),
                      ),
                      if (workout.progress?.lastSavedAt != null)
                        Text(
                          'Last saved: ${_formatSavedTime(workout.progress!.lastSavedAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // Action buttons for non-completed workouts
              if (!workout.isCompleted && onStartWorkout != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: isStartable
                      ? ElevatedButton.icon(
                          onPressed: onStartWorkout,
                          icon: Icon(workout.isInProgress ? Icons.play_circle : Icons.play_arrow),
                          label: Text(workout.isInProgress ? 'Resume Workout' : 'Start Workout'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: workout.isInProgress ? Colors.orange : null,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: null, // Disabled for non-startable workouts
                          icon: const Icon(Icons.schedule),
                          label: const Text('Scheduled'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final now = DateTime.now();
    final isUpcoming = workout.scheduledDate.isAfter(now) && !workout.isCompleted;
    final isPast = workout.scheduledDate.isBefore(now);
    
    String label;
    Color backgroundColor;
    Color textColor;
    
    if (workout.isCompleted) {
      label = 'Completed';
      backgroundColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
    } else if (workout.isInProgress) {
      label = 'In Progress';
      backgroundColor = Colors.orange[100]!;
      textColor = Colors.orange[800]!;
    } else if (isUpcoming) {
      label = 'Upcoming';
      backgroundColor = Colors.blue[100]!;
      textColor = Colors.blue[800]!;
    } else if (isPast) {
      label = 'Missed';
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
    } else {
      label = 'Today';
      backgroundColor = Colors.purple[100]!;
      textColor = Colors.purple[800]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getDateColor(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDate = DateTime(
      workout.scheduledDate.year,
      workout.scheduledDate.month,
      workout.scheduledDate.day,
    );
    
    if (workout.isCompleted) {
      return Colors.green[600]!;
    } else if (workoutDate.isAtSameMomentAs(today)) {
      return Colors.purple[600]!;
    } else if (workoutDate.isAfter(today)) {
      return Colors.blue[600]!;
    } else {
      return Colors.orange[600]!;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    
    final workoutDate = DateTime(date.year, date.month, date.day);
    
    if (workoutDate.isAtSameMomentAs(today)) {
      return 'Today, ${_formatTime(date)}';
    } else if (workoutDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow, ${_formatTime(date)}';
    } else if (workoutDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      final daysDiff = workoutDate.difference(today).inDays;
      if (daysDiff > 0 && daysDiff <= 7) {
        return '${_getDayName(date.weekday)}, ${_formatTime(date)}';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }

  String _formatCompletedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedDate = DateTime(date.year, date.month, date.day);
    
    if (completedDate.isAtSameMomentAs(today)) {
      return 'today';
    } else {
      final daysDiff = today.difference(completedDate).inDays;
      if (daysDiff == 1) {
        return 'yesterday';
      } else if (daysDiff < 7) {
        return '$daysDiff days ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday', 
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  String _formatSavedTime(DateTime savedTime) {
    final now = DateTime.now();
    final difference = now.difference(savedTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}