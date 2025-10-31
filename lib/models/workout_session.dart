import 'dart:convert';
import 'base_model.dart';

enum WorkoutSessionStatus { planned, inProgress, completed }

class WorkoutSessionSet {
  final String setId;
  final int setNumber;
  final int targetReps;
  final double targetWeight;
  final int? actualReps;
  final double? actualWeight;
  final bool completed;
  final Duration? restTime;

  WorkoutSessionSet({
    required this.setId,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    this.actualReps,
    this.actualWeight,
    this.completed = false,
    this.restTime,
  });

  factory WorkoutSessionSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionSet(
      setId: json['setId'] as String,
      setNumber: json['setNumber'] as int,
      targetReps: json['targetReps'] as int,
      targetWeight: (json['targetWeight'] as num).toDouble(),
      actualReps: json['actualReps'] as int?,
      actualWeight: json['actualWeight'] != null
          ? (json['actualWeight'] as num).toDouble()
          : null,
      completed: json['completed'] as bool? ?? false,
      restTime: json['restTime'] != null
          ? Duration(seconds: json['restTime'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setId': setId,
      'setNumber': setNumber,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'actualReps': actualReps,
      'actualWeight': actualWeight,
      'completed': completed,
      'restTime': restTime?.inSeconds,
    };
  }

  WorkoutSessionSet copyWith({
    String? setId,
    int? setNumber,
    int? targetReps,
    double? targetWeight,
    int? actualReps,
    double? actualWeight,
    bool? completed,
    Duration? restTime,
  }) {
    return WorkoutSessionSet(
      setId: setId ?? this.setId,
      setNumber: setNumber ?? this.setNumber,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      actualReps: actualReps ?? this.actualReps,
      actualWeight: actualWeight ?? this.actualWeight,
      completed: completed ?? this.completed,
      restTime: restTime ?? this.restTime,
    );
  }
}

class WorkoutSessionExercise {
  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSessionSet> sets;
  final int? targetSets;
  final int? targetReps;
  final double? targetWeight;

  WorkoutSessionExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
  });

  factory WorkoutSessionExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionExercise(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: (json['sets'] as List).map((set) {
        if (set is Map<String, dynamic>) {
          return WorkoutSessionSet.fromJson(set);
        } else if (set is Map) {
          return WorkoutSessionSet.fromJson(Map<String, dynamic>.from(set));
        }
        throw FormatException('Invalid set data format');
      }).toList(),
      targetSets: json['targetSets'] as int?,
      targetReps: json['targetReps'] as int?,
      targetWeight: json['targetWeight'] != null
          ? (json['targetWeight'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((set) => set.toJson()).toList(),
      'targetSets': targetSets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
    };
  }

  WorkoutSessionExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    List<WorkoutSessionSet>? sets,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
  }) {
    return WorkoutSessionExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
    );
  }

  bool get isCompleted => sets.every((set) => set.completed);
  int get completedSets => sets.where((set) => set.completed).length;
}

class WorkoutSession extends BasePocketBaseModel with UserOwnedModel {
  /// Name of the workout session
  final String name;

  /// Description of the workout session
  final String description;

  /// Current status of the workout session
  final WorkoutSessionStatus status;

  /// List of exercises in this workout session
  final List<WorkoutSessionExercise> exercises;

  /// When this session was scheduled for (optional)
  final DateTime? scheduledDate;

  /// When the workout session was started (optional)
  final DateTime? startedAt;

  /// When the workout session was completed (optional)
  final DateTime? completedAt;

  /// ID of the user who owns this workout session
  @override
  final String userId;

  const WorkoutSession({
    required super.id,
    required super.created,
    required super.updated,
    required this.userId,
    required this.name,
    this.description = '',
    this.status = WorkoutSessionStatus.planned,
    this.exercises = const [],
    this.scheduledDate,
    this.startedAt,
    this.completedAt,
  });

  /// Create a WorkoutSession from PocketBase JSON response
  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    final baseFields = BasePocketBaseModel.extractBaseFields(json);

    // Parse exercises that might be stored as JSON strings
    List<WorkoutSessionExercise> parseExercises(dynamic exercisesData) {
      if (exercisesData == null) return [];

      if (exercisesData is List) {
        return exercisesData.map((exercise) {
          if (exercise is String) {
            final decoded = jsonDecode(exercise);
            if (decoded is Map<String, dynamic>) {
              return WorkoutSessionExercise.fromJson(decoded);
            }
            throw FormatException('Invalid JSON format in exercise string');
          } else if (exercise is Map<String, dynamic>) {
            return WorkoutSessionExercise.fromJson(exercise);
          }
          throw FormatException('Invalid exercise data format');
        }).toList();
      }
      return [];
    }

    final exercises = parseExercises(json['exercises']);

    return WorkoutSession(
      id: baseFields['id'] as String,
      created: baseFields['created'] as DateTime,
      updated: baseFields['updated'] as DateTime,
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: _parseStatus(json['status']?.toString()),
      exercises: exercises,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'].toString())
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'].toString())
          : null,
    );
  }

  /// Convert WorkoutSession to JSON for PocketBase operations
  @override
  Map<String, dynamic> toJson() {
    final result = {
      'user_id': userId,
      'name': name,
      'description': description,
      'status': status.name,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };

    if (scheduledDate != null) {
      result['scheduled_date'] = scheduledDate!.toIso8601String();
    }
    if (startedAt != null) {
      result['started_at'] = startedAt!.toIso8601String();
    }
    if (completedAt != null) {
      result['completed_at'] = completedAt!.toIso8601String();
    }

    return result;
  }

  static WorkoutSessionStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        return WorkoutSessionStatus.inProgress;
      case 'completed':
        return WorkoutSessionStatus.completed;
      case 'planned':
      default:
        return WorkoutSessionStatus.planned;
    }
  }

  /// Create a copy of this WorkoutSession with updated fields
  @override
  WorkoutSession copyWith({
    String? id,
    DateTime? created,
    DateTime? updated,
    String? userId,
    String? name,
    String? description,
    WorkoutSessionStatus? status,
    List<WorkoutSessionExercise>? exercises,
    DateTime? scheduledDate,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Helper getters
  bool get isCompleted => status == WorkoutSessionStatus.completed;
  bool get isInProgress => status == WorkoutSessionStatus.inProgress;
  bool get isPlanned => status == WorkoutSessionStatus.planned;

  Duration? get duration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    } else if (startedAt != null && isInProgress) {
      return DateTime.now().difference(startedAt!);
    }
    return null;
  }

  int get totalExercises => exercises.length;
  int get completedExercises => exercises.where((ex) => ex.isCompleted).length;
  int get totalSets => exercises.fold(0, (sum, ex) => sum + ex.sets.length);
  int get completedSets =>
      exercises.fold(0, (sum, ex) => sum + ex.completedSets);

  double get progressPercentage {
    if (totalSets == 0) return 0.0;
    return (completedSets / totalSets) * 100;
  }
}

class WorkoutSessionStats {
  final int totalSessions;
  final int completedSessions;
  final int totalWorkoutTime; // in minutes
  final int totalSets;
  final double totalWeightLifted;
  final DateTime periodStart;
  final DateTime periodEnd;

  WorkoutSessionStats({
    required this.totalSessions,
    required this.completedSessions,
    required this.totalWorkoutTime,
    required this.totalSets,
    required this.totalWeightLifted,
    required this.periodStart,
    required this.periodEnd,
  });

  factory WorkoutSessionStats.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionStats(
      totalSessions: json['totalSessions'] as int,
      completedSessions: json['completedSessions'] as int,
      totalWorkoutTime: json['totalWorkoutTime'] as int,
      totalSets: json['totalSets'] as int,
      totalWeightLifted: (json['totalWeightLifted'] as num).toDouble(),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'totalWorkoutTime': totalWorkoutTime,
      'totalSets': totalSets,
      'totalWeightLifted': totalWeightLifted,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
    };
  }

  double get completionRate =>
      totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0.0;
  double get averageWorkoutTime =>
      completedSessions > 0 ? totalWorkoutTime / completedSessions : 0.0;
}
