import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_session.dart';
import '../providers/workout_session_providers.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';

class WorkoutSessionFormScreen extends ConsumerStatefulWidget {
  final WorkoutSession? session; // null for create, non-null for edit

  const WorkoutSessionFormScreen({
    Key? key,
    this.session,
  }) : super(key: key);

  @override
  ConsumerState<WorkoutSessionFormScreen> createState() => _WorkoutSessionFormScreenState();
}

class _WorkoutSessionFormScreenState extends ConsumerState<WorkoutSessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<WorkoutSessionExercise> _exercises = [];
  DateTime? _scheduledDate;
  bool _isLoading = false;
  String? _error;

  bool get isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (isEditing) {
      final session = widget.session!;
      _nameController.text = session.name;
      _descriptionController.text = session.description;
      _scheduledDate = session.scheduledDate;
      _exercises = List.from(session.exercises);
    } else {
      _scheduledDate = DateTime.now().add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Session' : 'Create Session'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSession,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              InlineError(
                message: _error!,
                onRetry: () => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
            ],
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildScheduleSection(),
            const SizedBox(height: 24),
            _buildExercisesSection(),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Session Name',
                hintText: 'e.g., Push Day, Full Body, etc.',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a session name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add notes or details about this session',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Scheduled Date & Time'),
              subtitle: Text(
                _scheduledDate != null
                    ? _formatDateTime(_scheduledDate!)
                    : 'Not scheduled',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scheduledDate != null)
                    IconButton(
                      onPressed: () => setState(() => _scheduledDate = null),
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear schedule',
                    ),
                  IconButton(
                    onPressed: _selectDateTime,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Select date & time',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Exercises',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_exercises.length} exercises',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_exercises.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 48,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No exercises added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap the button below to add exercises',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildExerciseCard(index),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(int index) {
    final exercise = _exercises[index];
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editExercise(index);
                        break;
                      case 'delete':
                        _deleteExercise(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
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
            ),
            const SizedBox(height: 8),
            Text(
              '${exercise.sets.length} sets',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: exercise.sets.asMap().entries.map((entry) {
                final setIndex = entry.key;
                final set = entry.value;
                return Chip(
                  label: Text(
                    '${setIndex + 1}: ${set.targetReps} × ${set.targetWeight}kg',
                    style: const TextStyle(fontSize: 12),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addExercise() {
    _showExerciseDialog();
  }

  void _editExercise(int index) {
    _showExerciseDialog(exerciseIndex: index);
  }

  void _deleteExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _showExerciseDialog({int? exerciseIndex}) {
    final isEditing = exerciseIndex != null;
    final exercise = isEditing ? _exercises[exerciseIndex] : null;
    
    final nameController = TextEditingController(text: exercise?.exerciseName ?? '');
    final sets = List<WorkoutSessionSet>.from(exercise?.sets ?? [
      WorkoutSessionSet(
        setId: '1',
        setNumber: 1,
        targetReps: 8,
        targetWeight: 0.0,
        restTime: const Duration(seconds: 90),
      ),
    ]);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Exercise' : 'Add Exercise'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name',
                    hintText: 'e.g., Bench Press, Squats',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sets (${sets.length})',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          sets.add(WorkoutSessionSet(
                            setId: (sets.length + 1).toString(),
                            setNumber: sets.length + 1,
                            targetReps: 8,
                            targetWeight: 0.0,
                            restTime: const Duration(seconds: 90),
                          ));
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: sets.length,
                    itemBuilder: (context, index) => _buildSetEditor(
                      sets[index],
                      (updatedSet) => setState(() => sets[index] = updatedSet),
                      () => setState(() => sets.removeAt(index)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an exercise name')),
                  );
                  return;
                }

                final newExercise = WorkoutSessionExercise(
                  exerciseId: exercise?.exerciseId ?? nameController.text.toLowerCase().replaceAll(' ', '-'),
                  exerciseName: nameController.text.trim(),
                  sets: sets,
                );

                this.setState(() {
                  if (isEditing) {
                    _exercises[exerciseIndex] = newExercise;
                  } else {
                    _exercises.add(newExercise);
                  }
                });

                Navigator.of(context).pop();
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetEditor(
    WorkoutSessionSet set,
    Function(WorkoutSessionSet) onUpdate,
    VoidCallback onDelete,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Text(
              '${set.setNumber}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: set.targetReps.toString(),
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final reps = int.tryParse(value) ?? set.targetReps;
                  onUpdate(set.copyWith(targetReps: reps));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: set.targetWeight.toString(),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final weight = double.tryParse(value) ?? set.targetWeight;
                  onUpdate(set.copyWith(targetWeight: weight));
                },
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final session = WorkoutSession(
        sessionId: widget.session?.sessionId ?? '',
        userId: widget.session?.userId ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        exercises: _exercises,
        scheduledDate: _scheduledDate,
        createdAt: widget.session?.createdAt ?? now,
        updatedAt: now,
      );

      if (isEditing) {
        await ref.read(workoutSessionProvider(widget.session!.sessionId).notifier).updateSession(session);
      } else {
        const filter = WorkoutSessionsFilter();
        await ref.read(workoutSessionsProvider(filter).notifier).createSession(session);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session ${isEditing ? 'updated' : 'created'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (sessionDate.isAtSameMomentAs(today)) {
      dateStr = 'Today';
    } else if (sessionDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      dateStr = 'Tomorrow';
    } else if (sessionDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$dateStr at $hour:$minute $period';
  }
}