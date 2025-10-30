import 'package:flutter/material.dart';
import '../models/workout_session.dart';

class WorkoutSessionCard extends StatelessWidget {
  final WorkoutSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onStart;
  final VoidCallback? onResume;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const WorkoutSessionCard({
    Key? key,
    required this.session,
    this.isActive = false,
    required this.onTap,
    this.onStart,
    this.onResume,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isActive ? 8 : 2,
      color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
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
              _buildDescription(context),
              const SizedBox(height: 12),
              _buildProgressInfo(context),
              const SizedBox(height: 12),
              _buildDateInfo(context),
              if (session.status != WorkoutSessionStatus.planned) ...[
                const SizedBox(height: 12),
                _buildDurationInfo(context),
              ],
              const SizedBox(height: 16),
              _buildActionButtons(context),
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
                session.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusChip(context),
            ],
          ),
        ),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ACTIVE',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            if (session.status == WorkoutSessionStatus.planned) ...[
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    Color textColor;
    IconData icon;

    switch (session.status) {
      case WorkoutSessionStatus.planned:
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.schedule;
        break;
      case WorkoutSessionStatus.inProgress:
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.play_circle_filled;
        break;
      case WorkoutSessionStatus.completed:
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            _formatStatus(session.status),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    if (session.description.isEmpty) return const SizedBox.shrink();

    return Text(
      session.description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressInfo(BuildContext context) {
    return Column(
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
              '${session.completedExercises}/${session.totalExercises} exercises',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Text(
              '${session.completedSets}/${session.totalSets} sets',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: session.progressPercentage / 100,
          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            session.isCompleted
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${session.progressPercentage.toInt()}% complete',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        if (session.scheduledDate != null) ...[
          Text(
            'Scheduled: ${_formatDateTime(session.scheduledDate!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else ...[
          Text(
            'Created: ${_formatDateTime(session.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildDurationInfo(BuildContext context) {
    final duration = session.duration;
    if (duration == null) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.timer,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Duration: ${_formatDuration(duration)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (onStart != null) ...[
          ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (onResume != null) ...[
          ElevatedButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_circle_filled, size: 18),
            label: const Text('Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('View'),
          ),
        ),
      ],
    );
  }

  String _formatStatus(WorkoutSessionStatus status) {
    switch (status) {
      case WorkoutSessionStatus.planned:
        return 'Planned';
      case WorkoutSessionStatus.inProgress:
        return 'In Progress';
      case WorkoutSessionStatus.completed:
        return 'Completed';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (sessionDate.isAtSameMomentAs(today)) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (sessionDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else if (sessionDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Tomorrow ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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