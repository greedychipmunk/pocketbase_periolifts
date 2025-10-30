import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import '../models/workout_session.dart';
import '../providers/workout_session_providers.dart';
import '../providers/units_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  DateTimeRange? _dateRange;
  
  // Time period filter
  TimePeriod _selectedPeriod = TimePeriod.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final filter = _getHistoryFilter();
      final notifier = ref.read(workoutHistoryProvider(filter).notifier);
      notifier.loadMore();
    }
  }

  WorkoutHistoryFilter _getHistoryFilter() {
    final (startDate, endDate) = _getDateRange();
    return WorkoutHistoryFilter(
      startDate: startDate,
      endDate: endDate,
    );
  }

  WorkoutStatsFilter _getStatsFilter() {
    final (startDate, endDate) = _getDateRange();
    return WorkoutStatsFilter(
      startDate: startDate,
      endDate: endDate,
    );
  }

  (DateTime?, DateTime?) _getDateRange() {
    if (_dateRange != null) {
      return (_dateRange!.start, _dateRange!.end);
    }

    final now = DateTime.now();
    switch (_selectedPeriod) {
      case TimePeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return (weekStart, now);
      case TimePeriod.month:
        final monthStart = DateTime(now.year, now.month, 1);
        return (monthStart, now);
      case TimePeriod.quarter:
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        return (quarterStart, now);
      case TimePeriod.year:
        final yearStart = DateTime(now.year, 1, 1);
        return (yearStart, now);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatisticsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final statsFilter = _getStatsFilter();
    final statsAsync = ref.watch(workoutStatsProvider(statsFilter));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workoutStatsProvider(statsFilter));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => _buildStatsContent(stats),
            loading: () => const LoadingIndicator(message: 'Loading statistics...'),
            error: (error, stackTrace) => ErrorMessage(
              message: error.toString(),
              onRetry: () => ref.invalidate(workoutStatsProvider(statsFilter)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final historyFilter = _getHistoryFilter();
    final historyAsync = ref.watch(workoutHistoryProvider(historyFilter));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workoutHistoryProvider(historyFilter));
      },
      child: historyAsync.when(
        data: (sessions) => _buildHistoryContent(sessions),
        loading: () => const LoadingIndicator(message: 'Loading history...'),
        error: (error, stackTrace) => ErrorMessage(
          message: error.toString(),
          onRetry: () => ref.invalidate(workoutHistoryProvider(historyFilter)),
        ),
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
                        _dateRange = null; // Clear custom date range
                      });
                      _refreshData();
                    }
                  },
                );
              }).toList(),
            ),
            if (_dateRange != null) ...[
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
                        'Custom: ${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _dateRange = null);
                        _refreshData();
                      },
                      child: const Text('Clear'),
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

  Widget _buildStatsContent(WorkoutSessionStats stats) {
    return Column(
      children: [
        _buildStatsOverview(stats),
        const SizedBox(height: 16),
        _buildStatsDetails(stats),
        const SizedBox(height: 16),
        _buildProgressChart(stats),
      ],
    );
  }

  Widget _buildStatsOverview(WorkoutSessionStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Workouts',
                    stats.totalSessions.toString(),
                    Icons.fitness_center,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    stats.completedSessions.toString(),
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
                  child: _buildStatCard(
                    'Total Sets',
                    stats.totalSets.toString(),
                    Icons.repeat,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: provider.Consumer<UnitsProvider>(
                    builder: (context, unitsProvider, child) {
                      return _buildStatCard(
                        'Weight Lifted',
                        unitsProvider.formatWeight(stats.totalWeightLifted, decimals: 0),
                        Icons.fitness_center,
                        Colors.purple,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDetails(WorkoutSessionStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Completion Rate',
              '${stats.completionRate.toStringAsFixed(1)}%',
              Icons.trending_up,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Average Workout Time',
              '${stats.averageWorkoutTime.toStringAsFixed(0)} min',
              Icons.timer,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Total Workout Time',
              '${(stats.totalWorkoutTime / 60).toStringAsFixed(1)} hours',
              Icons.schedule,
            ),
            const SizedBox(height: 12),
            provider.Consumer<UnitsProvider>(
              builder: (context, unitsProvider, child) {
                return _buildDetailRow(
                  'Average Weight per Set',
                  stats.totalSets > 0
                      ? unitsProvider.formatWeight(stats.totalWeightLifted / stats.totalSets, decimals: 1)
                      : unitsProvider.formatWeight(0, decimals: 0),
                  Icons.fitness_center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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

  Widget _buildProgressChart(WorkoutSessionStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 48,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chart Coming Soon',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Integration with charting library needed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyHistory();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length + 1, // +1 for loading indicator
      itemBuilder: (context, index) {
        if (index == sessions.length) {
          final filter = _getHistoryFilter();
          final notifier = ref.read(workoutHistoryProvider(filter).notifier);
          return notifier.hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }

        final session = sessions[index];
        return _buildHistoryCard(session);
      },
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No workout history',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first workout to see it here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(WorkoutSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSessionDetails(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatHistoryDate(session.completedAt ?? session.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade800),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (session.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  session.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHistoryMetric(
                    'Duration',
                    session.duration != null
                        ? _formatDuration(session.duration!)
                        : 'N/A',
                    Icons.timer,
                  ),
                  _buildHistoryMetric(
                    'Exercises',
                    session.totalExercises.toString(),
                    Icons.fitness_center,
                  ),
                  _buildHistoryMetric(
                    'Sets',
                    session.totalSets.toString(),
                    Icons.repeat,
                  ),
                  _buildHistoryMetric(
                    'Weight',
                    '${_calculateTotalWeight(session).toStringAsFixed(0)}kg',
                    Icons.fitness_center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

  Future<void> _showFilterDialog() async {
    DateTimeRange? tempDateRange = _dateRange;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter History'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Custom Date Range', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ListTile(
                title: Text(tempDateRange != null
                    ? '${_formatDate(tempDateRange!.start)} - ${_formatDate(tempDateRange!.end)}'
                    : 'Select date range'),
                trailing: tempDateRange != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => tempDateRange = null),
                      )
                    : null,
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                    initialDateRange: tempDateRange,
                  );
                  if (range != null) {
                    setState(() => tempDateRange = range);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() => tempDateRange = null);
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _dateRange = tempDateRange;
        if (_dateRange != null) {
          _selectedPeriod = TimePeriod.month; // Reset to default when using custom range
        }
      });
      _refreshData();
    }
  }

  void _refreshData() {
    final historyFilter = _getHistoryFilter();
    final statsFilter = _getStatsFilter();
    
    ref.invalidate(workoutHistoryProvider(historyFilter));
    ref.invalidate(workoutStatsProvider(statsFilter));
  }

  void _showSessionDetails(WorkoutSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      session.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatHistoryDate(session.completedAt ?? session.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: session.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = session.exercises[index];
                    return _buildSessionExerciseCard(exercise);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionExerciseCard(WorkoutSessionExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.exerciseName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...exercise.sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: set.completed ? Colors.green : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: set.completed
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Set ${index + 1}: ${set.actualReps ?? set.targetReps} reps × ${set.actualWeight ?? set.targetWeight}kg',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  double _calculateTotalWeight(WorkoutSession session) {
    double total = 0;
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        if (set.completed && set.actualWeight != null && set.actualReps != null) {
          total += set.actualWeight! * set.actualReps!;
        }
      }
    }
    return total;
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

  String _formatHistoryDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return _formatDate(dateTime);
    }
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