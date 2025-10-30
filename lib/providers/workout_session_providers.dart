import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../models/workout_session.dart';
import '../services/workout_session_service.dart';

// Service provider
final workoutSessionServiceProvider = Provider<WorkoutSessionService>((ref) {
  throw UnimplementedError('WorkoutSessionService provider must be overridden');
});

// Active workout session provider
final activeWorkoutSessionProvider = StateNotifierProvider<ActiveWorkoutSessionNotifier, AsyncValue<WorkoutSession?>>((ref) {
  final service = ref.watch(workoutSessionServiceProvider);
  return ActiveWorkoutSessionNotifier(service);
});

class ActiveWorkoutSessionNotifier extends StateNotifier<AsyncValue<WorkoutSession?>> {
  final WorkoutSessionService _service;

  ActiveWorkoutSessionNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadActiveSession();
  }

  Future<void> _loadActiveSession() async {
    try {
      final session = await _service.getActiveWorkoutSession();
      state = AsyncValue.data(session);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> startSession(String sessionId) async {
    try {
      state = const AsyncValue.loading();
      final session = await _service.startWorkoutSession(sessionId);
      state = AsyncValue.data(session);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSession(WorkoutSession session) async {
    try {
      final updatedSession = await _service.updateWorkoutSession(session);
      state = AsyncValue.data(updatedSession);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> completeSession(String sessionId) async {
    try {
      state = const AsyncValue.loading();
      await _service.completeWorkoutSession(sessionId);
      state = const AsyncValue.data(null); // No active session after completion
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSet(String sessionId, String exerciseId, String setId, WorkoutSessionSet updatedSet) async {
    try {
      final updatedSession = await _service.updateSetData(sessionId, exerciseId, setId, updatedSet);
      state = AsyncValue.data(updatedSession);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearActiveSession() {
    state = const AsyncValue.data(null);
  }
}

// Workout sessions list provider with pagination
final workoutSessionsProvider = StateNotifierProvider.family<WorkoutSessionsNotifier, AsyncValue<List<WorkoutSession>>, WorkoutSessionsFilter>((ref, filter) {
  final service = ref.watch(workoutSessionServiceProvider);
  return WorkoutSessionsNotifier(service, filter);
});

class WorkoutSessionsFilter {
  final WorkoutSessionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const WorkoutSessionsFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.limit = 20,
    this.offset = 0,
  });

  WorkoutSessionsFilter copyWith({
    WorkoutSessionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) {
    return WorkoutSessionsFilter(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSessionsFilter &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        limit.hashCode ^
        offset.hashCode;
  }
}

class WorkoutSessionsNotifier extends StateNotifier<AsyncValue<List<WorkoutSession>>> {
  final WorkoutSessionService _service;
  final WorkoutSessionsFilter _filter;
  List<WorkoutSession> _sessions = [];
  bool _hasMore = true;
  bool _isLoading = false;

  WorkoutSessionsNotifier(this._service, this._filter) : super(const AsyncValue.loading()) {
    _loadInitialSessions();
  }

  Future<void> _loadInitialSessions() async {
    try {
      _sessions.clear();
      _hasMore = true;
      final sessions = await _service.getWorkoutSessions(
        limit: _filter.limit,
        offset: 0,
        status: _filter.status,
        startDate: _filter.startDate,
        endDate: _filter.endDate,
      );
      _sessions = sessions;
      _hasMore = sessions.length >= _filter.limit;
      state = AsyncValue.data(_sessions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    try {
      final moreSessions = await _service.getWorkoutSessions(
        limit: _filter.limit,
        offset: _sessions.length,
        status: _filter.status,
        startDate: _filter.startDate,
        endDate: _filter.endDate,
      );
      
      _sessions.addAll(moreSessions);
      _hasMore = moreSessions.length >= _filter.limit;
      state = AsyncValue.data(_sessions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    await _loadInitialSessions();
  }

  Future<void> createSession(WorkoutSession session) async {
    try {
      final newSession = await _service.createWorkoutSession(session);
      _sessions.insert(0, newSession); // Add to beginning
      state = AsyncValue.data(_sessions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _service.deleteWorkoutSession(sessionId);
      _sessions.removeWhere((session) => session.sessionId == sessionId);
      state = AsyncValue.data(_sessions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}

// Workout session detail provider
final workoutSessionProvider = StateNotifierProvider.family<WorkoutSessionNotifier, AsyncValue<WorkoutSession>, String>((ref, sessionId) {
  final service = ref.watch(workoutSessionServiceProvider);
  return WorkoutSessionNotifier(service, sessionId);
});

class WorkoutSessionNotifier extends StateNotifier<AsyncValue<WorkoutSession>> {
  final WorkoutSessionService _service;
  final String _sessionId;

  WorkoutSessionNotifier(this._service, this._sessionId) : super(const AsyncValue.loading()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final session = await _service.getWorkoutSession(_sessionId);
      state = AsyncValue.data(session);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSession(WorkoutSession session) async {
    try {
      final updatedSession = await _service.updateWorkoutSession(session);
      state = AsyncValue.data(updatedSession);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> startSession() async {
    try {
      final updatedSession = await _service.startWorkoutSession(_sessionId);
      state = AsyncValue.data(updatedSession);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> completeSession() async {
    try {
      final updatedSession = await _service.completeWorkoutSession(_sessionId);
      state = AsyncValue.data(updatedSession);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSet(String exerciseId, String setId, WorkoutSessionSet updatedSet) async {
    try {
      final updatedSession = await _service.updateSetData(_sessionId, exerciseId, setId, updatedSet);
      state = AsyncValue.data(updatedSession);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadSession();
  }
}

// Workout statistics provider
final workoutStatsProvider = StateNotifierProvider.family<WorkoutStatsNotifier, AsyncValue<WorkoutSessionStats>, WorkoutStatsFilter>((ref, filter) {
  final service = ref.watch(workoutSessionServiceProvider);
  return WorkoutStatsNotifier(service, filter);
});

class WorkoutStatsFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  const WorkoutStatsFilter({
    this.startDate,
    this.endDate,
  });

  WorkoutStatsFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return WorkoutStatsFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutStatsFilter &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return startDate.hashCode ^ endDate.hashCode;
  }
}

class WorkoutStatsNotifier extends StateNotifier<AsyncValue<WorkoutSessionStats>> {
  final WorkoutSessionService _service;
  final WorkoutStatsFilter _filter;

  WorkoutStatsNotifier(this._service, this._filter) : super(const AsyncValue.loading()) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _service.getWorkoutStats(
        startDate: _filter.startDate,
        endDate: _filter.endDate,
      );
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

// Workout history provider
final workoutHistoryProvider = StateNotifierProvider.family<WorkoutHistoryNotifier, AsyncValue<List<WorkoutSession>>, WorkoutHistoryFilter>((ref, filter) {
  final service = ref.watch(workoutSessionServiceProvider);
  return WorkoutHistoryNotifier(service, filter);
});

class WorkoutHistoryFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const WorkoutHistoryFilter({
    this.startDate,
    this.endDate,
    this.limit = 20,
    this.offset = 0,
  });

  WorkoutHistoryFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) {
    return WorkoutHistoryFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    return startDate.hashCode ^
        endDate.hashCode ^
        limit.hashCode ^
        offset.hashCode;
  }
}

class WorkoutHistoryNotifier extends StateNotifier<AsyncValue<List<WorkoutSession>>> {
  final WorkoutSessionService _service;
  final WorkoutHistoryFilter _filter;
  List<WorkoutSession> _history = [];
  bool _hasMore = true;
  bool _isLoading = false;

  WorkoutHistoryNotifier(this._service, this._filter) : super(const AsyncValue.loading()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      _history.clear();
      _hasMore = true;
      final sessions = await _service.getWorkoutHistory(
        limit: _filter.limit,
        offset: 0,
        startDate: _filter.startDate,
        endDate: _filter.endDate,
      );
      _history = sessions;
      _hasMore = sessions.length >= _filter.limit;
      state = AsyncValue.data(_history);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    try {
      final moreHistory = await _service.getWorkoutHistory(
        limit: _filter.limit,
        offset: _history.length,
        startDate: _filter.startDate,
        endDate: _filter.endDate,
      );
      
      _history.addAll(moreHistory);
      _hasMore = moreHistory.length >= _filter.limit;
      state = AsyncValue.data(_history);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    await _loadHistory();
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}