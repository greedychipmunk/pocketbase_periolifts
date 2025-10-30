import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/workout_plan.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';
import 'workout_screen.dart';

class WorkoutPlanCalendarScreen extends StatefulWidget {
  final WorkoutPlan workoutPlan;
  final WorkoutService workoutService;

  const WorkoutPlanCalendarScreen({
    Key? key,
    required this.workoutPlan,
    required this.workoutService,
  }) : super(key: key);

  @override
  State<WorkoutPlanCalendarScreen> createState() =>
      _WorkoutPlanCalendarScreenState();
}

class _WorkoutPlanCalendarScreenState extends State<WorkoutPlanCalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Workout>> _workouts = {};
  List<Workout>? _selectedDayWorkouts;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.workoutPlan.startDate;
    _selectedDay = _focusedDay;
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => isLoading = true);
    try {
      Map<DateTime, List<Workout>> workoutMap = {};

      for (var entry in widget.workoutPlan.schedule.entries) {
        final date = DateTime.parse(entry.key);
        List<Workout> dayWorkouts = [];

        for (String workoutId in entry.value) {
          try {
            final workout = await widget.workoutService.getWorkout(workoutId);
            if (workout != null) {
              dayWorkouts.add(workout);
            }
          } catch (e) {
            print('Error loading workout $workoutId: $e');
          }
        }

        if (dayWorkouts.isNotEmpty) {
          workoutMap[date] = dayWorkouts;
        }
      }

      setState(() {
        _workouts = workoutMap;
        if (_selectedDay != null) {
          _selectedDayWorkouts = _workouts[_selectedDay];
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error loading workouts: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedDayWorkouts = _workouts[selectedDay];
    });
  }

  Future<void> _addWorkoutToDay(DateTime day) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WorkoutScreen(workoutService: widget.workoutService),
      ),
    );

    if (result != null && result is Workout) {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      Map<String, List<String>> newSchedule = Map.from(
        widget.workoutPlan.schedule,
      );

      if (!newSchedule.containsKey(dateStr)) {
        newSchedule[dateStr] = [];
      }
      newSchedule[dateStr]!.add(result.id);

      try {
        await widget.workoutService.updateWorkoutPlanSchedule(
          widget.workoutPlan.id,
          newSchedule,
        );
        await _loadWorkouts();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding workout: $e')));
      }
    }
  }

  Future<void> _removeWorkoutFromDay(String workoutId) async {
    if (_selectedDay == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    Map<String, List<String>> newSchedule = Map.from(
      widget.workoutPlan.schedule,
    );

    if (newSchedule.containsKey(dateStr)) {
      newSchedule[dateStr]!.remove(workoutId);
      if (newSchedule[dateStr]!.isEmpty) {
        newSchedule.remove(dateStr);
      }

      try {
        await widget.workoutService.updateWorkoutPlanSchedule(
          widget.workoutPlan.id,
          newSchedule,
        );
        await _loadWorkouts();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing workout: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutPlan.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit plan
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: widget.workoutPlan.startDate,
            lastDay: DateTime(widget.workoutPlan.startDate.year + 1),
            calendarFormat: CalendarFormat.month,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                shape: BoxShape.circle,
              ),
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: (day) => _workouts[day] ?? [],
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Select a day to view workouts'))
                : _buildWorkoutList(),
          ),
        ],
      ),
      floatingActionButton: _selectedDay == null
          ? null
          : FloatingActionButton(
              onPressed: () => _addWorkoutToDay(_selectedDay!),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildWorkoutList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final workouts = _selectedDayWorkouts ?? [];
    if (workouts.isEmpty) {
      return const Center(child: Text('No workouts scheduled for this day'));
    }

    return ListView.builder(
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return Dismissible(
          key: Key(workout.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => _removeWorkoutFromDay(workout.id),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: ListTile(
              title: Text(workout.name),
              subtitle: Text(workout.description),
              trailing: workout.isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                // TODO: View/edit workout details
              },
            ),
          ),
        );
      },
    );
  }
}

// TODO: Before using this screen, ensure:
// 1. The Appwrite 'workouts' collection has a 'description' attribute (String, required: false, default: '')
// 2. Test the calendar with actual workout data
// 3. Implement workout editing functionality when a workout is tapped
