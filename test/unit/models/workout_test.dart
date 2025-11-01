import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase_periolifts/models/workout.dart';

void main() {
  group('WorkoutSet Tests', () {
    group('fromJson', () {
      test('should create WorkoutSet from valid JSON', () {
        // Arrange
        final json = {
          'reps': 12,
          'weight': 50.5,
          'rest_time': 60,
          'notes': 'Focus on form',
        };

        // Act
        final workoutSet = WorkoutSet.fromJson(json);

        // Assert
        expect(workoutSet.reps, equals(12));
        expect(workoutSet.weight, equals(50.5));
        expect(workoutSet.restTime, equals(const Duration(seconds: 60)));
        expect(workoutSet.notes, equals('Focus on form'));
      });

      test('should handle missing optional fields', () {
        // Arrange
        final json = {'reps': 10, 'weight': 25.0};

        // Act
        final workoutSet = WorkoutSet.fromJson(json);

        // Assert
        expect(workoutSet.reps, equals(10));
        expect(workoutSet.weight, equals(25.0));
        expect(workoutSet.restTime, isNull);
        expect(workoutSet.notes, isNull);
      });

      test('should handle null and invalid values gracefully', () {
        // Arrange
        final json = {
          'reps': null,
          'weight': null,
          'rest_time': null,
          'notes': null,
        };

        // Act
        final workoutSet = WorkoutSet.fromJson(json);

        // Assert
        expect(workoutSet.reps, equals(0));
        expect(workoutSet.weight, equals(0.0));
        expect(workoutSet.restTime, isNull);
        expect(workoutSet.notes, isNull);
      });
    });

    group('toJson', () {
      test('should convert WorkoutSet to valid JSON', () {
        // Arrange
        final workoutSet = WorkoutSet(
          reps: 15,
          weight: 75.0,
          restTime: const Duration(seconds: 90),
          notes: 'Increase weight next time',
        );

        // Act
        final json = workoutSet.toJson();

        // Assert
        expect(json['reps'], equals(15));
        expect(json['weight'], equals(75.0));
        expect(json['rest_time'], equals(90));
        expect(json['notes'], equals('Increase weight next time'));
      });

      test('should handle null optional fields', () {
        // Arrange
        const workoutSet = WorkoutSet(reps: 8, weight: 30.0);

        // Act
        final json = workoutSet.toJson();

        // Assert
        expect(json['reps'], equals(8));
        expect(json['weight'], equals(30.0));
        expect(json['rest_time'], isNull);
        expect(json['notes'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        const original = WorkoutSet(
          reps: 10,
          weight: 50.0,
          restTime: Duration(seconds: 60),
          notes: 'Original notes',
        );

        // Act
        final copy = original.copyWith(reps: 12, weight: 55.0);

        // Assert
        expect(copy.reps, equals(12));
        expect(copy.weight, equals(55.0));
        expect(copy.restTime, equals(const Duration(seconds: 60)));
        expect(copy.notes, equals('Original notes'));
      });

      test('should create identical copy when no parameters provided', () {
        // Arrange
        const original = WorkoutSet(
          reps: 8,
          weight: 40.0,
          restTime: Duration(seconds: 45),
          notes: 'Test notes',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.reps, equals(original.reps));
        expect(copy.weight, equals(original.weight));
        expect(copy.restTime, equals(original.restTime));
        expect(copy.notes, equals(original.notes));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        // Arrange
        const set1 = WorkoutSet(
          reps: 10,
          weight: 50.0,
          restTime: Duration(seconds: 60),
          notes: 'Test',
        );

        const set2 = WorkoutSet(
          reps: 10,
          weight: 50.0,
          restTime: Duration(seconds: 60),
          notes: 'Test',
        );

        // Act & Assert
        expect(set1, equals(set2));
        expect(set1.hashCode, equals(set2.hashCode));
      });

      test('should not be equal when fields differ', () {
        // Arrange
        const set1 = WorkoutSet(reps: 10, weight: 50.0);
        const set2 = WorkoutSet(reps: 12, weight: 50.0);

        // Act & Assert
        expect(set1, isNot(equals(set2)));
      });
    });
  });

  group('WorkoutExercise Tests', () {
    group('fromJson', () {
      test('should create WorkoutExercise from valid JSON with legacy format', () {
        // Arrange - legacy format with int sets
        final json = {
          'exercise_id': 'exercise_123',
          'exercise_name': 'Push-up',
          'sets': 3,
          'reps': 15,
          'weight': 0.0,
          'rest_time': 60,
          'notes': 'Keep core tight',
        };

        // Act
        final exercise = WorkoutExercise.fromJson(json);

        // Assert
        expect(exercise.exerciseId, equals('exercise_123'));
        expect(exercise.exerciseName, equals('Push-up'));
        expect(exercise.sets.length, equals(3));
        expect(exercise.sets[0].reps, equals(15));
        expect(exercise.sets[0].weight, equals(0.0));
        expect(exercise.sets[0].restTime, equals(const Duration(seconds: 60)));
        expect(exercise.notes, equals('Keep core tight'));
      });

      test('should create WorkoutExercise from new format with List<WorkoutSet>', () {
        // Arrange - new format with List<WorkoutSet>
        final json = {
          'exercise_id': 'exercise_123',
          'exercise_name': 'Push-up',
          'sets': [
            {'reps': 15, 'weight': 0.0, 'rest_time': 60},
            {'reps': 12, 'weight': 0.0, 'rest_time': 60},
            {'reps': 10, 'weight': 0.0, 'rest_time': 60},
          ],
          'notes': 'Keep core tight',
        };

        // Act
        final exercise = WorkoutExercise.fromJson(json);

        // Assert
        expect(exercise.exerciseId, equals('exercise_123'));
        expect(exercise.exerciseName, equals('Push-up'));
        expect(exercise.sets.length, equals(3));
        expect(exercise.sets[0].reps, equals(15));
        expect(exercise.sets[1].reps, equals(12));
        expect(exercise.sets[2].reps, equals(10));
        expect(exercise.notes, equals('Keep core tight'));
      });

      test('should handle missing optional fields', () {
        // Arrange
        final json = {
          'exercise_id': 'exercise_456',
          'exercise_name': 'Squat',
          'sets': 4,
          'reps': 10,
        };

        // Act
        final exercise = WorkoutExercise.fromJson(json);

        // Assert
        expect(exercise.exerciseId, equals('exercise_456'));
        expect(exercise.exerciseName, equals('Squat'));
        expect(exercise.sets.length, equals(4));
        expect(exercise.sets[0].reps, equals(10));
        expect(exercise.notes, isNull);
      });

      test('should use default values for invalid data', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final exercise = WorkoutExercise.fromJson(json);

        // Assert
        expect(exercise.exerciseId, equals(''));
        expect(exercise.exerciseName, equals(''));
        expect(exercise.sets, isEmpty);
        expect(exercise.notes, isNull);
      });
    });

    group('toJson', () {
      test('should convert WorkoutExercise to valid JSON', () {
        // Arrange
        final exercise = WorkoutExercise(
          exerciseId: 'exercise_789',
          exerciseName: 'Bench Press',
          sets: [
            const WorkoutSet(reps: 8, weight: 80.0, restTime: Duration(seconds: 120)),
            const WorkoutSet(reps: 8, weight: 80.0, restTime: Duration(seconds: 120)),
            const WorkoutSet(reps: 8, weight: 80.0, restTime: Duration(seconds: 120)),
          ],
          notes: 'Progressive overload',
        );

        // Act
        final json = exercise.toJson();

        // Assert
        expect(json['exercise_id'], equals('exercise_789'));
        expect(json['exercise_name'], equals('Bench Press'));
        expect(json['sets'], isList);
        expect(json['sets'].length, equals(3));
        expect(json['sets'][0]['reps'], equals(8));
        expect(json['sets'][0]['weight'], equals(80.0));
        expect(json['sets'][0]['rest_time'], equals(120));
        expect(json['notes'], equals('Progressive overload'));
      });

      test('should handle null optional fields', () {
        // Arrange
        const exercise = WorkoutExercise(
          exerciseId: 'exercise_999',
          exerciseName: 'Deadlift',
          sets: [
            WorkoutSet(reps: 5, weight: 100.0),
          ],
        );

        // Act
        final json = exercise.toJson();

        // Assert
        expect(json['exercise_id'], equals('exercise_999'));
        expect(json['exercise_name'], equals('Deadlift'));
        expect(json['sets'], isList);
        expect(json['sets'].length, equals(1));
        expect(json['notes'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        final original = WorkoutExercise(
          exerciseId: 'exercise_original',
          exerciseName: 'Original Exercise',
          sets: [
            const WorkoutSet(reps: 10, weight: 50.0, restTime: Duration(seconds: 60)),
            const WorkoutSet(reps: 10, weight: 50.0, restTime: Duration(seconds: 60)),
            const WorkoutSet(reps: 10, weight: 50.0, restTime: Duration(seconds: 60)),
          ],
          notes: 'Original notes',
        );

        // Act
        final copy = original.copyWith(
          exerciseName: 'Updated Exercise',
          sets: [
            const WorkoutSet(reps: 12, weight: 60.0),
            const WorkoutSet(reps: 12, weight: 60.0),
            const WorkoutSet(reps: 12, weight: 60.0),
            const WorkoutSet(reps: 12, weight: 60.0),
          ],
        );

        // Assert
        expect(copy.exerciseId, equals('exercise_original'));
        expect(copy.exerciseName, equals('Updated Exercise'));
        expect(copy.sets.length, equals(4));
        expect(copy.sets[0].reps, equals(12));
        expect(copy.sets[0].weight, equals(60.0));
        expect(copy.notes, equals('Original notes'));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        // Arrange
        const exercise1 = WorkoutExercise(
          exerciseId: 'exercise_123',
          exerciseName: 'Test Exercise',
          sets: [],
          notes: 'Test notes',
        );

        const exercise2 = WorkoutExercise(
          exerciseId: 'exercise_123',
          exerciseName: 'Test Exercise',
          sets: [],
          notes: 'Test notes',
        );

        // Act & Assert
        expect(exercise1, equals(exercise2));
        expect(exercise1.hashCode, equals(exercise2.hashCode));
      });

      test('should not be equal when fields differ', () {
        // Arrange
        const exercise1 = WorkoutExercise(
          exerciseId: 'exercise_123',
          exerciseName: 'Exercise 1',
          sets: [],
        );

        const exercise2 = WorkoutExercise(
          exerciseId: 'exercise_456',
          exerciseName: 'Exercise 2',
          sets: [],
        );

        // Act & Assert
        expect(exercise1, isNot(equals(exercise2)));
      });
    });
  });

  group('Workout Tests', () {
    group('fromJson', () {
      test('should create Workout from valid PocketBase JSON', () {
        // Arrange
        final json = {
          'id': 'workout_123',
          'created': '2024-01-15T10:30:00.000Z',
          'updated': '2024-01-15T11:45:00.000Z',
          'name': 'Upper Body Workout',
          'description': 'Comprehensive upper body training',
          'estimated_duration': 45,
          'exercises': [
            {
              'exercise_id': 'exercise_1',
              'exercise_name': 'Push-up',
              'sets': 3,
              'reps': 15,
              'weight': 0.0,
              'rest_time': 60,
            },
            {
              'exercise_id': 'exercise_2',
              'exercise_name': 'Pull-up',
              'sets': 3,
              'reps': 8,
              'rest_time': 90,
            },
          ],
          'user_id': 'user_456',
        };

        // Act
        final workout = Workout.fromJson(json);

        // Assert
        expect(workout.id, equals('workout_123'));
        expect(
          workout.created,
          equals(DateTime.parse('2024-01-15T10:30:00.000Z')),
        );
        expect(
          workout.updated,
          equals(DateTime.parse('2024-01-15T11:45:00.000Z')),
        );
        expect(workout.name, equals('Upper Body Workout'));
        expect(
          workout.description,
          equals('Comprehensive upper body training'),
        );
        expect(workout.estimatedDuration, equals(45));
        expect(workout.exercises.length, equals(2));
        expect(workout.userId, equals('user_456'));

        expect(workout.exercises[0].exerciseId, equals('exercise_1'));
        expect(workout.exercises[0].exerciseName, equals('Push-up'));
        expect(workout.exercises[0].sets, equals(3));
        expect(workout.exercises[0].reps, equals(15));

        expect(workout.exercises[1].exerciseId, equals('exercise_2'));
        expect(workout.exercises[1].exerciseName, equals('Pull-up'));
        expect(workout.exercises[1].sets, equals(3));
        expect(workout.exercises[1].reps, equals(8));
      });

      test('should handle empty and null values gracefully', () {
        // Arrange
        final json = {
          'id': 'minimal_workout',
          'created': '2024-01-15T10:30:00.000Z',
          'updated': '2024-01-15T10:30:00.000Z',
          'name': null,
          'description': null,
          'estimated_duration': null,
          'exercises': null,
          'user_id': null,
        };

        // Act
        final workout = Workout.fromJson(json);

        // Assert
        expect(workout.name, equals(''));
        expect(workout.description, isNull);
        expect(workout.estimatedDuration, equals(0));
        expect(workout.exercises, isEmpty);
        expect(workout.userId, equals(''));
      });

      test('should parse exercises from JSON string format', () {
        // Arrange
        final json = {
          'id': 'string_exercises_workout',
          'created': '2024-01-15T10:30:00.000Z',
          'updated': '2024-01-15T10:30:00.000Z',
          'name': 'String Format Workout',
          'estimated_duration': 30,
          'exercises': [
            '{"exercise_id":"ex1","exercise_name":"Test Exercise","sets":2,"reps":10}',
          ],
          'user_id': 'user_123',
        };

        // Act
        final workout = Workout.fromJson(json);

        // Assert
        expect(workout.exercises.length, equals(1));
        expect(workout.exercises[0].exerciseId, equals('ex1'));
        expect(workout.exercises[0].exerciseName, equals('Test Exercise'));
        expect(workout.exercises[0].sets, equals(2));
        expect(workout.exercises[0].reps, equals(10));
      });

      test('should handle invalid exercise JSON gracefully', () {
        // Arrange
        final json = {
          'id': 'invalid_exercises_workout',
          'created': '2024-01-15T10:30:00.000Z',
          'updated': '2024-01-15T10:30:00.000Z',
          'name': 'Invalid Exercises Workout',
          'estimated_duration': 20,
          'exercises': [
            'invalid json string',
            123, // Invalid type
          ],
          'user_id': 'user_123',
        };

        // Act
        final workout = Workout.fromJson(json);

        // Assert
        expect(workout.exercises.length, equals(2));
        expect(workout.exercises[0].exerciseName, equals('Invalid Exercise'));
        expect(workout.exercises[1].exerciseName, equals('Unknown Exercise'));
      });
    });

    group('toJson', () {
      test('should convert Workout to valid PocketBase JSON', () {
        // Arrange
        final workout = Workout(
          id: 'workout_456',
          created: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updated: DateTime.parse('2024-01-15T11:45:00.000Z'),
          name: 'Lower Body Workout',
          description: 'Leg day training',
          estimatedDuration: 60,
          exercises: const [
            WorkoutExercise.uniform(
              exerciseId: 'squat_id',
              exerciseName: 'Squat',
              sets: 4,
              reps: 12,
              weight: 100.0,
              restTime: 120,
            ),
            WorkoutExercise.uniform(
              exerciseId: 'deadlift_id',
              exerciseName: 'Deadlift',
              sets: 3,
              reps: 8,
              weight: 120.0,
              restTime: 180,
            ),
          ],
          userId: 'user_789',
        );

        // Act
        final json = workout.toJson();

        // Assert
        expect(json['name'], equals('Lower Body Workout'));
        expect(json['description'], equals('Leg day training'));
        expect(json['estimated_duration'], equals(60));
        expect(json['user_id'], equals('user_789'));
        expect(json['exercises'], isList);
        expect(json['exercises'].length, equals(2));

        final exerciseJson = json['exercises'][0] as Map<String, dynamic>;
        expect(exerciseJson['exercise_id'], equals('squat_id'));
        expect(exerciseJson['exercise_name'], equals('Squat'));
        expect(exerciseJson['sets'], equals(4));
        expect(exerciseJson['reps'], equals(12));
      });

      test('should handle empty user ID correctly', () {
        // Arrange
        final workout = Workout(
          id: 'test_workout',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Test Workout',
          estimatedDuration: 30,
          exercises: const [],
          userId: '',
        );

        // Act
        final json = workout.toJson();

        // Assert
        expect(json['user_id'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        final original = Workout(
          id: 'original_id',
          created: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updated: DateTime.parse('2024-01-15T10:30:00.000Z'),
          name: 'Original Workout',
          description: 'Original description',
          estimatedDuration: 30,
          exercises: const [
            WorkoutExercise.uniform(
              exerciseId: 'ex1',
              exerciseName: 'Exercise 1',
              sets: 3,
              reps: 10,
            ),
          ],
          userId: 'user_123',
        );

        // Act
        final copy = original.copyWith(
          name: 'Updated Workout',
          estimatedDuration: 45,
          exercises: const [
            WorkoutExercise.uniform(
              exerciseId: 'ex2',
              exerciseName: 'Exercise 2',
              sets: 4,
              reps: 8,
            ),
          ],
        );

        // Assert
        expect(copy.id, equals('original_id')); // Unchanged
        expect(copy.name, equals('Updated Workout')); // Changed
        expect(copy.description, equals('Original description')); // Unchanged
        expect(copy.estimatedDuration, equals(45)); // Changed
        expect(copy.exercises.length, equals(1)); // Changed
        expect(copy.exercises[0].exerciseId, equals('ex2')); // Changed
        expect(copy.userId, equals('user_123')); // Unchanged
      });
    });

    group('Computed Properties', () {
      test('should calculate total sets correctly', () {
        // Arrange
        final workout = Workout(
          id: 'test_workout',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Test Workout',
          estimatedDuration: 30,
          exercises: const [
            WorkoutExercise.uniform(
              exerciseId: 'ex1',
              exerciseName: 'Exercise 1',
              sets: 3,
              reps: 10,
            ),
            WorkoutExercise.uniform(
              exerciseId: 'ex2',
              exerciseName: 'Exercise 2',
              sets: 4,
              reps: 8,
            ),
          ],
          userId: 'user_123',
        );

        // Act & Assert
        expect(workout.totalSets, equals(7)); // 3 + 4
      });

      test('should calculate total reps correctly', () {
        // Arrange
        final workout = Workout(
          id: 'test_workout',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Test Workout',
          estimatedDuration: 30,
          exercises: const [
            WorkoutExercise.uniform(
              exerciseId: 'ex1',
              exerciseName: 'Exercise 1',
              sets: 3,
              reps: 10,
            ),
            WorkoutExercise.uniform(
              exerciseId: 'ex2',
              exerciseName: 'Exercise 2',
              sets: 2,
              reps: 15,
            ),
          ],
          userId: 'user_123',
        );

        // Act & Assert
        expect(workout.totalReps, equals(60)); // (3 * 10) + (2 * 15)
      });

      test('should get unique exercise IDs', () {
        // Arrange
        final workout = Workout(
          id: 'test_workout',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Test Workout',
          estimatedDuration: 30,
          exercises: const [
            WorkoutExercise.uniform(
              exerciseId: 'ex1',
              exerciseName: 'Exercise 1',
              sets: 3,
              reps: 10,
            ),
            WorkoutExercise.uniform(
              exerciseId: 'ex2',
              exerciseName: 'Exercise 2',
              sets: 2,
              reps: 15,
            ),
            WorkoutExercise(
              exerciseId: 'ex1', // Duplicate
              exerciseName: 'Exercise 1 Again',
              sets: 1,
              reps: 5,
            ),
          ],
          userId: 'user_123',
        );

        // Act & Assert
        expect(workout.exerciseIds, equals(['ex1', 'ex2']));
      });

      test('should check if workout has exercises', () {
        // Arrange
        final workoutWithExercises = Workout(
          id: 'workout_with_exercises',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Workout With Exercises',
          estimatedDuration: 30,
          exercises: const [
            WorkoutExercise.uniform(
              exerciseId: 'ex1',
              exerciseName: 'Exercise 1',
              sets: 3,
              reps: 10,
            ),
          ],
          userId: 'user_123',
        );

        final workoutWithoutExercises = Workout(
          id: 'workout_without_exercises',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Empty Workout',
          estimatedDuration: 0,
          exercises: const [],
          userId: 'user_123',
        );

        // Act & Assert
        expect(workoutWithExercises.hasExercises, isTrue);
        expect(workoutWithoutExercises.hasExercises, isFalse);
      });

      test('should validate workout correctly', () {
        // Arrange
        final validWorkout = Workout(
          id: 'valid_workout',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Valid Workout',
          estimatedDuration: 30,
          exercises: const [
            WorkoutExercise.uniform(
              exerciseId: 'valid_exercise_id',
              exerciseName: 'Valid Exercise',
              sets: 3,
              reps: 10,
            ),
          ],
          userId: 'user_123',
        );

        final invalidWorkout = Workout(
          id: 'invalid_workout',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Invalid Workout',
          estimatedDuration: 30,
          exercises: const [
            WorkoutExercise(
              exerciseId: '', // Invalid empty ID
              exerciseName: 'Invalid Exercise',
              sets: 3,
              reps: 10,
            ),
          ],
          userId: 'user_123',
        );

        final emptyWorkout = Workout(
          id: 'empty_workout',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Empty Workout',
          estimatedDuration: 0,
          exercises: const [],
          userId: 'user_123',
        );

        // Act & Assert
        expect(validWorkout.isValid, isTrue);
        expect(invalidWorkout.isValid, isFalse);
        expect(emptyWorkout.isValid, isFalse);
      });
    });

    group('UserOwnedModel Mixin', () {
      test('should correctly implement belongsToUser', () {
        // Arrange
        final workout = Workout(
          id: 'user_workout',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'User Workout',
          estimatedDuration: 30,
          exercises: const [],
          userId: 'user_123',
        );

        // Act & Assert
        expect(workout.belongsToUser('user_123'), isTrue);
        expect(workout.belongsToUser('other_user'), isFalse);
        expect(workout.belongsToUser(null), isFalse);
      });
    });

    group('toString', () {
      test('should provide meaningful string representation', () {
        // Arrange
        final workout = Workout(
          id: 'test_workout',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Test Workout',
          estimatedDuration: 45,
          exercises: const [
            WorkoutExercise.uniform(
              exerciseId: 'ex1',
              exerciseName: 'Exercise 1',
              sets: 3,
              reps: 10,
            ),
            WorkoutExercise.uniform(
              exerciseId: 'ex2',
              exerciseName: 'Exercise 2',
              sets: 2,
              reps: 15,
            ),
          ],
          userId: 'user_123',
        );

        // Act
        final string = workout.toString();

        // Assert
        expect(string, contains('Workout'));
        expect(string, contains('test_workout'));
        expect(string, contains('Test Workout'));
        expect(string, contains('2')); // Number of exercises
        expect(string, contains('45')); // Duration
      });
    });

    group('Edge Cases', () {
      test('should handle malformed JSON gracefully', () {
        // Arrange
        final malformedJson = <String, dynamic>{
          'id': 'test_id',
          'created': 'invalid_date',
          'updated': 'invalid_date',
          // Missing required fields
        };

        // Act & Assert - Should not throw, should use defaults
        expect(() => Workout.fromJson(malformedJson), returnsNormally);

        final workout = Workout.fromJson(malformedJson);
        expect(workout.id, equals('test_id'));
        expect(workout.name, equals(''));
        expect(workout.estimatedDuration, equals(0));
        expect(workout.exercises, isEmpty);
      });

      test('should handle large number of exercises', () {
        // Arrange
        final manyExercises = List.generate(
          100,
          (index) => WorkoutExercise.uniform(
              exerciseId: 'exercise_$index',
              exerciseName: 'Exercise $index',
              sets: 3,
              reps: 10,
          ),
        );

        final workout = Workout(
          id: 'large_workout',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Large Workout',
          estimatedDuration: 120,
          exercises: manyExercises,
          userId: 'user_123',
        );

        // Act
        final json = workout.toJson();
        final recreated = Workout.fromJson({
          'id': 'large_workout',
          'created': DateTime.now().toIso8601String(),
          'updated': DateTime.now().toIso8601String(),
          ...json,
        });

        // Assert
        expect(recreated.exercises.length, equals(100));
        expect(recreated.totalSets, equals(300)); // 100 exercises * 3 sets
        expect(recreated.exerciseIds.length, equals(100)); // All unique
      });
    });
  });
}
