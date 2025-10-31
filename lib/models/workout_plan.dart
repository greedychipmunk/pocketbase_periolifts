import 'dart:convert';
import 'base_model.dart';

/// Workout plan model representing structured workout schedules
///
/// Integrates with PocketBase and provides:
/// - Schedule management with date-to-workout mapping
/// - User ownership and customization
/// - Plan activation and deactivation
/// - Progress tracking integration
class WorkoutPlan extends BasePocketBaseModel with UserOwnedModel {
  /// Name of the workout plan
  final String name;

  /// Description of the workout plan
  final String description;

  /// When the plan should start
  final DateTime startDate;

  /// Map of date strings to workout IDs
  /// Format: "YYYY-MM-DD" -> ["workoutId1", "workoutId2"]
  final Map<String, List<String>> schedule;

  /// Whether this plan is currently active
  final bool isActive;

  /// ID of the user who owns this workout plan
  @override
  final String userId;

  const WorkoutPlan({
    required super.id,
    required super.created,
    required super.updated,
    required this.userId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.schedule,
    this.isActive = true,
  });

  /// Create WorkoutPlan from PocketBase JSON response
  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    try {
      // Extract base fields using the helper
      final baseFields = BasePocketBaseModel.extractBaseFields(json);

      // Parse schedule data with proper error handling
      Map<String, List<String>> scheduleMap = {};
      final scheduleData = json['schedule'] ?? json['workoutDays'];

      if (scheduleData != null) {
        if (scheduleData is String) {
          // Parse JSON string to Map
          try {
            final decoded = jsonDecode(scheduleData);
            if (decoded is Map<String, dynamic>) {
              final Map<String, dynamic> scheduleJson = decoded;
              scheduleMap = scheduleJson.map(
                (key, value) => MapEntry(key, List<String>.from(value as List)),
              );
            }
          } catch (e) {
            // If parsing fails, default to empty map
            scheduleMap = {};
          }
        } else if (scheduleData is Map<String, dynamic>) {
          scheduleMap = scheduleData.map(
            (key, value) => MapEntry(key, List<String>.from(value as List)),
          );
        } else if (scheduleData is List) {
          // Handle case where schedule is stored as an empty list in database
          scheduleMap = {};
        }
      }

      return WorkoutPlan(
        id: baseFields['id'] as String,
        created: baseFields['created'] as DateTime,
        updated: baseFields['updated'] as DateTime,
        userId: json['user_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        startDate: json['start_date'] != null
            ? DateTime.parse(json['start_date'].toString())
            : baseFields['created'] as DateTime, // Fallback to created date
        schedule: scheduleMap,
        isActive: json['is_active'] as bool? ?? true,
      );
    } catch (e) {
      throw FormatException('Failed to parse WorkoutPlan from JSON: $e');
    }
  }

  /// Convert WorkoutPlan to PocketBase JSON format
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'user_id': userId,
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'schedule': jsonEncode(schedule),
      'is_active': isActive,
    };
  }

  @override
  WorkoutPlan copyWith({
    String? id,
    DateTime? created,
    DateTime? updated,
    String? userId,
    String? name,
    String? description,
    DateTime? startDate,
    Map<String, List<String>>? schedule,
    bool? isActive,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      schedule: schedule ?? this.schedule,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get workouts scheduled for a specific date
  List<String> getWorkoutsForDate(DateTime date) {
    final dateString = _formatDateKey(date);
    return schedule[dateString] ?? [];
  }

  /// Add workout to a specific date
  WorkoutPlan addWorkoutToDate(DateTime date, String workoutId) {
    final dateString = _formatDateKey(date);
    final updatedSchedule = Map<String, List<String>>.from(schedule);

    if (updatedSchedule.containsKey(dateString)) {
      if (!updatedSchedule[dateString]!.contains(workoutId)) {
        updatedSchedule[dateString] = [
          ...updatedSchedule[dateString]!,
          workoutId,
        ];
      }
    } else {
      updatedSchedule[dateString] = [workoutId];
    }

    return copyWith(schedule: updatedSchedule);
  }

  /// Remove workout from a specific date
  WorkoutPlan removeWorkoutFromDate(DateTime date, String workoutId) {
    final dateString = _formatDateKey(date);
    final updatedSchedule = Map<String, List<String>>.from(schedule);

    if (updatedSchedule.containsKey(dateString)) {
      updatedSchedule[dateString] = updatedSchedule[dateString]!
          .where((id) => id != workoutId)
          .toList();

      // Remove empty date entries
      if (updatedSchedule[dateString]!.isEmpty) {
        updatedSchedule.remove(dateString);
      }
    }

    return copyWith(schedule: updatedSchedule);
  }

  /// Check if the plan has any workouts scheduled
  bool get hasScheduledWorkouts => schedule.isNotEmpty;

  /// Get all unique workout IDs in this plan
  Set<String> get allWorkoutIds {
    return schedule.values.expand((workoutIds) => workoutIds).toSet();
  }

  /// Get the date range covered by this plan
  ({DateTime? earliest, DateTime? latest}) get dateRange {
    if (schedule.isEmpty) {
      return (earliest: null, latest: null);
    }

    final dates = schedule.keys
        .map((dateString) => DateTime.tryParse(dateString))
        .where((date) => date != null)
        .cast<DateTime>()
        .toList();

    if (dates.isEmpty) {
      return (earliest: null, latest: null);
    }

    dates.sort();
    return (earliest: dates.first, latest: dates.last);
  }

  /// Activate or deactivate the plan
  WorkoutPlan activate() => copyWith(isActive: true);
  WorkoutPlan deactivate() => copyWith(isActive: false);

  /// Format date as string key for schedule map
  static String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Create a basic workout plan for testing or initial setup
  factory WorkoutPlan.create({
    required String userId,
    required String name,
    required String description,
    DateTime? startDate,
    Map<String, List<String>>? schedule,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return WorkoutPlan(
      id: '', // Will be set by PocketBase
      created: now,
      updated: now,
      userId: userId,
      name: name,
      description: description,
      startDate: startDate ?? now,
      schedule: schedule ?? {},
      isActive: isActive,
    );
  }

  /// Create empty workout plan
  factory WorkoutPlan.empty() {
    final now = DateTime.now();
    return WorkoutPlan(
      id: '',
      created: now,
      updated: now,
      userId: '',
      name: '',
      description: '',
      startDate: now,
      schedule: {},
      isActive: false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutPlan &&
        other.id == id &&
        other.userId == userId &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, userId, name);

  @override
  String toString() {
    return 'WorkoutPlan(id: $id, userId: $userId, name: $name, isActive: $isActive)';
  }
}
