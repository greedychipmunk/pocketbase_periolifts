import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_plan.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../widgets/base_layout.dart';
import 'program_details_screen.dart';

class ProgramsScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final AuthService authService;
  final VoidCallback onAuthError;

  const ProgramsScreen({
    super.key, 
    required this.workoutService,
    required this.authService,
    required this.onAuthError,
  });

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  List<WorkoutPlan> programs = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedPrograms = await widget.workoutService.getPrograms();
      if (mounted) {
        setState(() {
          programs = loadedPrograms;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading programs: $e')),
        );
      }
    }
  }

  Future<void> _createProgram() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _CreateProgramDialog(),
    );

    if (result != null) {
      try {
        final program = WorkoutPlan(
          id: '',
          userId: '',
          name: result['name']!,
          description: result['description']!,
          createdAt: DateTime.now(),
          startDate: DateTime.parse(result['startDate']!),
          schedule: {},
        );

        final createdProgram = await widget.workoutService.createProgram(program);
        setState(() {
          programs.add(createdProgram);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Program created successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating program: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return BaseLayout(
        workoutService: widget.workoutService,
        authService: widget.authService,
        onAuthError: widget.onAuthError,
        currentIndex: 1, // Programs tab
        title: 'Programs',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return BaseLayout(
      workoutService: widget.workoutService,
      authService: widget.authService,
      onAuthError: widget.onAuthError,
      currentIndex: 1, // Programs tab
      title: 'Programs',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadPrograms,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _createProgram,
          tooltip: 'Add Program',
        ),
      ],
      child: _buildProgramsList(),
    );
  }

  Widget _buildProgramsList() {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading programs',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPrograms,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (programs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No programs yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first program to get started!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createProgram,
              icon: const Icon(Icons.add),
              label: const Text('Create Program'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPrograms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: programs.length,
        itemBuilder: (context, index) {
          final program = programs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildProgramCard(program),
          );
        },
      ),
    );
  }

  Widget _buildProgramCard(WorkoutPlan program) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _onProgramTap(program),
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
                          program.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (program.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            program.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Active status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: program.isActive ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      program.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: program.isActive ? Colors.green[800] : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Program details
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Started ${DateFormat('MMM d, y').format(program.startDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${program.schedule.isEmpty ? 0 : program.schedule.values.expand((i) => i).length} workouts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Created date
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created ${_formatRelativeTime(program.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _onProgramTap(WorkoutPlan program) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramDetailsScreen(
          program: program,
          workoutService: widget.workoutService,
          authService: widget.authService,
          onAuthError: widget.onAuthError,
        ),
      ),
    );
    
    // If the program was updated (result == true), refresh the programs list
    if (result == true) {
      _loadPrograms();
    }
  }
}

class _CreateProgramDialog extends StatefulWidget {
  const _CreateProgramDialog();

  @override
  State<_CreateProgramDialog> createState() => _CreateProgramDialogState();
}

class _CreateProgramDialogState extends State<_CreateProgramDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Program'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Program Name',
                hintText: 'e.g., Push Pull Legs',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of the program',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('MMM d, y').format(_startDate),
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
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a program name')),
              );
              return;
            }
            
            Navigator.of(context).pop({
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim(),
              'startDate': _startDate.toIso8601String(),
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}