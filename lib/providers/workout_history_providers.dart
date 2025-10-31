import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_history.dart';
import '../services/workout_history_service.dart';

// Service provider
final workoutHistoryServiceProvider = Provider<WorkoutHistoryService>((ref) {
  return WorkoutHistoryService();
});

// Workout history provider with filtering and pagination
final workoutHistoryProvider =
    StateNotifierProvider.family<
      WorkoutHistoryNotifier,
      AsyncValue<List<WorkoutHistoryEntry>>,
      WorkoutHistoryFilter
    >((ref, filter) {
      final service = ref.watch(workoutHistoryServiceProvider);
      return WorkoutHistoryNotifier(service, filter);
    });

class WorkoutHistoryFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final WorkoutHistoryStatus? status;
  final String? exerciseName;
  final String? workoutName;
  final int limit;
  final int offset;

  const WorkoutHistoryFilter({
    this.startDate,
    this.endDate,
    this.status,
    this.exerciseName,
    this.workoutName,
    this.limit = 20,
    this.offset = 0,
  });

  WorkoutHistoryFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    WorkoutHistoryStatus? status,
    String? exerciseName,
    String? workoutName,
    int? limit,
    int? offset,
  }) {
    return WorkoutHistoryFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      exerciseName: exerciseName ?? this.exerciseName,
      workoutName: workoutName ?? this.workoutName,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutHistoryFilter &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.status == status &&
        other.exerciseName == exerciseName &&
        other.workoutName == workoutName &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    return startDate.hashCode ^
        endDate.hashCode ^
        status.hashCode ^
        exerciseName.hashCode ^
        workoutName.hashCode ^
        limit.hashCode ^
        offset.hashCode;
  }
}

class WorkoutHistoryNotifier
    extends StateNotifier<AsyncValue<List<WorkoutHistoryEntry>>> {
  final WorkoutHistoryService _service;
  final WorkoutHistoryFilter _filter;
  List<WorkoutHistoryEntry> _history = [];
  bool _hasMore = true;
  bool _isLoading = false;

  WorkoutHistoryNotifier(this._service, this._filter)
    : super(const AsyncValue.loading()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      _history.clear();
      _hasMore = true;
      final entriesResult = await _service.getWorkoutHistory(
        startDate: _filter.startDate,
        endDate: _filter.endDate,
        status: _filter.status,
        exerciseName: _filter.exerciseName,
        workoutName: _filter.workoutName,
        page: 1,
        perPage: _filter.limit,
      );

      _history = entriesResult.getOrThrow();
      _hasMore = _history.length >= _filter.limit;
      state = AsyncValue.data(_history);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    try {
      final moreEntriesResult = await _service.getWorkoutHistory(
        startDate: _filter.startDate,
        endDate: _filter.endDate,
        status: _filter.status,
        exerciseName: _filter.exerciseName,
        workoutName: _filter.workoutName,
        page: (_history.length ~/ _filter.limit) + 1,
        perPage: _filter.limit,
      );

      final moreEntries = moreEntriesResult.getOrThrow();
      _history.addAll(moreEntries);
      _hasMore = moreEntries.length >= _filter.limit;
      state = AsyncValue.data(_history);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadHistory();
  }

  Future<void> createEntry(WorkoutHistoryEntry entry) async {
    try {
      final newEntryResult = await _service.createWorkoutHistory(entry);
      final newEntry = newEntryResult.getOrThrow();
      _history.insert(0, newEntry); // Add to beginning
      state = AsyncValue.data(_history);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateEntry(WorkoutHistoryEntry entry) async {
    try {
      final updatedEntryResult = await _service.updateWorkoutHistory(
        entry.id,
        entry,
      );
      final updatedEntry = updatedEntryResult.getOrThrow();
      final index = _history.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _history[index] = updatedEntry;
        state = AsyncValue.data(_history);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _service.deleteWorkoutHistory(entryId);
      _history.removeWhere((entry) => entry.id == entryId);
      state = AsyncValue.data(_history);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}

// Individual workout history entry provider
final workoutHistoryEntryProvider =
    StateNotifierProvider.family<
      WorkoutHistoryEntryNotifier,
      AsyncValue<WorkoutHistoryEntry>,
      String
    >((ref, entryId) {
      final service = ref.watch(workoutHistoryServiceProvider);
      return WorkoutHistoryEntryNotifier(service, entryId);
    });

class WorkoutHistoryEntryNotifier
    extends StateNotifier<AsyncValue<WorkoutHistoryEntry>> {
  final WorkoutHistoryService _service;
  final String _entryId;

  WorkoutHistoryEntryNotifier(this._service, this._entryId)
    : super(const AsyncValue.loading()) {
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    try {
      final entryResult = await _service.getWorkoutHistoryById(_entryId);
      final entry = entryResult.getOrThrow();
      state = AsyncValue.data(entry);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateEntry(WorkoutHistoryEntry entry) async {
    try {
      final updatedEntryResult = await _service.updateWorkoutHistory(
        entry.id,
        entry,
      );
      final updatedEntry = updatedEntryResult.getOrThrow();
      state = AsyncValue.data(updatedEntry);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadEntry();
  }
}

// Workout statistics provider
final workoutHistoryStatsProvider =
    StateNotifierProvider.family<
      WorkoutHistoryStatsNotifier,
      AsyncValue<WorkoutHistoryStats>,
      WorkoutHistoryStatsFilter
    >((ref, filter) {
      final service = ref.watch(workoutHistoryServiceProvider);
      return WorkoutHistoryStatsNotifier(service, filter);
    });

class WorkoutHistoryStatsFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  const WorkoutHistoryStatsFilter({this.startDate, this.endDate});

  WorkoutHistoryStatsFilter copyWith({DateTime? startDate, DateTime? endDate}) {
    return WorkoutHistoryStatsFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutHistoryStatsFilter &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return startDate.hashCode ^ endDate.hashCode;
  }
}

class WorkoutHistoryStatsNotifier
    extends StateNotifier<AsyncValue<WorkoutHistoryStats>> {
  final WorkoutHistoryService _service;
  final WorkoutHistoryStatsFilter _filter;

  WorkoutHistoryStatsNotifier(this._service, this._filter)
    : super(const AsyncValue.loading()) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final statsResult = await _service.getUserWorkoutStats(
        startDate: _filter.startDate,
        endDate: _filter.endDate,
      );
      final stats = statsResult.getOrThrow();
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadStats();
  }
}

// Recent workout history provider (for dashboard)
final recentWorkoutHistoryProvider =
    StateNotifierProvider<
      RecentWorkoutHistoryNotifier,
      AsyncValue<List<WorkoutHistoryEntry>>
    >((ref) {
      final service = ref.watch(workoutHistoryServiceProvider);
      return RecentWorkoutHistoryNotifier(service);
    });

class RecentWorkoutHistoryNotifier
    extends StateNotifier<AsyncValue<List<WorkoutHistoryEntry>>> {
  final WorkoutHistoryService _service;

  RecentWorkoutHistoryNotifier(this._service)
    : super(const AsyncValue.loading()) {
    _loadRecentHistory();
  }

  Future<void> _loadRecentHistory() async {
    try {
      final entriesResult = await _service.getRecentWorkouts();
      final entries = entriesResult.getOrThrow();
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadRecentHistory();
  }
}

// Workout patterns provider (streaks, weekly patterns, etc.)
final workoutPatternsProvider =
    StateNotifierProvider.family<
      WorkoutPatternsNotifier,
      AsyncValue<Map<String, dynamic>>,
      WorkoutPatternsFilter
    >((ref, filter) {
      final service = ref.watch(workoutHistoryServiceProvider);
      return WorkoutPatternsNotifier(service, filter);
    });

class WorkoutPatternsFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  const WorkoutPatternsFilter({this.startDate, this.endDate});

  WorkoutPatternsFilter copyWith({DateTime? startDate, DateTime? endDate}) {
    return WorkoutPatternsFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutPatternsFilter &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return startDate.hashCode ^ endDate.hashCode;
  }
}

class WorkoutPatternsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final WorkoutHistoryService _service;
  final WorkoutPatternsFilter _filter;

  WorkoutPatternsNotifier(this._service, this._filter)
    : super(const AsyncValue.loading()) {
    _loadPatterns();
  }

  Future<void> _loadPatterns() async {
    try {
      // TODO: Implement getWorkoutPatterns method in WorkoutHistoryService
      // For now, return empty patterns to avoid compilation errors
      final patterns = <String, dynamic>{};
      state = AsyncValue.data(patterns);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPatterns();
  }
}
