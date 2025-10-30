import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import '../models/workout_history.dart';
import '../providers/workout_history_providers.dart';
import '../providers/units_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';

class WorkoutStatsScreen extends ConsumerStatefulWidget {
  const WorkoutStatsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutStatsScreen> createState() => _WorkoutStatsScreenState();
}

class _WorkoutStatsScreenState extends ConsumerState<WorkoutStatsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  TimePeriod _selectedPeriod = TimePeriod.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setDefaultDateRange();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case TimePeriod.week:
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case TimePeriod.month:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case TimePeriod.quarter:
        _startDate = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        _endDate = now;
        break;
      case TimePeriod.year:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
    }
  }

  WorkoutHistoryStatsFilter _getStatsFilter() {
    return WorkoutHistoryStatsFilter(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  WorkoutPatternsFilter _getPatternsFilter() {
    return WorkoutPatternsFilter(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.analytics)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
            Tab(text: 'Patterns', icon: Icon(Icons.pattern)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildProgressTab(),
          _buildPatternsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final statsFilter = _getStatsFilter();
    final statsAsync = ref.watch(workoutHistoryStatsProvider(statsFilter));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workoutHistoryStatsProvider(statsFilter));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => _buildOverviewContent(stats),
            loading: () => const LoadingIndicator(message: 'Loading statistics...'),
            error: (error, stackTrace) => ErrorMessage(
              message: error.toString(),
              onRetry: () => ref.invalidate(workoutHistoryStatsProvider(statsFilter)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    final statsFilter = _getStatsFilter();
    final statsAsync = ref.watch(workoutHistoryStatsProvider(statsFilter));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workoutHistoryStatsProvider(statsFilter));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          statsAsync.when(
            data: (stats) => _buildProgressContent(stats),
            loading: () => const LoadingIndicator(message: 'Loading progress...'),
            error: (error, stackTrace) => ErrorMessage(
              message: error.toString(),
              onRetry: () => ref.invalidate(workoutHistoryStatsProvider(statsFilter)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsTab() {
    final patternsFilter = _getPatternsFilter();
    final patternsAsync = ref.watch(workoutPatternsProvider(patternsFilter));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workoutPatternsProvider(patternsFilter));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          patternsAsync.when(
            data: (patterns) => _buildPatternsContent(patterns),
            loading: () => const LoadingIndicator(message: 'Loading patterns...'),
            error: (error, stackTrace) => ErrorMessage(
              message: error.toString(),
              onRetry: () => ref.invalidate(workoutPatternsProvider(patternsFilter)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TimePeriod.values.map((period) {
                final isSelected = _selectedPeriod == period;
                return FilterChip(
                  label: Text(_getPeriodLabel(period)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriod = period;
                        _setDefaultDateRange();
                      });
                      _refreshData();
                    }
                  },
                );
              }).toList(),
            ),
            if (_startDate != null && _endDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewContent(WorkoutHistoryStats stats) {
    return Column(
      children: [
        _buildStatsCards(stats),
        const SizedBox(height: 16),
        _buildCompletionChart(stats),
        const SizedBox(height: 16),
        _buildExerciseFrequency(stats),
      ],
    );
  }

  Widget _buildStatsCards(WorkoutHistoryStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Workouts',
                stats.totalWorkouts.toString(),
                Icons.fitness_center,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                stats.completedWorkouts.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: provider.Consumer<UnitsProvider>(
                builder: (context, unitsProvider, child) {
                  return _buildStatCard(
                    'Weight Lifted',
                    unitsProvider.formatWeight(stats.totalWeightLifted, decimals: 0),
                    Icons.monitor_weight,
                    Colors.purple,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Time',
                _formatDuration(stats.totalDuration),
                Icons.timer,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionChart(WorkoutHistoryStats stats) {
    final completionRate = stats.completionRate / 100;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completion Rate',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    CircularProgressIndicator(
                      value: completionRate,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completionRate > 0.8 ? Colors.green : 
                        completionRate > 0.5 ? Colors.orange : Colors.red,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${stats.completionRate.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Complete',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      stats.completedWorkouts.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Completed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      (stats.totalWorkouts - stats.completedWorkouts).toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Missed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseFrequency(WorkoutHistoryStats stats) {
    if (stats.exerciseFrequency.isEmpty) return const SizedBox.shrink();

    final sortedExercises = stats.exerciseFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxFrequency = sortedExercises.first.value.toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercise Frequency',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...sortedExercises.take(8).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}x',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: entry.value / maxFrequency,
                    backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContent(WorkoutHistoryStats stats) {
    return Column(
      children: [
        _buildPersonalRecords(stats),
        const SizedBox(height: 16),
        _buildVolumeProgress(stats),
        const SizedBox(height: 16),
        _buildConsistencyMetrics(stats),
      ],
    );
  }

  Widget _buildPersonalRecords(WorkoutHistoryStats stats) {
    // Sort exercises by max weight
    final topExercises = stats.exerciseProgress
        .where((exercise) => exercise.maxWeight > 0)
        .toList()
      ..sort((a, b) => b.maxWeight.compareTo(a.maxWeight));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Records',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (topExercises.isEmpty)
              Text(
                'No personal records yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            else
              ...topExercises.take(5).map((exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise.exerciseName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: provider.Consumer<UnitsProvider>(
                        builder: (context, unitsProvider, child) {
                          return Text(
                            unitsProvider.formatWeight(exercise.maxWeight, decimals: 1),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeProgress(WorkoutHistoryStats stats) {
    // Sort exercises by total volume
    final topVolumeExercises = stats.exerciseProgress
        .where((exercise) => exercise.totalVolume > 0)
        .toList()
      ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volume Leaders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (topVolumeExercises.isEmpty)
              Text(
                'No volume data yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            else
              ...topVolumeExercises.take(5).map((exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            exercise.exerciseName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        provider.Consumer<UnitsProvider>(
                          builder: (context, unitsProvider, child) {
                            return Text(
                              unitsProvider.formatWeight(exercise.totalVolume, decimals: 0),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    provider.Consumer<UnitsProvider>(
                      builder: (context, unitsProvider, child) {
                        return Text(
                          '${exercise.totalReps} reps × ${unitsProvider.formatWeight(exercise.avgWeight, decimals: 1)} avg',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildConsistencyMetrics(WorkoutHistoryStats stats) {
    final avgWorkoutsPerWeek = stats.totalWorkouts / 
        ((_endDate!.difference(_startDate!).inDays + 1) / 7);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consistency Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Average Duration', _formatDuration(stats.averageDuration)),
            const SizedBox(height: 12),
            _buildMetricRow('Workouts per Week', avgWorkoutsPerWeek.toStringAsFixed(1)),
            const SizedBox(height: 12),
            _buildMetricRow('Success Rate', '${stats.completionRate.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternsContent(Map<String, dynamic> patterns) {
    return Column(
      children: [
        _buildStreakInfo(patterns),
        const SizedBox(height: 16),
        _buildWeeklyPattern(patterns),
        const SizedBox(height: 16),
        _buildActivitySummary(patterns),
      ],
    );
  }

  Widget _buildStreakInfo(Map<String, dynamic> patterns) {
    final currentStreak = patterns['currentStreak'] ?? 0;
    final longestStreak = patterns['longestStreak'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Streaks',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStreakCard('Current Streak', currentStreak, Icons.local_fire_department, Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStreakCard('Longest Streak', longestStreak, Icons.emoji_events, Colors.amber),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(String title, int days, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            days.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPattern(Map<String, dynamic> patterns) {
    final weeklyPattern = patterns['weeklyPattern'] as Map<int, int>? ?? {};
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxWorkouts = weeklyPattern.values.isEmpty ? 1 : weeklyPattern.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Pattern',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final dayOfWeek = index + 1;
                final workouts = weeklyPattern[dayOfWeek] ?? 0;
                final height = maxWorkouts > 0 ? (workouts / maxWorkouts) * 60 : 0.0;
                
                return Column(
                  children: [
                    Container(
                      height: 60,
                      width: 24,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: height,
                        width: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      workouts.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weekdays[index],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummary(Map<String, dynamic> patterns) {
    final totalWorkoutDays = patterns['totalWorkoutDays'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Total Active Days', totalWorkoutDays.toString()),
            const SizedBox(height: 12),
            _buildMetricRow('Period Length', '${_endDate!.difference(_startDate!).inDays + 1} days'),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      _refreshData();
    }
  }

  void _refreshData() {
    final statsFilter = _getStatsFilter();
    final patternsFilter = _getPatternsFilter();
    
    ref.invalidate(workoutHistoryStatsProvider(statsFilter));
    ref.invalidate(workoutPatternsProvider(patternsFilter));
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.week:
        return 'This Week';
      case TimePeriod.month:
        return 'This Month';
      case TimePeriod.quarter:
        return 'This Quarter';
      case TimePeriod.year:
        return 'This Year';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

enum TimePeriod {
  week,
  month,
  quarter,
  year,
}