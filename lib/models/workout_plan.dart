import 'dart:convert';

class WorkoutPlan {
  final String id;
  final String userId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime startDate;
  final Map<String, List<String>>
  schedule; // Map of date strings to workout IDs
  final bool isActive;

  WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.startDate,
    required this.schedule,
    this.isActive = true,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> scheduleMap = {};
    
    // Handle both old format (schedule) and new format (workoutDays)
    final scheduleData = json['schedule'] ?? json['workoutDays'];
    if (scheduleData != null) {
      if (scheduleData is String) {
        // Parse JSON string to Map
        try {
          final Map<String, dynamic> scheduleJson = jsonDecode(scheduleData);
          scheduleMap = scheduleJson.map(
            (key, value) => MapEntry(key, List<String>.from(value as List)),
          );
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
      id: json['\$id'] as String,
      userId: json['userId'] as String? ?? '', // Handle missing userId
      name: json['name'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.parse(json['createdAt'] as String), // Fallback to createdAt
      schedule: scheduleMap,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'schedule': jsonEncode(schedule),
      'isActive': isActive,
    };
  }

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? startDate,
    Map<String, List<String>>? schedule,
    bool? isActive,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      schedule: schedule ?? this.schedule,
      isActive: isActive ?? this.isActive,
    );
  }
}
