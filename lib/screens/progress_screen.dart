import 'package:flutter/material.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../widgets/base_layout.dart';
import '../widgets/futuristic_widgets.dart';

class ProgressScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final AuthService authService;
  final VoidCallback onAuthError;

  const ProgressScreen({
    Key? key,
    required this.workoutService,
    required this.authService,
    required this.onAuthError,
  }) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true;
  List<Workout> _allWorkouts = [];
  List<WorkoutPlan> _allPrograms = [];
  Map<String, int> _exerciseFrequency = {};
  String _selectedTimeRange = '30'; // Days

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);

    try {
      // Load all workouts and programs
      final now = DateTime.now();
      final daysBack = int.parse(_selectedTimeRange);
      final startDate = now.subtract(Duration(days: daysBack));

      final workouts = await widget.workoutService.getWorkouts(
        startDate: startDate,
        endDate: now,
      );
      
      final programs = await widget.workoutService.getPrograms();

      // Calculate exercise frequency
      final Map<String, int> exerciseCount = {};
      for (final workout in workouts) {
        if (workout.isCompleted) {
          for (final exercise in workout.exercises) {
            exerciseCount[exercise.exerciseName] = 
                (exerciseCount[exercise.exerciseName] ?? 0) + 1;
          }
        }
      }

      setState(() {
        _allWorkouts = workouts;
        _allPrograms = programs;
        _exerciseFrequency = exerciseCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Workout> get _completedWorkouts => 
      _allWorkouts.where((w) => w.isCompleted).toList();

  List<Workout> get _inProgressWorkouts => 
      _allWorkouts.where((w) => w.isInProgress).toList();

  int get _totalSetsCompleted => _completedWorkouts.fold(0, 
      (sum, workout) => sum + workout.exercises.fold(0, 
          (exerciseSum, exercise) => exerciseSum + exercise.sets.length));

  int get _totalExercisesCompleted => _completedWorkouts.fold(0,
      (sum, workout) => sum + workout.exercises.length);

  double get _averageWorkoutDuration {
    final completedWithDates = _completedWorkouts.where(
        (w) => w.completedDate != null).toList();
    
    if (completedWithDates.isEmpty) return 0.0;
    
    // Estimate average workout duration (this would be better with actual tracking)
    return 45.0; // Default estimate in minutes
  }

  List<String> get _topExercises {
    final sortedExercises = _exerciseFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedExercises.take(5).map((e) => e.key).toList();
  }

  Map<String, int> _getWorkoutsByWeek() {
    final Map<String, int> weeklyWorkouts = {};
    final now = DateTime.now();
    
    for (int i = 0; i < 4; i++) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekLabel = 'Week ${i == 0 ? 'This' : '$i ago'}';
      
      final workoutsInWeek = _completedWorkouts.where((workout) {
        final completedDate = workout.completedDate ?? workout.scheduledDate;
        return completedDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
               completedDate.isBefore(weekEnd.add(const Duration(days: 1)));
      }).length;
      
      weeklyWorkouts[weekLabel] = workoutsInWeek;
    }
    
    return weeklyWorkouts;
  }

  String _getStreakText() {
    if (_completedWorkouts.isEmpty) return '0 days';
    
    // Sort by completion date
    final sortedWorkouts = _completedWorkouts.toList()
      ..sort((a, b) => (b.completedDate ?? b.scheduledDate)
          .compareTo(a.completedDate ?? a.scheduledDate));
    
    int streak = 0;
    DateTime? lastWorkoutDate;
    
    for (final workout in sortedWorkouts) {
      final workoutDate = workout.completedDate ?? workout.scheduledDate;
      final dateOnly = DateTime(workoutDate.year, workoutDate.month, workoutDate.day);
      
      if (lastWorkoutDate == null) {
        lastWorkoutDate = dateOnly;
        streak = 1;
      } else {
        final daysDiff = lastWorkoutDate.difference(dateOnly).inDays;
        if (daysDiff == 1) {
          streak++;
          lastWorkoutDate = dateOnly;
        } else {
          break;
        }
      }
    }
    
    return '$streak day${streak != 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      workoutService: widget.workoutService,
      authService: widget.authService,
      onAuthError: widget.onAuthError,
      currentIndex: 3, // Progress tab
      title: 'Progress',
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (value) {
            setState(() {
              _selectedTimeRange = value;
            });
            _loadProgressData();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: '7', child: Text('Last 7 days')),
            const PopupMenuItem(value: '30', child: Text('Last 30 days')),
            const PopupMenuItem(value: '90', child: Text('Last 3 months')),
            const PopupMenuItem(value: '365', child: Text('Last year')),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadProgressData,
        ),
      ],
      child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCards(),
                  const SizedBox(height: 24),
                  _buildWorkoutFrequency(),
                  const SizedBox(height: 24),
                  _buildTopExercises(),
                  const SizedBox(height: 24),
                  _buildProgramProgress(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview (Last ${_selectedTimeRange} days)',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              'Workouts Completed',
              '${_completedWorkouts.length}',
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'In Progress',
              '${_inProgressWorkouts.length}',
              Icons.play_circle,
              Colors.orange,
            ),
            _buildStatCard(
              'Total Sets',
              '$_totalSetsCompleted',
              Icons.fitness_center,
              Colors.blue,
            ),
            _buildStatCard(
              'Current Streak',
              _getStreakText(),
              Icons.local_fire_department,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutFrequency() {
    final weeklyData = _getWorkoutsByWeek();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Weekly Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...weeklyData.entries.map((entry) {
              final maxWorkouts = weeklyData.values.isNotEmpty 
                  ? weeklyData.values.reduce((a, b) => a > b ? a : b)
                  : 1;
              final percentage = maxWorkouts > 0 ? entry.value / maxWorkouts : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${entry.value} workouts'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FuturisticProgressIndicator(
                      value: percentage,
                      height: 6,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopExercises() {
    if (_topExercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Most Frequent Exercises',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._topExercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exerciseName = entry.value;
              final count = _exerciseFrequency[exerciseName] ?? 0;
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(exerciseName),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count times',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramProgress() {
    if (_allPrograms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Program Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._allPrograms.map((program) {
              // Count workouts completed for this program
              final programWorkouts = _completedWorkouts.where((workout) =>
                  workout.description.contains(program.name) ||
                  program.schedule.values.any((workoutIds) =>
                      workoutIds.any((id) => workout.id.contains(id.split('-').first))
                  )
              ).length;

              // Calculate total scheduled workouts in time range
              final now = DateTime.now();
              final daysBack = int.parse(_selectedTimeRange);
              final startDate = now.subtract(Duration(days: daysBack));
              
              int totalScheduled = 0;
              program.schedule.forEach((dateStr, workoutIds) {
                final scheduleDate = DateTime.tryParse(dateStr);
                if (scheduleDate != null && 
                    scheduleDate.isAfter(startDate) && 
                    scheduleDate.isBefore(now)) {
                  totalScheduled += workoutIds.length;
                }
              });

              final completion = totalScheduled > 0 
                  ? (programWorkouts / totalScheduled).clamp(0.0, 1.0)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            program.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: program.isActive 
                                ? Colors.green[100] 
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            program.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: program.isActive 
                                  ? Colors.green[800] 
                                  : Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: completion,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(completion * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$programWorkouts of $totalScheduled workouts completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}