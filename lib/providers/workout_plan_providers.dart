import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_plan.dart';
import '../services/workout_plan_service.dart';

// Service provider
final workoutPlanServiceProvider = Provider<WorkoutPlanService>((ref) {
  return WorkoutPlanService();
});

// Workout plans list provider with filtering and pagination
final workoutPlansProvider =
    StateNotifierProvider.family<
      WorkoutPlansNotifier,
      AsyncValue<List<WorkoutPlan>>,
      WorkoutPlansFilter
    >((ref, filter) {
      final service = ref.watch(workoutPlanServiceProvider);
      return WorkoutPlansNotifier(service, filter);
    });

class WorkoutPlansFilter {
  final String? searchQuery;
  final bool activeOnly;
  final int page;
  final int perPage;

  const WorkoutPlansFilter({
    this.searchQuery,
    this.activeOnly = false,
    this.page = 1,
    this.perPage = 50,
  });

  WorkoutPlansFilter copyWith({
    String? searchQuery,
    bool? activeOnly,
    int? page,
    int? perPage,
  }) {
    return WorkoutPlansFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      activeOnly: activeOnly ?? this.activeOnly,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutPlansFilter &&
        other.searchQuery == searchQuery &&
        other.activeOnly == activeOnly &&
        other.page == page &&
        other.perPage == perPage;
  }

  @override
  int get hashCode {
    return searchQuery.hashCode ^
        activeOnly.hashCode ^
        page.hashCode ^
        perPage.hashCode;
  }
}

class WorkoutPlansNotifier
    extends StateNotifier<AsyncValue<List<WorkoutPlan>>> {
  final WorkoutPlanService _service;
  final WorkoutPlansFilter _filter;
  bool _hasMore = true;
  bool _isLoading = false;

  WorkoutPlansNotifier(this._service, this._filter)
    : super(const AsyncValue.loading()) {
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final result = await _service.getWorkoutPlans(
        searchQuery: _filter.searchQuery,
        page: _filter.page,
        perPage: _filter.perPage,
        activeOnly: _filter.activeOnly,
      );

      if (result.isSuccess) {
        final plans = result.data!;
        _hasMore = plans.length == _filter.perPage;
        state = AsyncValue.data(plans);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _hasMore = true;
    await _loadPlans();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;

    try {
      final currentData = state.value ?? <WorkoutPlan>[];
      final nextPage = (_filter.page) + (currentData.length ~/ _filter.perPage);

      final result = await _service.getWorkoutPlans(
        searchQuery: _filter.searchQuery,
        page: nextPage,
        perPage: _filter.perPage,
        activeOnly: _filter.activeOnly,
      );

      if (result.isSuccess) {
        final newPlans = result.data!;
        _hasMore = newPlans.length == _filter.perPage;

        final allPlans = [...currentData, ...newPlans];
        state = AsyncValue.data(allPlans);
      }
    } catch (error) {
      // Don't update state for load more errors, just log
      print('Load more error: $error');
    }
  }

  Future<void> createPlan(WorkoutPlan plan) async {
    try {
      final result = await _service.createWorkoutPlan(plan);
      if (result.isSuccess) {
        final newPlan = result.data!;
        final currentData = state.value ?? <WorkoutPlan>[];
        state = AsyncValue.data([newPlan, ...currentData]);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updatePlan(WorkoutPlan plan) async {
    try {
      final result = await _service.updateWorkoutPlan(plan);
      if (result.isSuccess) {
        final updatedPlan = result.data!;
        final currentData = state.value ?? <WorkoutPlan>[];
        final updatedData = currentData
            .map((p) => p.id == updatedPlan.id ? updatedPlan : p)
            .toList();
        state = AsyncValue.data(updatedData);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      final result = await _service.deleteWorkoutPlan(planId);
      if (result.isSuccess) {
        final currentData = state.value ?? <WorkoutPlan>[];
        final updatedData = currentData.where((p) => p.id != planId).toList();
        state = AsyncValue.data(updatedData);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> activatePlan(String planId) async {
    try {
      final result = await _service.activatePlan(planId);
      if (result.isSuccess) {
        final activatedPlan = result.data!;
        final currentData = state.value ?? <WorkoutPlan>[];
        final updatedData = currentData
            .map((p) => p.id == activatedPlan.id ? activatedPlan : p)
            .toList();
        state = AsyncValue.data(updatedData);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deactivatePlan(String planId) async {
    try {
      final result = await _service.deactivatePlan(planId);
      if (result.isSuccess) {
        final deactivatedPlan = result.data!;
        final currentData = state.value ?? <WorkoutPlan>[];
        final updatedData = currentData
            .map((p) => p.id == deactivatedPlan.id ? deactivatedPlan : p)
            .toList();
        state = AsyncValue.data(updatedData);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}

// Individual workout plan provider
final workoutPlanProvider =
    StateNotifierProvider.family<
      WorkoutPlanNotifier,
      AsyncValue<WorkoutPlan>,
      String
    >((ref, planId) {
      final service = ref.watch(workoutPlanServiceProvider);
      return WorkoutPlanNotifier(service, planId);
    });

class WorkoutPlanNotifier extends StateNotifier<AsyncValue<WorkoutPlan>> {
  final WorkoutPlanService _service;
  final String _planId;

  WorkoutPlanNotifier(this._service, this._planId)
    : super(const AsyncValue.loading()) {
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final result = await _service.getWorkoutPlan(_planId);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPlan();
  }

  Future<void> updatePlan(WorkoutPlan plan) async {
    try {
      final result = await _service.updateWorkoutPlan(plan);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addWorkoutToDate(DateTime date, String workoutId) async {
    try {
      final result = await _service.addWorkoutToDate(_planId, date, workoutId);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeWorkoutFromDate(DateTime date, String workoutId) async {
    try {
      final result = await _service.removeWorkoutFromDate(
        _planId,
        date,
        workoutId,
      );
      if (result.isSuccess) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> activate() async {
    try {
      final result = await _service.activatePlan(_planId);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deactivate() async {
    try {
      final result = await _service.deactivatePlan(_planId);
      if (result.isSuccess) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(result.error!, StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Active workout plans provider (shortcut for active-only filter)
final activePlansProvider =
    Provider<
      StateNotifierProvider<WorkoutPlansNotifier, AsyncValue<List<WorkoutPlan>>>
    >((ref) {
      return workoutPlansProvider(const WorkoutPlansFilter(activeOnly: true));
    });

// Plans for specific date provider
final plansForDateProvider = FutureProvider.family<List<WorkoutPlan>, DateTime>(
  (ref, date) async {
    final service = ref.watch(workoutPlanServiceProvider);
    final result = await service.getPlansForDate(date);
    return result.getOrThrow();
  },
);

// Workout IDs for specific date provider
final workoutIdsForDateProvider = FutureProvider.family<List<String>, DateTime>(
  (ref, date) async {
    final service = ref.watch(workoutPlanServiceProvider);
    final result = await service.getWorkoutIdsForDate(date);
    return result.getOrThrow();
  },
);

// Plan creation form provider for managing form state
final planCreationFormProvider =
    StateNotifierProvider<PlanCreationFormNotifier, PlanCreationFormState>(
      (ref) => PlanCreationFormNotifier(),
    );

class PlanCreationFormState {
  final String name;
  final String? description;
  final DateTime startDate;
  final bool isActive;
  final Map<String, List<String>> schedule;
  final bool isLoading;
  final String? error;

  PlanCreationFormState({
    this.name = '',
    this.description = '',
    DateTime? startDate,
    this.isActive = true,
    this.schedule = const {},
    this.isLoading = false,
    this.error,
  }) : startDate = startDate ?? DateTime.now();

  PlanCreationFormState copyWith({
    String? name,
    String? description,
    DateTime? startDate,
    bool? isActive,
    Map<String, List<String>>? schedule,
    bool? isLoading,
    String? error,
  }) {
    return PlanCreationFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      schedule: schedule ?? this.schedule,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isValid =>
      name.trim().isNotEmpty &&
      name.trim().length >= 2 &&
      name.trim().length <= 100;

  WorkoutPlan toPlan(String userId) {
    return WorkoutPlan.create(
      userId: userId,
      name: name.trim(),
      description: description?.trim() ?? '',
      startDate: startDate,
      schedule: schedule,
      isActive: isActive,
    );
  }
}

class PlanCreationFormNotifier extends StateNotifier<PlanCreationFormState> {
  PlanCreationFormNotifier() : super(PlanCreationFormState());

  void updateName(String name) {
    state = state.copyWith(name: name, error: null);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description, error: null);
  }

  void updateStartDate(DateTime startDate) {
    state = state.copyWith(startDate: startDate, error: null);
  }

  void updateIsActive(bool isActive) {
    state = state.copyWith(isActive: isActive, error: null);
  }

  void addWorkoutToDate(DateTime date, String workoutId) {
    final dateKey = _formatDateKey(date);
    final updatedSchedule = Map<String, List<String>>.from(state.schedule);

    if (updatedSchedule.containsKey(dateKey)) {
      if (!updatedSchedule[dateKey]!.contains(workoutId)) {
        updatedSchedule[dateKey] = [...updatedSchedule[dateKey]!, workoutId];
      }
    } else {
      updatedSchedule[dateKey] = [workoutId];
    }

    state = state.copyWith(schedule: updatedSchedule, error: null);
  }

  void removeWorkoutFromDate(DateTime date, String workoutId) {
    final dateKey = _formatDateKey(date);
    final updatedSchedule = Map<String, List<String>>.from(state.schedule);

    if (updatedSchedule.containsKey(dateKey)) {
      updatedSchedule[dateKey] = updatedSchedule[dateKey]!
          .where((id) => id != workoutId)
          .toList();

      if (updatedSchedule[dateKey]!.isEmpty) {
        updatedSchedule.remove(dateKey);
      }
    }

    state = state.copyWith(schedule: updatedSchedule, error: null);
  }

  void setSchedule(Map<String, List<String>> schedule) {
    state = state.copyWith(schedule: schedule, error: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void reset() {
    state = PlanCreationFormState();
  }

  void loadFromPlan(WorkoutPlan plan) {
    state = PlanCreationFormState(
      name: plan.name,
      description: plan.description,
      startDate: plan.startDate,
      isActive: plan.isActive,
      schedule: Map.from(plan.schedule),
      isLoading: false,
      error: null,
    );
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
