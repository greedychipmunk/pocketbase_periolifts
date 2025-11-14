import 'base_model.dart';

/// Calendar event model representing a scheduled workout in the calendar
///
/// This model represents a normalized workout schedule entry optimized for
/// calendar display. It replaces the JSON blob approach with a proper
/// relational structure that enables:
/// - Fast date range queries for month/week views
/// - Indexed lookups for specific dates
/// - Rich calendar metadata (colors, status, etc.)
/// - Direct SQL queries without client-side JSON parsing
class CalendarEvent extends BasePocketBaseModel {
  /// ID of the workout plan this event belongs to
  final String planId;

  /// ID of the workout scheduled for this date
  final String workoutId;

  /// The scheduled date for this workout
  final DateTime scheduledDate;

  /// Day of week for this event (monday, tuesday, etc.)
  final String dayOfWeek;

  /// Sort order for multiple workouts on the same date
  final int sortOrder;

  /// Whether this is a rest day
  final bool isRestDay;

  /// Optional notes for this calendar event
  final String? notes;

  /// Optional calendar color for visual indicators
  final String? calendarColor;

  /// Whether this workout has been completed
  final bool? isCompleted;

  /// Date when the workout was completed
  final DateTime? completionDate;

  /// Expanded plan name (from relation)
  final String? planName;

  /// Expanded plan description (from relation)
  final String? planDescription;

  const CalendarEvent({
    required super.id,
    required super.created,
    required super.updated,
    required this.planId,
    required this.workoutId,
    required this.scheduledDate,
    required this.dayOfWeek,
    this.sortOrder = 0,
    this.isRestDay = false,
    this.notes,
    this.calendarColor,
    this.isCompleted,
    this.completionDate,
    this.planName,
    this.planDescription,
  });

  /// Create CalendarEvent from PocketBase JSON response
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    try {
      final baseFields = BasePocketBaseModel.extractBaseFields(json);

      return CalendarEvent(
        id: baseFields['id'] as String,
        created: baseFields['created'] as DateTime,
        updated: baseFields['updated'] as DateTime,
        planId: json['plan_id']?.toString() ?? '',
        workoutId: json['workoutId']?.toString() ?? '',
        scheduledDate: json['scheduled_date'] != null
            ? DateTime.parse(json['scheduled_date'].toString())
            : DateTime.now(),
        dayOfWeek: json['day_of_week']?.toString() ?? '',
        sortOrder: json['sort_order'] as int? ?? 0,
        isRestDay: json['is_rest_day'] as bool? ?? false,
        notes: json['notes']?.toString(),
        calendarColor: json['calendar_color']?.toString(),
        isCompleted: json['is_completed'] as bool?,
        completionDate: json['completion_date'] != null
            ? DateTime.parse(json['completion_date'].toString())
            : null,
        planName: _extractExpandedField(json, 'plan_id', 'name'),
        planDescription: _extractExpandedField(json, 'plan_id', 'description'),
      );
    } catch (e) {
      throw FormatException('Failed to parse CalendarEvent from JSON: $e');
    }
  }

  /// Extract expanded field from PocketBase response
  static String? _extractExpandedField(
    Map<String, dynamic> json,
    String relation,
    String field,
  ) {
    final expand = json['expand'];
    if (expand == null || expand is! Map<String, dynamic>) {
      return null;
    }

    final relationData = expand[relation];
    if (relationData == null || relationData is! Map<String, dynamic>) {
      return null;
    }

    return relationData[field]?.toString();
  }

  /// Convert CalendarEvent to PocketBase JSON format
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'plan_id': planId,
      'workout_id': workoutId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'day_of_week': dayOfWeek,
      'sort_order': sortOrder,
      'is_rest_day': isRestDay,
      if (notes != null) 'notes': notes,
      if (calendarColor != null) 'calendar_color': calendarColor,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completionDate != null)
        'completion_date': completionDate!.toIso8601String(),
    };
  }

  @override
  CalendarEvent copyWith({
    String? id,
    DateTime? created,
    DateTime? updated,
    String? planId,
    String? workoutId,
    DateTime? scheduledDate,
    String? dayOfWeek,
    int? sortOrder,
    bool? isRestDay,
    String? notes,
    String? calendarColor,
    bool? isCompleted,
    DateTime? completionDate,
    String? planName,
    String? planDescription,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      planId: planId ?? this.planId,
      workoutId: workoutId ?? this.workoutId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      sortOrder: sortOrder ?? this.sortOrder,
      isRestDay: isRestDay ?? this.isRestDay,
      notes: notes ?? this.notes,
      calendarColor: calendarColor ?? this.calendarColor,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDate: completionDate ?? this.completionDate,
      planName: planName ?? this.planName,
      planDescription: planDescription ?? this.planDescription,
    );
  }

  /// Get date key for grouping events by date
  String get dateKey {
    return '${scheduledDate.year.toString().padLeft(4, '0')}-'
        '${scheduledDate.month.toString().padLeft(2, '0')}-'
        '${scheduledDate.day.toString().padLeft(2, '0')}';
  }

  /// Check if this event is in the past
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    return eventDate.isBefore(today);
  }

  /// Check if this event is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  /// Check if this event is in the future
  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    return eventDate.isAfter(today);
  }

  /// Create a basic calendar event for testing
  factory CalendarEvent.create({
    required String planId,
    required String workoutId,
    required DateTime scheduledDate,
    String? dayOfWeek,
    int sortOrder = 0,
    bool isRestDay = false,
    String? notes,
    String? calendarColor,
  }) {
    final now = DateTime.now();
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final computedDayOfWeek =
        dayOfWeek ?? days[scheduledDate.weekday % 7];

    return CalendarEvent(
      id: '', // Will be set by PocketBase
      created: now,
      updated: now,
      planId: planId,
      workoutId: workoutId,
      scheduledDate: scheduledDate,
      dayOfWeek: computedDayOfWeek,
      sortOrder: sortOrder,
      isRestDay: isRestDay,
      notes: notes,
      calendarColor: calendarColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent &&
        other.id == id &&
        other.planId == planId &&
        other.workoutId == workoutId &&
        other.scheduledDate == scheduledDate;
  }

  @override
  int get hashCode => Object.hash(id, planId, workoutId, scheduledDate);

  @override
  String toString() {
    return 'CalendarEvent(id: $id, planId: $planId, workoutId: $workoutId, '
        'date: $dateKey, dayOfWeek: $dayOfWeek)';
  }
}
