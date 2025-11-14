import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_event.dart';
import '../services/workout_schedule_service.dart';
import '../utils/result.dart';

/// Service provider for workout schedule operations
final workoutScheduleServiceProvider = Provider<WorkoutScheduleService>((ref) {
  return WorkoutScheduleService();
});

/// Provider for calendar events in a date range
///
/// This provider is optimized for calendar month/week views with date range
/// queries that utilize database indexes for fast performance.
final calendarEventsProvider = FutureProvider.family<
    List<CalendarEvent>,
    CalendarDateRange>((ref, dateRange) async {
  final service = ref.watch(workoutScheduleServiceProvider);
  final result = await service.getCalendarEvents(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    planId: dateRange.planId,
  );

  return switch (result) {
    Success(data: final data) => data,
    Error(error: final error) => throw error,
  };
});

/// Provider for events on a specific date
///
/// This provider is optimized for day selection with indexed date lookups.
final eventsForDateProvider =
    FutureProvider.family<List<CalendarEvent>, DateTime>((ref, date) async {
  final service = ref.watch(workoutScheduleServiceProvider);
  final result = await service.getEventsForDate(date);

  return switch (result) {
    Success(data: final data) => data,
    Error(error: final error) => throw error,
  };
});

/// Provider for events by day of week
///
/// This provider supports recurring schedule pattern queries.
final eventsByDayOfWeekProvider = FutureProvider.family<
    List<CalendarEvent>,
    DayOfWeekFilter>((ref, filter) async {
  final service = ref.watch(workoutScheduleServiceProvider);
  final result = await service.getEventsByDayOfWeek(
    filter.dayOfWeek,
    startDate: filter.startDate,
    endDate: filter.endDate,
    planId: filter.planId,
  );

  return switch (result) {
    Success(data: final data) => data,
    Error(error: final error) => throw error,
  };
});

/// Date range filter for calendar events
class CalendarDateRange {
  final DateTime startDate;
  final DateTime endDate;
  final String? planId;

  const CalendarDateRange({
    required this.startDate,
    required this.endDate,
    this.planId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarDateRange &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.planId == planId;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate, planId);
}

/// Day of week filter for recurring patterns
class DayOfWeekFilter {
  final String dayOfWeek;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? planId;

  const DayOfWeekFilter({
    required this.dayOfWeek,
    this.startDate,
    this.endDate,
    this.planId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayOfWeekFilter &&
        other.dayOfWeek == dayOfWeek &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.planId == planId;
  }

  @override
  int get hashCode =>
      Object.hash(dayOfWeek, startDate, endDate, planId);
}
