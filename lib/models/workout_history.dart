import 'dart:convert';

/// Workout history entry status matching the API design
enum WorkoutHistoryStatus {
  planned,
  inProgress,
  completed,
}

/// Exercise progress data for analytics
class ExerciseProgressData {
  final String exerciseId;
  final String exerciseName;
  final double maxWeight;
  final double avgWeight;
  final int totalReps;
  final double totalVolume;

  ExerciseProgressData({
    required this.exerciseId,
    required this.exerciseName,
    required this.maxWeight,
    required this.avgWeight,
    required this.totalReps,
    required this.totalVolume,
  });

  factory ExerciseProgressData.fromJson(Map<String, dynamic> json) {
    return ExerciseProgressData(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      maxWeight: (json['maxWeight'] as num).toDouble(),
      avgWeight: (json['avgWeight'] as num).toDouble(),
      totalReps: json['totalReps'] as int,
      totalVolume: (json['totalVolume'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'maxWeight': maxWeight,
      'avgWeight': avgWeight,
      'totalReps': totalReps,
      'totalVolume': totalVolume,
    };
  }
}

/// Workout history statistics for analytics dashboard
class WorkoutHistoryStats {
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalWorkouts;
  final int completedWorkouts;
  final Duration totalDuration;
  final double totalWeightLifted;
  final Map<String, int> exerciseFrequency;
  final List<ExerciseProgressData> exerciseProgress;

  WorkoutHistoryStats({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalWorkouts,
    required this.completedWorkouts,
    required this.totalDuration,
    required this.totalWeightLifted,
    required this.exerciseFrequency,
    required this.exerciseProgress,
  });

  factory WorkoutHistoryStats.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryStats(
      userId: json['userId'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      totalWorkouts: json['totalWorkouts'] as int,
      completedWorkouts: json['completedWorkouts'] as int,
      totalDuration: Duration(seconds: json['totalDuration'] as int),
      totalWeightLifted: (json['totalWeightLifted'] as num).toDouble(),
      exerciseFrequency: Map<String, int>.from(json['exerciseFrequency'] as Map),
      exerciseProgress: (json['exerciseProgress'] as List)
          .map((item) => ExerciseProgressData.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalWorkouts': totalWorkouts,
      'completedWorkouts': completedWorkouts,
      'totalDuration': totalDuration.inSeconds,
      'totalWeightLifted': totalWeightLifted,
      'exerciseFrequency': exerciseFrequency,
      'exerciseProgress': exerciseProgress.map((item) => item.toJson()).toList(),
    };
  }

  /// Completion rate as percentage
  double get completionRate => totalWorkouts > 0 ? (completedWorkouts / totalWorkouts) * 100 : 0.0;
  
  /// Average workout duration
  Duration get averageDuration => completedWorkouts > 0 
      ? Duration(seconds: totalDuration.inSeconds ~/ completedWorkouts)
      : Duration.zero;
}

/// Set data for workout history exercises
class WorkoutHistorySet {
  final int reps;
  final double weight;
  final Duration? restTime;
  final bool completed;

  WorkoutHistorySet({
    required this.reps,
    required this.weight,
    this.restTime,
    this.completed = false,
  });

  factory WorkoutHistorySet.fromJson(Map<String, dynamic> json) {
    return WorkoutHistorySet(
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      restTime: json['restTime'] != null
          ? Duration(seconds: json['restTime'] as int)
          : null,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'restTime': restTime?.inSeconds,
      'completed': completed,
    };
  }

  /// Calculate volume (weight × reps) if completed
  double get volume => completed ? weight * reps : 0.0;
}

/// Exercise data for workout history
class WorkoutHistoryExercise {
  final String exerciseId;
  final String exerciseName;
  final List<WorkoutHistorySet> sets;

  WorkoutHistoryExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  factory WorkoutHistoryExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryExercise(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: (json['sets'] as List)
          .map((set) => WorkoutHistorySet.fromJson(set))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((set) => set.toJson()).toList(),
    };
  }

  /// Total completed sets
  int get completedSets => sets.where((set) => set.completed).length;
  
  /// Total sets
  int get totalSets => sets.length;
  
  /// Total volume for this exercise
  double get totalVolume => sets.fold(0.0, (sum, set) => sum + set.volume);
  
  /// Maximum weight used in this exercise
  double get maxWeight => sets.isEmpty ? 0.0 : 
      sets.map((set) => set.completed ? set.weight : 0.0).reduce((a, b) => a > b ? a : b);
      
  /// Average weight used in completed sets
  double get avgWeight {
    final completedSetsWeights = sets.where((set) => set.completed).map((set) => set.weight);
    if (completedSetsWeights.isEmpty) return 0.0;
    return completedSetsWeights.reduce((a, b) => a + b) / completedSetsWeights.length;
  }
}

/// Main workout history entry matching the API design
class WorkoutHistoryEntry {
  final String id;
  final String userId;
  final String name;
  final WorkoutHistoryStatus status;
  final DateTime? scheduledDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Duration? duration;
  final List<WorkoutHistoryExercise> exercises;
  final int totalSets;
  final int totalReps;
  final double totalWeightLifted;
  final String notes;

  WorkoutHistoryEntry({
    required this.id,
    required this.userId,
    required this.name,
    this.status = WorkoutHistoryStatus.planned,
    this.scheduledDate,
    this.startedAt,
    this.completedAt,
    this.duration,
    this.exercises = const [],
    this.totalSets = 0,
    this.totalReps = 0,
    this.totalWeightLifted = 0.0,
    this.notes = '',
  });

  factory WorkoutHistoryEntry.fromJson(Map<String, dynamic> json) {
    // Handle exercises that might be stored as JSON strings
    List<WorkoutHistoryExercise> parseExercises(dynamic exercisesData) {
      if (exercisesData == null) return [];
      
      if (exercisesData is List) {
        return exercisesData.map((exercise) {
          if (exercise is String) {
            final Map<String, dynamic> exerciseMap = jsonDecode(exercise);
            return WorkoutHistoryExercise.fromJson(exerciseMap);
          } else {
            return WorkoutHistoryExercise.fromJson(exercise);
          }
        }).toList();
      }
      return [];
    }

    final exercises = parseExercises(json['exercises']);
    
    return WorkoutHistoryEntry(
      id: json['\$id'] as String? ?? json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      status: _parseStatus(json['status'] as String?),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      exercises: exercises,
      totalSets: json['totalSets'] as int? ?? _calculateTotalSets(exercises),
      totalReps: json['totalReps'] as int? ?? _calculateTotalReps(exercises),
      totalWeightLifted: json['totalWeightLifted'] != null
          ? (json['totalWeightLifted'] as num).toDouble()
          : _calculateTotalWeightLifted(exercises),
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final result = {
      'id': id,
      'userId': userId,
      'name': name,
      'status': status.name,
      'exercises': exercises.map((exercise) {
        final exerciseJson = jsonEncode(exercise.toJson());
        // Handle Appwrite's 2048 character limit for string attributes
        if (exerciseJson.length > 2048) {
          print('Warning: Exercise JSON too long (${exerciseJson.length} chars), truncating...');
          return exerciseJson.substring(0, 2045) + '...';
        }
        return exerciseJson;
      }).toList(),
      'totalSets': totalSets,
      'totalReps': totalReps,
      'totalWeightLifted': totalWeightLifted,
      'notes': notes,
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
    if (duration != null) {
      result['duration'] = duration!.inSeconds;
    }

    return result;
  }

  static WorkoutHistoryStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        return WorkoutHistoryStatus.inProgress;
      case 'completed':
        return WorkoutHistoryStatus.completed;
      case 'planned':
      default:
        return WorkoutHistoryStatus.planned;
    }
  }

  static int _calculateTotalSets(List<WorkoutHistoryExercise> exercises) {
    return exercises.fold(0, (sum, exercise) => sum + exercise.totalSets);
  }

  static int _calculateTotalReps(List<WorkoutHistoryExercise> exercises) {
    return exercises.fold(0, (sum, exercise) => 
        sum + exercise.sets.where((set) => set.completed).fold(0, (reps, set) => reps + set.reps));
  }

  static double _calculateTotalWeightLifted(List<WorkoutHistoryExercise> exercises) {
    return exercises.fold(0.0, (sum, exercise) => sum + exercise.totalVolume);
  }

  WorkoutHistoryEntry copyWith({
    String? id,
    String? userId,
    String? name,
    WorkoutHistoryStatus? status,
    DateTime? scheduledDate,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? duration,
    List<WorkoutHistoryExercise>? exercises,
    int? totalSets,
    int? totalReps,
    double? totalWeightLifted,
    String? notes,
  }) {
    return WorkoutHistoryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
      exercises: exercises ?? this.exercises,
      totalSets: totalSets ?? this.totalSets,
      totalReps: totalReps ?? this.totalReps,
      totalWeightLifted: totalWeightLifted ?? this.totalWeightLifted,
      notes: notes ?? this.notes,
    );
  }

  /// Helper getters
  bool get isCompleted => status == WorkoutHistoryStatus.completed;
  bool get isInProgress => status == WorkoutHistoryStatus.inProgress;
  bool get isPlanned => status == WorkoutHistoryStatus.planned;
  
  /// Calculate completion percentage
  double get completionPercentage {
    if (totalSets == 0) return 0.0;
    final completedSets = exercises.fold(0, (sum, ex) => sum + ex.completedSets);
    return (completedSets / totalSets) * 100;
  }
}