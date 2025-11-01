import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';
import 'base_model.dart';
import 'dart:convert';

/// Individual set data within a workout exercise
///
/// Represents the planned parameters for a single set including
/// repetitions, weight, and optional rest time.
class WorkoutSet {
  /// Number of repetitions planned for this set
  final int reps;

  /// Weight to be used for this set (in user's preferred unit)
  final double weight;

  /// Optional rest time after completing this set
  final Duration? restTime;

  /// Optional notes for this specific set
  final String? notes;

  const WorkoutSet({
    required this.reps,
    required this.weight,
    this.restTime,
    this.notes,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      reps: json['reps'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      restTime: json['rest_time'] != null
          ? Duration(seconds: json['rest_time'] as int)
          : null,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'rest_time': restTime?.inSeconds,
      'notes': notes,
    };
  }

  WorkoutSet copyWith({
    int? reps,
    double? weight,
    Duration? restTime,
    String? notes,
  }) {
    return WorkoutSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSet &&
        other.reps == reps &&
        other.weight == weight &&
        other.restTime == restTime &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(reps, weight, restTime, notes);
  }

  @override
  String toString() {
    return 'WorkoutSet(reps: $reps, weight: $weight, restTime: $restTime)';
  }
}

/// Exercise definition within a workout template
///
/// Represents an exercise planned for inclusion in a workout with
/// its planned sets, repetitions, weight, and rest periods.
class WorkoutExercise {
  /// Reference to the Exercise document ID
  final String exerciseId;

  /// Cached exercise name for display purposes
  final String exerciseName;

  /// List of sets for this exercise
  final List<WorkoutSet> sets;

  /// Optional notes for this exercise in the workout
  final String? notes;

  const WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes,
  });

  /// Legacy factory constructor for creating exercises with uniform sets
  /// 
  /// This is useful for testing and simple workout creation where all sets
  /// have the same reps, weight, and rest time.
  factory WorkoutExercise.uniform({
    required String exerciseId,
    required String exerciseName,
    required int sets,
    required int reps,
    double? weight,
    int? restTime,
    String? notes,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: List.generate(
        sets,
        (_) => WorkoutSet(
          reps: reps,
          weight: weight ?? 0.0,
          restTime: restTime != null ? Duration(seconds: restTime) : null,
        ),
      ),
      notes: notes,
    );
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    // Parse sets - can be either a list of set objects or a simple integer
    List<WorkoutSet> parseSets() {
      final setsData = json['sets'];
      if (setsData is List) {
        return setsData.map((setJson) {
          if (setJson is Map<String, dynamic>) {
            return WorkoutSet.fromJson(setJson);
          }
          // Skip invalid set data instead of creating invalid sets
          return null;
        }).whereType<WorkoutSet>().toList();
      } else if (setsData is int && setsData > 0) {
        // Legacy format: create sets based on count with default reps/weight
        final reps = json['reps'] as int? ?? 10;
        final weight = (json['weight'] as num?)?.toDouble() ?? 0.0;
        final restTime = json['rest_time'] != null
            ? Duration(seconds: json['rest_time'] as int)
            : null;
        
        return List.generate(
          setsData,
          (_) => WorkoutSet(
            reps: reps,
            weight: weight,
            restTime: restTime,
          ),
        );
      }
      return [];
    }

    return WorkoutExercise(
      exerciseId: json['exercise_id']?.toString() ?? '',
      exerciseName: json['exercise_name']?.toString() ?? '',
      sets: parseSets(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'sets': sets.map((set) => set.toJson()).toList(),
      'notes': notes,
    };
  }

  WorkoutExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    List<WorkoutSet>? sets,
    String? notes,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutExercise &&
        other.exerciseId == exerciseId &&
        other.exerciseName == exerciseName &&
        listEquals(other.sets, sets) &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      exerciseId,
      exerciseName,
      Object.hashAll(sets),
      notes,
    );
  }

  @override
  String toString() {
    return 'WorkoutExercise(exerciseId: $exerciseId, name: $exerciseName, sets: ${sets.length})';
  }
}

/// Progress tracking data for in-progress workouts
///
/// Stores the current state of a workout in progress, including which
/// exercise and set the user is on, and tracking completion status.
class WorkoutProgress {
  /// Current exercise index in the workout
  final int currentExerciseIndex;

  /// Current set index within the current exercise
  final int currentSetIndex;

  /// Completion status for each set in each exercise
  final List<List<bool>> completedSets;

  /// Modified set values for each exercise
  final List<List<WorkoutSet>> modifiedSets;

  /// Timestamp when progress was last saved
  final DateTime lastSavedAt;

  const WorkoutProgress({
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required this.completedSets,
    required this.modifiedSets,
    required this.lastSavedAt,
  });

  factory WorkoutProgress.fromJson(Map<String, dynamic> json) {
    return WorkoutProgress(
      currentExerciseIndex: json['current_exercise_index'] as int? ?? 0,
      currentSetIndex: json['current_set_index'] as int? ?? 0,
      completedSets: _parseCompletedSets(json['completed_sets']),
      modifiedSets: _parseModifiedSets(json['modified_sets']),
      lastSavedAt: json['last_saved_at'] != null
          ? DateTime.parse(json['last_saved_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_exercise_index': currentExerciseIndex,
      'current_set_index': currentSetIndex,
      'completed_sets': completedSets,
      'modified_sets': modifiedSets
          .map((exerciseSets) => exerciseSets.map((set) => set.toJson()).toList())
          .toList(),
      'last_saved_at': lastSavedAt.toIso8601String(),
    };
  }

  WorkoutProgress copyWith({
    int? currentExerciseIndex,
    int? currentSetIndex,
    List<List<bool>>? completedSets,
    List<List<WorkoutSet>>? modifiedSets,
    DateTime? lastSavedAt,
  }) {
    return WorkoutProgress(
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      completedSets: completedSets ?? this.completedSets,
      modifiedSets: modifiedSets ?? this.modifiedSets,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  static List<List<bool>> _parseCompletedSets(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((exerciseSets) {
        if (exerciseSets is List) {
          return exerciseSets.map((set) => set == true).toList();
        }
        return <bool>[];
      }).toList();
    }
    return [];
  }

  static List<List<WorkoutSet>> _parseModifiedSets(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((exerciseSets) {
        if (exerciseSets is List) {
          return exerciseSets.map((set) {
            if (set is Map<String, dynamic>) {
              return WorkoutSet.fromJson(set);
            }
            // Skip invalid set data
            return null;
          }).whereType<WorkoutSet>().toList();
        }
        return <WorkoutSet>[];
      }).toList();
    }
    return [];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutProgress &&
        other.currentExerciseIndex == currentExerciseIndex &&
        other.currentSetIndex == currentSetIndex;
  }

  @override
  int get hashCode {
    return Object.hash(currentExerciseIndex, currentSetIndex);
  }

  @override
  String toString() {
    return 'WorkoutProgress(exercise: $currentExerciseIndex, set: $currentSetIndex, lastSaved: $lastSavedAt)';
  }
}

/// Workout template model representing a planned workout routine
///
/// A workout defines a structured exercise routine with planned exercises,
/// sets, reps, and timing. This serves as a template that can be used
/// to create workout sessions for execution.
class Workout extends BasePocketBaseModel with UserOwnedModel {
  /// Display name of the workout
  final String name;

  /// Optional detailed description of the workout
  final String? description;

  /// Estimated duration of the workout in minutes
  final int estimatedDuration;

  /// List of exercises planned for this workout
  final List<WorkoutExercise> exercises;

  /// ID of the user who created this workout
  @override
  final String userId;

  /// Scheduled date for this workout
  final DateTime? scheduledDate;

  /// Whether this workout has been completed
  final bool isCompleted;

  /// Date when the workout was completed
  final DateTime? completedDate;

  /// Whether this workout is currently in progress
  final bool isInProgress;

  /// Progress data for in-progress workouts
  final WorkoutProgress? progress;

  const Workout({
    required super.id,
    required super.created,
    required super.updated,
    required this.name,
    this.description,
    this.estimatedDuration = 0,
    required this.exercises,
    required this.userId,
    this.scheduledDate,
    this.isCompleted = false,
    this.completedDate,
    this.isInProgress = false,
    this.progress,
  });

  /// Create a Workout from PocketBase JSON response
  factory Workout.fromJson(Map<String, dynamic> json) {
    try {
      final baseFields = BasePocketBaseModel.extractBaseFields(json);

      return Workout(
        id: baseFields['id'] as String,
        created: baseFields['created'] as DateTime,
        updated: baseFields['updated'] as DateTime,
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        estimatedDuration: json['estimated_duration'] as int? ?? 0,
        exercises: _parseExercises(json['exercises']),
        userId: json['user_id']?.toString() ?? '',
        scheduledDate: json['scheduled_date'] != null
            ? DateTime.parse(json['scheduled_date'] as String)
            : null,
        isCompleted: json['is_completed'] as bool? ?? false,
        completedDate: json['completed_date'] != null
            ? DateTime.parse(json['completed_date'] as String)
            : null,
        isInProgress: json['is_in_progress'] as bool? ?? false,
        progress: json['progress'] != null
            ? WorkoutProgress.fromJson(json['progress'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      throw ValidationException(
        'Failed to parse Workout from JSON',
        originalError: e,
        fieldErrors: {'json': 'Invalid workout data format'},
      );
    }
  }

  /// Create Workout from PocketBase RecordModel
  ///
  /// This is the preferred method for creating Workout instances from PocketBase
  /// responses as it leverages the RecordModel's built-in data access methods
  /// and provides better type safety.
  factory Workout.fromRecord(RecordModel record) {
    try {
      return Workout(
        id: record.id,
        created: _parseDate(record.created) ?? DateTime.now(),
        updated: _parseDate(record.updated) ?? DateTime.now(),
        name: record.get<String>('name', ''),
        description: record.get<String>('description'),
        estimatedDuration: record.get<int>('estimated_duration', 0),
        exercises: _parseExercises(record.get<dynamic>('exercises')),
        userId: record.get<String>('user_id', ''),
        scheduledDate: _parseDate(record.get<String>('scheduled_date')),
        isCompleted: record.get<bool>('is_completed', false),
        completedDate: _parseDate(record.get<String>('completed_date')),
        isInProgress: record.get<bool>('is_in_progress', false),
        progress: record.get<dynamic>('progress') != null
            ? WorkoutProgress.fromJson(record.get<dynamic>('progress') as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      throw ValidationException(
        'Failed to create Workout from RecordModel',
        originalError: e,
        fieldErrors: {'record': 'Invalid record data format'},
      );
    }
  }

  /// Helper method to safely parse date strings
  static DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Convert Workout to JSON for PocketBase operations
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'name': name,
      'description': description,
      'estimated_duration': estimatedDuration,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'user_id': userId.isEmpty ? null : userId,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'is_completed': isCompleted,
      'completed_date': completedDate?.toIso8601String(),
      'is_in_progress': isInProgress,
      'progress': progress?.toJson(),
    };
  }

  /// Create a copy of this Workout with updated fields
  @override
  Workout copyWith({
    String? id,
    DateTime? created,
    DateTime? updated,
    String? name,
    String? description,
    int? estimatedDuration,
    List<WorkoutExercise>? exercises,
    String? userId,
    DateTime? scheduledDate,
    bool? isCompleted,
    DateTime? completedDate,
    bool? isInProgress,
    WorkoutProgress? progress,
  }) {
    return Workout(
      id: id ?? this.id,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      name: name ?? this.name,
      description: description ?? this.description,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      exercises: exercises ?? this.exercises,
      userId: userId ?? this.userId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      isInProgress: isInProgress ?? this.isInProgress,
      progress: progress ?? this.progress,
    );
  }

  /// Parse exercises from various JSON formats
  static List<WorkoutExercise> _parseExercises(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) {
          return WorkoutExercise.fromJson(item);
        } else if (item is String) {
          try {
            final dynamic decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return WorkoutExercise.fromJson(decoded);
            }
          } catch (e) {
            // If parsing fails, return a default exercise
          }
          return const WorkoutExercise(
            exerciseId: '',
            exerciseName: 'Invalid Exercise',
            sets: [],
          );
        }
        return const WorkoutExercise(
          exerciseId: '',
          exerciseName: 'Unknown Exercise',
          sets: [],
        );
      }).toList();
    }

    return [];
  }

  /// Calculate total estimated sets across all exercises
  int get totalSets {
    return exercises.fold(0, (total, exercise) => total + exercise.sets.length);
  }

  /// Calculate total estimated repetitions across all exercises
  int get totalReps {
    return exercises.fold(
      0,
      (total, exercise) => total + exercise.sets.fold(0, (sum, set) => sum + set.reps),
    );
  }

  /// Get list of unique exercise IDs in this workout
  List<String> get exerciseIds {
    return exercises.map((exercise) => exercise.exerciseId).toSet().toList();
  }

  /// Check if this workout has any exercises
  bool get hasExercises {
    return exercises.isNotEmpty;
  }

  /// Check if all exercises have valid exercise IDs
  bool get isValid {
    return hasExercises &&
        exercises.every((exercise) => exercise.exerciseId.isNotEmpty);
  }

  /// Validate workout data
  List<String> validate() {
    final errors = <String>[];

    // Name validation
    if (name.trim().isEmpty) {
      errors.add('Workout name cannot be empty');
    } else if (name.trim().length < 2) {
      errors.add('Workout name must be at least 2 characters long');
    } else if (name.trim().length > 100) {
      errors.add('Workout name must be less than 100 characters');
    }

    // Description validation
    if (description != null && description!.length > 500) {
      errors.add('Workout description must be less than 500 characters');
    }

    // Duration validation
    if (estimatedDuration < 5) {
      errors.add('Estimated duration must be at least 5 minutes');
    } else if (estimatedDuration > 300) {
      errors.add('Estimated duration must be less than 300 minutes');
    }

    // Exercises validation
    if (exercises.isEmpty) {
      errors.add('Workout must contain at least one exercise');
    } else if (exercises.length > 20) {
      errors.add('Workout cannot contain more than 20 exercises');
    }

    // Validate individual exercises
    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];

      if (exercise.exerciseId.isEmpty) {
        errors.add('Exercise ${i + 1}: Exercise ID cannot be empty');
      }

      if (exercise.exerciseName.trim().isEmpty) {
        errors.add('Exercise ${i + 1}: Exercise name cannot be empty');
      }

      if (exercise.sets.isEmpty) {
        errors.add('Exercise ${i + 1}: Must have at least one set');
      } else if (exercise.sets.length > 20) {
        errors.add('Exercise ${i + 1}: Cannot have more than 20 sets');
      }

      // Validate individual sets
      for (int j = 0; j < exercise.sets.length; j++) {
        final set = exercise.sets[j];
        
        if (set.reps < 1 || set.reps > 100) {
          errors.add('Exercise ${i + 1}, Set ${j + 1}: Reps must be between 1 and 100');
        }

        if (set.weight < 0 || set.weight > 1000) {
          errors.add('Exercise ${i + 1}, Set ${j + 1}: Weight must be between 0 and 1000');
        }

        if (set.restTime != null &&
            (set.restTime!.inSeconds < 0 || set.restTime!.inSeconds > 600)) {
          errors.add(
            'Exercise ${i + 1}, Set ${j + 1}: Rest time must be between 0 and 600 seconds',
          );
        }
      }
    }

    // User ID validation
    if (userId.trim().isEmpty) {
      errors.add('User ID cannot be empty');
    }

    return errors;
  }

  /// Create a workout for creation (no ID required)
  factory Workout.forCreation({
    required String name,
    String? description,
    required int estimatedDuration,
    required List<WorkoutExercise> exercises,
    required String userId,
  }) {
    final now = DateTime.now();
    return Workout(
      id: '', // Will be set by PocketBase
      created: now,
      updated: now,
      name: name,
      description: description,
      estimatedDuration: estimatedDuration,
      exercises: exercises,
      userId: userId,
    );
  }

  /// Create empty workout for initial state
  factory Workout.empty() {
    final now = DateTime.now();
    return Workout(
      id: '',
      created: now,
      updated: now,
      name: '',
      estimatedDuration: 0,
      exercises: [],
      userId: '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workout &&
        other.id == id &&
        other.name == name &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(id, name, userId);

  @override
  String toString() {
    return 'Workout(id: $id, name: $name, exercises: ${exercises.length}, duration: ${estimatedDuration}min)';
  }
}
