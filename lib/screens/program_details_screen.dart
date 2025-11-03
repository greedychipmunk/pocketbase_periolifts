import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_plan.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';

class ProgramDetailsScreen extends StatefulWidget {
  final WorkoutPlan program;
  final WorkoutService workoutService;
  final AuthService authService;
  final VoidCallback onAuthError;

  const ProgramDetailsScreen({
    super.key,
    required this.program,
    required this.workoutService,
    required this.authService,
    required this.onAuthError,
  });

  @override
  State<ProgramDetailsScreen> createState() => _ProgramDetailsScreenState();
}

class _ProgramDetailsScreenState extends State<ProgramDetailsScreen> {
  List<Workout> scheduledWorkouts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScheduledWorkouts();
  }

  Future<void> _loadScheduledWorkouts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      List<Workout> workouts = [];
      
      // Load workouts for the next 7 days based on the program schedule
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      for (int i = 0; i < 7; i++) {
        final checkDate = today.add(Duration(days: i));
        final dateKey = _formatDateKey(checkDate);
        
        if (widget.program.schedule.containsKey(dateKey)) {
          final workoutIds = widget.program.schedule[dateKey]!;
          
          for (String workoutId in workoutIds) {
            // Generate a meaningful workout name based on the workout ID pattern
            String workoutName = _generateWorkoutNameFromId(workoutId);
            
            // Create a placeholder workout since the schedule contains template IDs, not real workout documents
            workouts.add(Workout(
              id: workoutId,
              created: DateTime.now(),
              updated: DateTime.now(),
              userId: widget.program.userId,
              name: workoutName,
              description: 'Scheduled workout from ${widget.program.name}',
              scheduledDate: checkDate,
              exercises: [],
            ));
          }
        }
      }
      
      workouts.sort((a, b) => (a.scheduledDate ?? DateTime.now()).compareTo(b.scheduledDate ?? DateTime.now()));
      
      if (mounted) {
        setState(() {
          scheduledWorkouts = workouts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _generateWorkoutNameFromId(String workoutId) {
    // Parse workout type from the generated ID pattern
    if (workoutId.startsWith('push-workout')) {
      return 'Push Day';
    } else if (workoutId.startsWith('pull-workout')) {
      return 'Pull Day';
    } else if (workoutId.startsWith('legs-workout')) {
      return 'Leg Day';
    } else if (workoutId.startsWith('upper-workout')) {
      return 'Upper Body';
    } else if (workoutId.startsWith('lower-workout')) {
      return 'Lower Body';
    } else if (workoutId.startsWith('fullbody-workout')) {
      return 'Full Body';
    } else {
      // Default fallback
      return 'Workout';
    }
  }

  String _getExercisesForWorkoutType(String workoutId) {
    // Return exercises based on workout type
    if (workoutId.startsWith('push-workout')) {
      return 'Bench Press, Overhead Press, Dips, Tricep Extensions';
    } else if (workoutId.startsWith('pull-workout')) {
      return 'Pull-ups, Rows, Deadlifts, Bicep Curls';
    } else if (workoutId.startsWith('legs-workout')) {
      return 'Squats, Lunges, Leg Press, Calf Raises';
    } else if (workoutId.startsWith('upper-workout')) {
      return 'Bench Press, Pull-ups, Overhead Press, Rows';
    } else if (workoutId.startsWith('lower-workout')) {
      return 'Squats, Deadlifts, Lunges, Leg Curls';
    } else if (workoutId.startsWith('fullbody-workout')) {
      return 'Squats, Bench Press, Rows, Overhead Press';
    } else {
      // Default fallback
      return 'Various exercises';
    }
  }

  Future<void> _toggleProgramStatus() async {
    try {
      final updatedProgram = widget.program.copyWith(
        isActive: !widget.program.isActive,
      );
      
      await widget.workoutService.updateProgram(updatedProgram);
      
      if (mounted) {
        setState(() {
          // Update the program status locally
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedProgram.isActive 
                ? 'Program activated successfully!' 
                : 'Program deactivated successfully!'
            ),
          ),
        );
        
        // Go back to refresh the programs list
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating program: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'toggle_status':
                  _toggleProgramStatus();
                  break;
                case 'edit':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit functionality coming soon!')),
                  );
                  break;
                case 'delete':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delete functionality coming soon!')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(widget.program.isActive ? Icons.pause : Icons.play_arrow),
                    const SizedBox(width: 8),
                    Text(widget.program.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgramSchedule(),
            const SizedBox(height: 24),
            _buildScheduleInsights(),
            const SizedBox(height: 24),
            _buildProgramStats(),
            const SizedBox(height: 24),
            _buildScheduledWorkouts(),
          ],
        ),
      ),
    );
  }


  Widget _buildProgramStats() {
    final totalWorkouts = widget.program.schedule.values.expand((i) => i).length;
    final scheduledDays = widget.program.schedule.length;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Program Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Workouts',
                    totalWorkouts.toString(),
                    Icons.fitness_center,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Scheduled Days',
                    scheduledDays.toString(),
                    Icons.calendar_month,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Upcoming',
                    scheduledWorkouts.length.toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Status',
                    widget.program.isActive ? 'Active' : 'Inactive',
                    widget.program.isActive ? Icons.play_circle : Icons.pause_circle,
                    widget.program.isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgramSchedule() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Program Schedule',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.program.isActive 
                        ? Colors.green.withOpacity(0.2) 
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.program.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: widget.program.isActive 
                          ? Colors.green 
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.program.schedule.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline, 
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('No schedule configured for this program'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildWeeklyScheduleView(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyScheduleView() {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weekdayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return Column(
      children: [
        Text(
          'Weekly Training Schedule',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...weekdays.asMap().entries.map((entry) {
          final index = entry.key;
          final fullDayName = entry.value;
          final shortDayName = weekdayAbbr[index];
          final date = startOfWeek.add(Duration(days: index));
          final dateKey = _formatDateKey(date);
          final hasWorkouts = widget.program.schedule.containsKey(dateKey);
          final workoutIds = hasWorkouts ? widget.program.schedule[dateKey]! : <String>[];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: hasWorkouts 
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasWorkouts 
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: hasWorkouts 
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              shortDayName.substring(0, 1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullDayName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: hasWorkouts 
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (hasWorkouts) ...[
                                ...workoutIds.map((workoutId) {
                                  final workoutName = _generateWorkoutNameFromId(workoutId);
                                  final exercises = _getExercisesForWorkoutType(workoutId);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          workoutName,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          exercises,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ] else ...[
                                Text(
                                  'Rest Day',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScheduleInsights() {
    // Analyze the schedule to show patterns
    final scheduleEntries = widget.program.schedule.entries.toList();
    if (scheduleEntries.isEmpty) return const SizedBox.shrink();
    
    // Group by day of week to find patterns
    final dayOfWeekCounts = <int, int>{};
    
    for (final entry in scheduleEntries) {
      try {
        final date = DateTime.parse(entry.key);
        final dayOfWeek = date.weekday;
        
        dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;
      } catch (e) {
        // Skip invalid date formats
        continue;
      }
    }
    
    final mostCommonDay = dayOfWeekCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    // Generate common exercises based on program type
    String commonExercises = _getCommonExercisesForProgram();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Schedule Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Most active day: ${dayNames[mostCommonDay.key]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Common exercises: $commonExercises',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Total scheduled days: ${scheduleEntries.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCommonExercisesForProgram() {
    final programName = widget.program.name.toLowerCase();
    
    if (programName.contains('push pull legs') || programName.contains('ppl')) {
      return 'Bench Press, Pull-ups, Squats';
    } else if (programName.contains('full body')) {
      return 'Squats, Bench Press, Rows';
    } else if (programName.contains('upper lower')) {
      return 'Deadlifts, Overhead Press, Rows';
    } else if (programName.contains('strength')) {
      return 'Deadlifts, Squats, Bench Press';
    } else if (programName.contains('beginner')) {
      return 'Squats, Push-ups, Planks';
    } else {
      // Default common exercises
      return 'Squats, Bench Press, Deadlifts';
    }
  }

  Widget _buildScheduledWorkouts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Next 7 Days',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading) ...[
          const Center(child: CircularProgressIndicator()),
        ] else if (errorMessage != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[300]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error loading workouts: $errorMessage',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else if (scheduledWorkouts.isEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline, 
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('No upcoming workouts scheduled'),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scheduledWorkouts.length,
            itemBuilder: (context, index) {
              return _buildWorkoutCard(scheduledWorkouts[index]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            (workout.scheduledDate?.day ?? 1).toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          workout.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatWorkoutDate(workout.scheduledDate ?? DateTime.now())),
            if (workout.exercises.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '${workout.exercises.length} exercises',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout details coming soon!')),
          );
        },
      ),
    );
  }

  String _formatWorkoutDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final workoutDate = DateTime(date.year, date.month, date.day);

    if (workoutDate == today) {
      return 'Today';
    } else if (workoutDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    }
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
}