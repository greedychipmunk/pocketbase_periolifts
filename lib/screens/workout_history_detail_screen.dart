import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import '../models/workout_history.dart';
import '../providers/workout_history_providers.dart';
import '../providers/units_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';

class WorkoutHistoryDetailScreen extends ConsumerStatefulWidget {
  final WorkoutHistoryEntry entry;

  const WorkoutHistoryDetailScreen({
    Key? key,
    required this.entry,
  }) : super(key: key);

  @override
  ConsumerState<WorkoutHistoryDetailScreen> createState() => _WorkoutHistoryDetailScreenState();
}

class _WorkoutHistoryDetailScreenState extends ConsumerState<WorkoutHistoryDetailScreen> {
  late TextEditingController _notesController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.entry.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(workoutHistoryEntryProvider(widget.entry.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.name),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNotes,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() => _isEditing = false);
                _notesController.text = widget.entry.notes;
              },
            ),
        ],
      ),
      body: entryAsync.when(
        data: (entry) => _buildContent(entry),
        loading: () => const LoadingIndicator(message: 'Loading workout details...'),
        error: (error, stackTrace) => ErrorMessage(
          message: error.toString(),
          onRetry: () => ref.invalidate(workoutHistoryEntryProvider(widget.entry.id)),
        ),
      ),
    );
  }

  Widget _buildContent(WorkoutHistoryEntry entry) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(entry),
          const SizedBox(height: 24),
          _buildMetrics(entry),
          const SizedBox(height: 24),
          _buildNotes(entry),
          const SizedBox(height: 24),
          _buildExercises(entry),
        ],
      ),
    );
  }

  Widget _buildHeader(WorkoutHistoryEntry entry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(entry.status),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Scheduled', 
                entry.scheduledDate != null ? _formatDateTime(entry.scheduledDate!) : 'Not scheduled'),
            if (entry.startedAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.play_arrow, 'Started', _formatDateTime(entry.startedAt!)),
            ],
            if (entry.completedAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.check_circle, 'Completed', _formatDateTime(entry.completedAt!)),
            ],
            if (entry.duration != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.timer, 'Duration', _formatDuration(entry.duration!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(WorkoutHistoryStatus status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
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

  Widget _buildMetrics(WorkoutHistoryEntry entry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Exercises',
                    entry.exercises.length.toString(),
                    Icons.fitness_center,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Total Sets',
                    entry.totalSets.toString(),
                    Icons.repeat,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Reps',
                    entry.totalReps.toString(),
                    Icons.numbers,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: provider.Consumer<UnitsProvider>(
                    builder: (context, unitsProvider, child) {
                      return _buildMetricCard(
                        'Weight Lifted',
                        unitsProvider.formatWeight(entry.totalWeightLifted, decimals: 0),
                        Icons.monitor_weight,
                        Colors.purple,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressBar(entry),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(WorkoutHistoryEntry entry) {
    final completedSets = entry.exercises.fold(0, (sum, ex) => sum + ex.completedSets);
    final progress = entry.totalSets > 0 ? completedSets / entry.totalSets : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completion Progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$completedSets / ${entry.totalSets} sets',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            progress == 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% complete',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(WorkoutHistoryEntry entry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditing)
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Add your notes about this workout...',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  entry.notes.isEmpty ? 'No notes added' : entry.notes,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: entry.notes.isEmpty ? FontStyle.italic : null,
                    color: entry.notes.isEmpty 
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercises(WorkoutHistoryEntry entry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercises',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...entry.exercises.map((exercise) => _buildExerciseCard(exercise)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutHistoryExercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${exercise.completedSets}/${exercise.totalSets} sets',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildExerciseStats(exercise),
          const SizedBox(height: 12),
          _buildSets(exercise),
        ],
      ),
    );
  }

  Widget _buildExerciseStats(WorkoutHistoryExercise exercise) {
    return provider.Consumer<UnitsProvider>(
      builder: (context, unitsProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildExerciseStat('Max Weight', unitsProvider.formatWeight(exercise.maxWeight, decimals: 1)),
            ),
            Expanded(
              child: _buildExerciseStat('Avg Weight', unitsProvider.formatWeight(exercise.avgWeight, decimals: 1)),
            ),
            Expanded(
              child: _buildExerciseStat('Volume', unitsProvider.formatWeight(exercise.totalVolume, decimals: 0)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExerciseStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildSets(WorkoutHistoryExercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sets',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...exercise.sets.asMap().entries.map((entry) {
          final index = entry.key;
          final set = entry.value;
          return _buildSetRow(index + 1, set);
        }),
      ],
    );
  }

  Widget _buildSetRow(int setNumber, WorkoutHistorySet set) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: set.completed 
                  ? Colors.green.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: set.completed 
                    ? Colors.green 
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: set.completed
                  ? const Icon(Icons.check, color: Colors.green, size: 16)
                  : Text(
                      '$setNumber',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: provider.Consumer<UnitsProvider>(
              builder: (context, unitsProvider, child) {
                return Text(
                  '${set.reps} reps × ${unitsProvider.formatWeight(set.weight)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: set.completed 
                        ? null 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    decoration: set.completed ? null : TextDecoration.lineThrough,
                  ),
                );
              },
            ),
          ),
          if (set.restTime != null)
            Text(
              'Rest: ${_formatDuration(set.restTime!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: set.completed 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: provider.Consumer<UnitsProvider>(
              builder: (context, unitsProvider, child) {
                return Text(
                  unitsProvider.formatWeight(set.volume, decimals: 0),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: set.completed ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNotes() async {
    final updatedEntry = widget.entry.copyWith(notes: _notesController.text);
    
    try {
      final notifier = ref.read(workoutHistoryEntryProvider(widget.entry.id).notifier);
      await notifier.updateEntry(updatedEntry);
      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;
    
    if (difference == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference == 1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else if (difference < 7) {
      return '$difference days ago at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}