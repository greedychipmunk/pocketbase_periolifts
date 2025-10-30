import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import '../models/workout_history.dart';
import '../providers/workout_history_providers.dart';
import '../providers/units_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';
import '../widgets/workout_history_card.dart';
import 'workout_history_detail_screen.dart';

class EnhancedWorkoutHistoryScreen extends ConsumerStatefulWidget {
  const EnhancedWorkoutHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedWorkoutHistoryScreen> createState() => _EnhancedWorkoutHistoryScreenState();
}

class _EnhancedWorkoutHistoryScreenState extends ConsumerState<EnhancedWorkoutHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  // Filter state
  DateTimeRange? _dateRange;
  WorkoutHistoryStatus? _selectedStatus;
  String _searchQuery = '';
  String _exerciseFilter = '';
  TimePeriod _selectedPeriod = TimePeriod.month;
  
  // Search controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _exerciseController = TextEditingController();

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
    _searchController.dispose();
    _exerciseController.dispose();
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
      status: _selectedStatus,
      workoutName: _searchQuery.isEmpty ? null : _searchQuery,
      exerciseName: _exerciseFilter.isEmpty ? null : _exerciseFilter,
    );
  }

  WorkoutHistoryStatsFilter _getStatsFilter() {
    final (startDate, endDate) = _getDateRange();
    return WorkoutHistoryStatsFilter(
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
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
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
            data: (stats) => _buildStatsContent(stats),
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

  Widget _buildHistoryTab() {
    final historyFilter = _getHistoryFilter();
    final historyAsync = ref.watch(workoutHistoryProvider(historyFilter));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workoutHistoryProvider(historyFilter));
      },
      child: Column(
        children: [
          if (_searchQuery.isNotEmpty || _exerciseFilter.isNotEmpty || _selectedStatus != null) ...[
            _buildActiveFilters(),
          ],
          Expanded(
            child: historyAsync.when(
              data: (entries) => _buildHistoryContent(entries),
              loading: () => const LoadingIndicator(message: 'Loading history...'),
              error: (error, stackTrace) => ErrorMessage(
                message: error.toString(),
                onRetry: () => ref.invalidate(workoutHistoryProvider(historyFilter)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_searchQuery.isNotEmpty)
            Chip(
              label: Text('Name: $_searchQuery'),
              onDeleted: () {
                setState(() => _searchQuery = '');
                _searchController.clear();
                _refreshData();
              },
            ),
          if (_exerciseFilter.isNotEmpty)
            Chip(
              label: Text('Exercise: $_exerciseFilter'),
              onDeleted: () {
                setState(() => _exerciseFilter = '');
                _exerciseController.clear();
                _refreshData();
              },
            ),
          if (_selectedStatus != null)
            Chip(
              label: Text('Status: ${_selectedStatus!.name}'),
              onDeleted: () {
                setState(() => _selectedStatus = null);
                _refreshData();
              },
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

  Widget _buildStatsContent(WorkoutHistoryStats stats) {
    return Column(
      children: [
        _buildStatsOverview(stats),
        const SizedBox(height: 16),
        _buildStatsDetails(stats),
        const SizedBox(height: 16),
        _buildExerciseFrequency(stats),
        const SizedBox(height: 16),
        _buildProgressChart(stats),
      ],
    );
  }

  Widget _buildStatsOverview(WorkoutHistoryStats stats) {
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
                        'Total Weight',
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
                    'Avg Duration',
                    _formatDuration(stats.averageDuration),
                    Icons.timer,
                    Colors.orange,
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

  Widget _buildStatsDetails(WorkoutHistoryStats stats) {
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
              'Total Duration',
              _formatDuration(stats.totalDuration),
              Icons.schedule,
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

  Widget _buildExerciseFrequency(WorkoutHistoryStats stats) {
    if (stats.exerciseFrequency.isEmpty) return const SizedBox.shrink();

    final sortedExercises = stats.exerciseFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Frequent Exercises',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedExercises.take(5).map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
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

  Widget _buildProgressChart(WorkoutHistoryStats stats) {
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

  Widget _buildHistoryContent(List<WorkoutHistoryEntry> entries) {
    if (entries.isEmpty) {
      return _buildEmptyHistory();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: entries.length + 1, // +1 for loading indicator
      itemBuilder: (context, index) {
        if (index == entries.length) {
          final filter = _getHistoryFilter();
          final notifier = ref.read(workoutHistoryProvider(filter).notifier);
          return notifier.hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }

        final entry = entries[index];
        return WorkoutHistoryCard(
          entry: entry,
          onTap: () => _showWorkoutDetails(entry),
          onDelete: () => _showDeleteConfirmation(entry),
        );
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

  Future<void> _showSearchDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Workouts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Workout name',
                hintText: 'Enter workout name',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _exerciseController,
              decoration: const InputDecoration(
                labelText: 'Exercise name',
                hintText: 'Enter exercise name',
                prefixIcon: Icon(Icons.fitness_center),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
                _exerciseFilter = _exerciseController.text;
              });
              Navigator.of(context).pop();
              _refreshData();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    DateTimeRange? tempDateRange = _dateRange;
    WorkoutHistoryStatus? tempStatus = _selectedStatus;

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
              const SizedBox(height: 16),
              Text('Status', style: Theme.of(context).textTheme.titleSmall),
              DropdownButton<WorkoutHistoryStatus?>(
                value: tempStatus,
                onChanged: (status) => setState(() => tempStatus = status),
                items: [
                  const DropdownMenuItem<WorkoutHistoryStatus?>(
                    value: null,
                    child: Text('All statuses'),
                  ),
                  ...WorkoutHistoryStatus.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.name),
                  )),
                ],
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
                setState(() {
                  tempDateRange = null;
                  tempStatus = null;
                });
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
        _selectedStatus = tempStatus;
        if (_dateRange != null) {
          _selectedPeriod = TimePeriod.month; // Reset to default when using custom range
        }
      });
      _refreshData();
    }
  }

  void _showWorkoutDetails(WorkoutHistoryEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutHistoryDetailScreen(entry: entry),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(WorkoutHistoryEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: Text('Are you sure you want to delete "${entry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final filter = _getHistoryFilter();
      final notifier = ref.read(workoutHistoryProvider(filter).notifier);
      await notifier.deleteEntry(entry.id);
    }
  }

  void _refreshData() {
    final historyFilter = _getHistoryFilter();
    final statsFilter = _getStatsFilter();
    
    ref.invalidate(workoutHistoryProvider(historyFilter));
    ref.invalidate(workoutHistoryStatsProvider(statsFilter));
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

