import 'dart:convert';

enum WorkoutSessionStatus {
  planned,
  inProgress,
  completed,
}

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
      sets: (json['sets'] as List)
          .map((set) => WorkoutSessionSet.fromJson(set))
          .toList(),
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

class WorkoutSession {
  final String sessionId;
  final String userId;
  final String name;
  final String description;
  final WorkoutSessionStatus status;
  final List<WorkoutSessionExercise> exercises;
  final DateTime? scheduledDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutSession({
    required this.sessionId,
    required this.userId,
    required this.name,
    this.description = '',
    this.status = WorkoutSessionStatus.planned,
    this.exercises = const [],
    this.scheduledDate,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      sessionId: json['\$id'] as String? ?? json['sessionId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      exercises: json['exercises'] != null
          ? (json['exercises'] as List).map((exercise) {
              if (exercise is String) {
                final Map<String, dynamic> exerciseMap = jsonDecode(exercise);
                return WorkoutSessionExercise.fromJson(exerciseMap);
              } else {
                return WorkoutSessionExercise.fromJson(exercise);
              }
            }).toList()
          : [],
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final result = {
      'sessionId': sessionId,
      'userId': userId,
      'name': name,
      'description': description,
      'status': status.name,
      'exercises': exercises.map((exercise) {
        final exerciseJson = jsonEncode(exercise.toJson());
        if (exerciseJson.length > 2048) {
          print('Warning: Exercise JSON too long (${exerciseJson.length} chars), truncating...');
          return exerciseJson.substring(0, 2045) + '...';
        }
        return exerciseJson;
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (scheduledDate != null) {
      result['scheduledDate'] = scheduledDate!.toIso8601String();
    }
    if (startedAt != null) {
      result['startedAt'] = startedAt!.toIso8601String();
    }
    if (completedAt != null) {
      result['completedAt'] = completedAt!.toIso8601String();
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

  WorkoutSession copyWith({
    String? sessionId,
    String? userId,
    String? name,
    String? description,
    WorkoutSessionStatus? status,
    List<WorkoutSessionExercise>? exercises,
    DateTime? scheduledDate,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
  int get completedSets => exercises.fold(0, (sum, ex) => sum + ex.completedSets);
  
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

  double get completionRate => totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0.0;
  double get averageWorkoutTime => completedSessions > 0 ? totalWorkoutTime / completedSessions : 0.0;
}