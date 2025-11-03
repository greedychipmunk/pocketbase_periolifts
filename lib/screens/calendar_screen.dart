import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../models/workout.dart';
import '../widgets/base_layout.dart';
import 'workout_tracking_screen_riverpod.dart';

class CalendarScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final AuthService authService;
  final VoidCallback onAuthError;

  const CalendarScreen({
    Key? key,
    required this.workoutService,
    required this.authService,
    required this.onAuthError,
  }) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Workout>> _workouts = {};
  List<Workout> _selectedDayWorkouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    
    try {
      // Load workouts from past 6 months to future 1 month
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 6, 1);
      final endDate = DateTime(now.year, now.month + 1, 31);
      
      final workoutsResult = await widget.workoutService.getWorkouts();
      
      if (workoutsResult.isError) {
        throw Exception('Failed to load workouts: ${workoutsResult.error}');
      }
      
      final allWorkouts = workoutsResult.data!;
      
      // Filter workouts by date range locally
      final workouts = allWorkouts.where((workout) {
        final workoutDate = workout.completedDate ?? workout.scheduledDate;
        if (workoutDate == null) return false;
        return workoutDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               workoutDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      // Group workouts by date
      final Map<DateTime, List<Workout>> workoutsByDate = {};
      
      for (final workout in workouts) {
        final scheduledDate = workout.scheduledDate ?? DateTime.now();
        final dateKey = DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
        );
        
        if (!workoutsByDate.containsKey(dateKey)) {
          workoutsByDate[dateKey] = [];
        }
        workoutsByDate[dateKey]!.add(workout);
      }

      setState(() {
        _workouts = workoutsByDate;
        _isLoading = false;
        _updateSelectedDayWorkouts();
      });
    } catch (e) {
      print('Error loading workouts for calendar: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateSelectedDayWorkouts() {
    if (_selectedDay != null) {
      final dateKey = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );
      _selectedDayWorkouts = _workouts[dateKey] ?? [];
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _updateSelectedDayWorkouts();
    });
  }

  List<Workout> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _workouts[dateKey] ?? [];
  }

  Color _getWorkoutStatusColor(Workout workout) {
    if (workout.isCompleted) {
      return Colors.green;
    } else if (workout.isInProgress) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  IconData _getWorkoutStatusIcon(Workout workout) {
    if (workout.isCompleted) {
      return Icons.check_circle;
    } else if (workout.isInProgress) {
      return Icons.play_circle;
    } else {
      return Icons.radio_button_unchecked;
    }
  }

  String _getWorkoutStatusText(Workout workout) {
    if (workout.isCompleted) {
      return 'Completed';
    } else if (workout.isInProgress) {
      return 'In Progress';
    } else {
      return 'Scheduled';
    }
  }

  void _startOrViewWorkout(Workout workout) async {
    if (workout.isCompleted) {
      // Show workout summary/details dialog
      _showWorkoutSummary(workout);
    } else {
      // Start or resume the workout
      try {
        Workout actualWorkout = workout;
        if (workout.id.contains('-workout-')) {
          final createResult = await widget.workoutService.createWorkout(workout);
          if (createResult.isError) {
            throw Exception('Failed to create workout: ${createResult.error}');
          }
          actualWorkout = createResult.data!;
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutTrackingScreenRiverpod(
              workout: actualWorkout,
              workoutService: widget.workoutService,
              authService: widget.authService,
              onAuthError: widget.onAuthError,
            ),
          ),
        );

        if (result == true) {
          _loadWorkouts(); // Refresh calendar data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting workout: $e')),
          );
        }
      }
    }
  }

  void _showWorkoutSummary(Workout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(workout.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completed: ${_formatDate((workout.completedDate ?? workout.scheduledDate) ?? DateTime.now())}'),
            const SizedBox(height: 12),
            Text('Exercises: ${workout.exercises.length}'),
            const SizedBox(height: 8),
            Text('Total Sets: ${workout.exercises.fold(0, (sum, e) => sum + e.sets.length)}'),
            if (workout.exercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Exercises:', style: Theme.of(context).textTheme.titleSmall),
              ...workout.exercises.map((exercise) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• ${exercise.exerciseName}'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateKey = DateTime(date.year, date.month, date.day);

    if (dateKey == today) {
      return 'Today';
    } else if (dateKey == yesterday) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      workoutService: widget.workoutService,
      authService: widget.authService,
      onAuthError: widget.onAuthError,
      currentIndex: 2, // Calendar tab
      title: 'Workout Calendar',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadWorkouts,
        ),
      ],
      child: Column(
        children: [
          TableCalendar<Workout>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return _selectedDay != null && isSameDay(_selectedDay!, day);
            },
            calendarFormat: CalendarFormat.month,
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.red[400]),
              holidayTextStyle: TextStyle(color: Colors.red[400]),
              markerDecoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                
                return Container(
                  margin: const EdgeInsets.only(top: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(3).map((event) {
                      final workout = event as Workout;
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _getWorkoutStatusColor(workout),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildSelectedDayWorkouts(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayWorkouts() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedDay == null) {
      return const Center(
        child: Text('Select a day to view workouts'),
      );
    }

    if (_selectedDayWorkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No workouts on ${_formatDate(_selectedDay!)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedDayWorkouts.length,
      itemBuilder: (context, index) {
        final workout = _selectedDayWorkouts[index];
        final statusColor = _getWorkoutStatusColor(workout);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(
                _getWorkoutStatusIcon(workout),
                color: statusColor,
              ),
            ),
            title: Text(
              workout.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getWorkoutStatusText(workout)),
                const SizedBox(height: 4),
                Text(
                  '${workout.exercises.length} exercises • '
                  '${workout.exercises.fold(0, (sum, e) => sum + e.sets.length)} sets',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Icon(
              workout.isCompleted ? Icons.visibility : Icons.play_arrow,
              color: statusColor,
            ),
            onTap: () => _startOrViewWorkout(workout),
          ),
        );
      },
    );
  }
}