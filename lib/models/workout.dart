import 'package:appwrite/appwrite.dart';
import 'dart:convert';

class WorkoutSet {
  final int reps;
  final double weight;
  final Duration? restTime;

  WorkoutSet({required this.reps, required this.weight, this.restTime});

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      reps: json['reps'] as int,
      weight: json['weight'].toDouble(),
      restTime: json['restTime'] != null
          ? Duration(seconds: json['restTime'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'reps': reps, 'weight': weight, 'restTime': restTime?.inSeconds};
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSet> sets;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: (json['sets'] as List)
          .map((set) => WorkoutSet.fromJson(set))
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
}

class WorkoutProgress {
  final int currentExerciseIndex;
  final int currentSetIndex;
  final List<List<bool>> completedSets;
  final List<List<WorkoutSet>> modifiedSets;
  final DateTime? lastSavedAt;

  WorkoutProgress({
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required this.completedSets,
    required this.modifiedSets,
    this.lastSavedAt,
  });

  factory WorkoutProgress.fromJson(Map<String, dynamic> json) {
    return WorkoutProgress(
      currentExerciseIndex: json['currentExerciseIndex'] as int,
      currentSetIndex: json['currentSetIndex'] as int,
      completedSets: (json['completedSets'] as List)
          .map((exerciseSets) => (exerciseSets as List)
              .map((completed) => completed as bool)
              .toList())
          .toList(),
      modifiedSets: (json['modifiedSets'] as List)
          .map((exerciseSets) => (exerciseSets as List)
              .map((set) => WorkoutSet.fromJson(set))
              .toList())
          .toList(),
      lastSavedAt: json['lastSavedAt'] != null
          ? DateTime.parse(json['lastSavedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentExerciseIndex': currentExerciseIndex,
      'currentSetIndex': currentSetIndex,
      'completedSets': completedSets,
      'modifiedSets': modifiedSets.map((exerciseSets) => 
          exerciseSets.map((set) => set.toJson()).toList()).toList(),
      'lastSavedAt': lastSavedAt?.toIso8601String(),
    };
  }
}

class Workout {
  final String id;
  final String userId;
  final String name;
  final String description;
  final DateTime scheduledDate;
  final List<WorkoutExercise> exercises;
  final bool isCompleted;
  final DateTime? completedDate;
  final bool isInProgress;
  final WorkoutProgress? progress;

  Workout({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    required this.scheduledDate,
    required this.exercises,
    this.isCompleted = false,
    this.completedDate,
    this.isInProgress = false,
    this.progress,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['\$id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      exercises: (json['exercises'] as List)
          .map((exercise) {
            if (exercise is String) {
              // Parse JSON string to Map if stored as string
              final Map<String, dynamic> exerciseMap = jsonDecode(exercise);
              return WorkoutExercise.fromJson(exerciseMap);
            } else {
              // Direct Map if not stored as string
              return WorkoutExercise.fromJson(exercise);
            }
          })
          .toList(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      isInProgress: json.containsKey('isInProgress') 
          ? (json['isInProgress'] as bool? ?? false)
          : false,
      progress: json.containsKey('progress') && json['progress'] != null
          ? WorkoutProgress.fromJson(json['progress'] is String
              ? jsonDecode(json['progress'] as String)
              : json['progress'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final result = {
      'id': id, // Include id field as required by collection schema
      'userId': userId,
      'name': name,
      'description': description,
      'scheduledDate': scheduledDate.toIso8601String(),
      // Convert exercises to JSON strings as expected by Appwrite schema
      'exercises': exercises.map((exercise) {
        final exerciseJson = jsonEncode(exercise.toJson());
        // Ensure each exercise JSON string is within Appwrite's 2048 char limit
        if (exerciseJson.length > 2048) {
          print('Warning: Exercise JSON too long (${exerciseJson.length} chars), truncating...');
          return exerciseJson.substring(0, 2045) + '...'; // Leave room for truncation indicator
        }
        return exerciseJson;
      }).toList(),
      'isCompleted': isCompleted,
    };

    // Add optional fields only if they have meaningful values
    if (completedDate != null) {
      result['completedDate'] = completedDate!.toIso8601String();
    }
    
    // Only include isInProgress and progress if the workout is actually in progress
    if (isInProgress) {
      result['isInProgress'] = isInProgress;
      if (progress != null) {
        result['progress'] = jsonEncode(progress!.toJson());
      }
    }

    return result;
  }

  Workout copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    DateTime? scheduledDate,
    List<WorkoutExercise>? exercises,
    bool? isCompleted,
    DateTime? completedDate,
    bool? isInProgress,
    WorkoutProgress? progress,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      exercises: exercises ?? this.exercises,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      isInProgress: isInProgress ?? this.isInProgress,
      progress: progress ?? this.progress,
    );
  }
}
