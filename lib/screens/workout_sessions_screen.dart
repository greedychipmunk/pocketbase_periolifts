import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_session.dart';
import '../providers/workout_session_providers.dart';
import '../widgets/workout_session_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_message.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../utils/workout_converter.dart';
import 'workout_session_form_screen.dart';
import 'workout_tracking_screen_riverpod.dart';

class WorkoutSessionsScreen extends ConsumerStatefulWidget {
  const WorkoutSessionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutSessionsScreen> createState() =>
      _WorkoutSessionsScreenState();
}

class _WorkoutSessionsScreenState extends ConsumerState<WorkoutSessionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  WorkoutSessionStatus? _selectedStatus;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  /// Helper method to create service instances with proper configuration
  Map<String, dynamic> _createServices() {
    final workoutService = WorkoutService();
    final authService = AuthService();

    return {'workoutService': workoutService, 'authService': authService};
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final filter = _getCurrentFilter();
      final notifier = ref.read(workoutSessionsProvider(filter).notifier);
      notifier.loadMore();
    }
  }

  WorkoutSessionsFilter _getCurrentFilter() {
    WorkoutSessionStatus? status;
    switch (_tabController.index) {
      case 1:
        status = WorkoutSessionStatus.planned;
        break;
      case 2:
        status = WorkoutSessionStatus.inProgress;
        break;
      case 3:
        status = WorkoutSessionStatus.completed;
        break;
      default:
        status = _selectedStatus;
    }

    return WorkoutSessionsFilter(
      status: status,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreateSession,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Planned'),
            Tab(text: 'Active'),
            Tab(text: 'Complete'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionsList(),
          _buildSessionsList(),
          _buildSessionsList(),
          _buildSessionsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateSession,
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
    );
  }

  Widget _buildSessionsList() {
    final filter = _getCurrentFilter();
    final sessionsAsync = ref.watch(workoutSessionsProvider(filter));
    final activeSessionAsync = ref.watch(activeWorkoutSessionProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workoutSessionsProvider(filter));
        ref.invalidate(activeWorkoutSessionProvider);
      },
      child: sessionsAsync.when(
        data: (sessions) =>
            _buildSessionsListView(sessions, activeSessionAsync),
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorMessage(
          message: error.toString(),
          onRetry: () => ref.invalidate(workoutSessionsProvider(filter)),
        ),
      ),
    );
  }

  Widget _buildSessionsListView(
    List<WorkoutSession> sessions,
    AsyncValue<WorkoutSession?> activeSessionAsync,
  ) {
    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length + 1, // +1 for loading indicator
      itemBuilder: (context, index) {
        if (index == sessions.length) {
          final filter = _getCurrentFilter();
          final notifier = ref.read(workoutSessionsProvider(filter).notifier);
          return notifier.hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }

        final session = sessions[index];
        final isActive = activeSessionAsync.when(
          data: (activeSession) => activeSession?.id == session.id,
          loading: () => false,
          error: (_, __) => false,
        );

        return WorkoutSessionCard(
          session: session,
          isActive: isActive,
          onTap: () => _navigateToSession(session),
          onStart: session.status == WorkoutSessionStatus.planned
              ? () => _startSession(session)
              : null,
          onResume: session.status == WorkoutSessionStatus.inProgress
              ? () => _resumeSession(session)
              : null,
          onDelete: () => _deleteSession(session),
          onEdit: () => _navigateToEditSession(session),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No workout sessions yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first workout session to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreateSession,
            icon: const Icon(Icons.add),
            label: const Text('Create Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    WorkoutSessionStatus? tempStatus = _selectedStatus;
    DateTimeRange? tempDateRange = _dateRange;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Sessions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: tempStatus == null,
                    onSelected: (selected) {
                      setState(() => tempStatus = selected ? null : tempStatus);
                    },
                  ),
                  FilterChip(
                    label: const Text('Planned'),
                    selected: tempStatus == WorkoutSessionStatus.planned,
                    onSelected: (selected) {
                      setState(
                        () => tempStatus = selected
                            ? WorkoutSessionStatus.planned
                            : null,
                      );
                    },
                  ),
                  FilterChip(
                    label: const Text('In Progress'),
                    selected: tempStatus == WorkoutSessionStatus.inProgress,
                    onSelected: (selected) {
                      setState(
                        () => tempStatus = selected
                            ? WorkoutSessionStatus.inProgress
                            : null,
                      );
                    },
                  ),
                  FilterChip(
                    label: const Text('Completed'),
                    selected: tempStatus == WorkoutSessionStatus.completed,
                    onSelected: (selected) {
                      setState(
                        () => tempStatus = selected
                            ? WorkoutSessionStatus.completed
                            : null,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Date Range', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ListTile(
                title: Text(
                  tempDateRange != null
                      ? '${_formatDate(tempDateRange!.start)} - ${_formatDate(tempDateRange!.end)}'
                      : 'All dates',
                ),
                trailing: tempDateRange != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => tempDateRange = null),
                      )
                    : null,
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
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
                setState(() {
                  tempStatus = null;
                  tempDateRange = null;
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
        _selectedStatus = tempStatus;
        _dateRange = tempDateRange;
      });

      // Refresh the current tab's data
      final filter = _getCurrentFilter();
      ref.invalidate(workoutSessionsProvider(filter));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToCreateSession() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const WorkoutSessionFormScreen(),
      ),
    );
  }

  void _navigateToEditSession(WorkoutSession session) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => WorkoutSessionFormScreen(session: session),
      ),
    );
  }

  void _navigateToSession(WorkoutSession session) {
    if (session.status == WorkoutSessionStatus.inProgress) {
      _resumeSession(session);
    } else {
      // Navigate to session details view (to be implemented)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session: ${session.name}'),
          action: SnackBarAction(
            label: 'View Details',
            onPressed: () {
              // TODO: Navigate to session details screen
            },
          ),
        ),
      );
    }
  }

  Future<void> _startSession(WorkoutSession session) async {
    try {
      await ref
          .read(activeWorkoutSessionProvider.notifier)
          .startSession(session.id);

      if (mounted) {
        // Convert WorkoutSession to Workout for compatibility
        final workout = WorkoutConverter.convertFromWorkoutSession(session);

        // Create service instances
        final services = _createServices();
        final workoutService = services['workoutService'] as WorkoutService;
        final authService = services['authService'] as AuthService;

        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (context) => WorkoutTrackingScreenRiverpod(
              workout: workout,
              workoutService: workoutService,
              authService: authService,
              onAuthError: () {
                // Handle auth error - navigate back or show error
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Authentication error occurred'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start session: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _resumeSession(WorkoutSession session) {
    // Convert WorkoutSession to Workout for compatibility
    final workout = WorkoutConverter.convertFromWorkoutSession(session);

    // Create service instances
    final services = _createServices();
    final workoutService = services['workoutService'] as WorkoutService;
    final authService = services['authService'] as AuthService;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => WorkoutTrackingScreenRiverpod(
          workout: workout,
          workoutService: workoutService,
          authService: authService,
          onAuthError: () {
            // Handle auth error - navigate back or show error
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteSession(WorkoutSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${session.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final filter = _getCurrentFilter();
        await ref
            .read(workoutSessionsProvider(filter).notifier)
            .deleteSession(session.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session deleted successfully')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete session: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
