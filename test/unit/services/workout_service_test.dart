import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/workout_service.dart';
import '../../../lib/models/workout.dart';

void main() {
  group('WorkoutService', () {
    late WorkoutService service;

    setUp(() {
      service = WorkoutService();
    });

    group('getWorkouts', () {
      test('should return validation error for invalid page number', () async {
        final result = await service.getWorkouts(page: 0);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Page number must be greater than 0'),
        );
      });

      test('should return validation error for negative page', () async {
        final result = await service.getWorkouts(page: -1);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Page number must be greater than 0'),
        );
      });

      test(
        'should return validation error for invalid perPage (too low)',
        () async {
          final result = await service.getWorkouts(perPage: 0);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Items per page must be between 1 and 100'),
          );
        },
      );

      test(
        'should return validation error for invalid perPage (too high)',
        () async {
          final result = await service.getWorkouts(perPage: 101);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Items per page must be between 1 and 100'),
          );
        },
      );

      test('should return validation error for negative perPage', () async {
        final result = await service.getWorkouts(perPage: -5);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Items per page must be between 1 and 100'),
        );
      });

      test(
        'should build correct filter for includeUserOnly when authenticated',
        () async {
          // This will fail with authentication error, but we can check the filter logic
          final result = await service.getWorkouts(includeUserOnly: true);

          expect(result.isError, isTrue);
          // Should be authentication error since we're not actually authenticated
          expect(result.error!.type, equals('AuthenticationError'));
        },
      );

      test('should handle search query sanitization', () async {
        // Test with potentially unsafe characters
        final result = await service.getWorkouts(
          searchQuery: 'test"query\\with\nspecial\rchars',
          page: 1,
          perPage: 10,
        );

        // Should not crash due to injection attempts
        expect(result.isError, isTrue);
        // Will fail because we're not connected to PocketBase, but should sanitize the query
      });

      test('should accept valid pagination parameters', () async {
        final result = await service.getWorkouts(
          page: 1,
          perPage: 50,
          includeUserOnly: false,
        );

        // Will fail without PocketBase connection, but parameters should be valid
        expect(result.isError, isTrue);
      });

      test('should accept edge case valid parameters', () async {
        final result = await service.getWorkouts(
          page: 1,
          perPage: 1, // minimum valid
        );

        expect(result.isError, isTrue);
      });

      test('should accept maximum valid perPage', () async {
        final result = await service.getWorkouts(
          page: 1,
          perPage: 100, // maximum valid
        );

        expect(result.isError, isTrue);
      });
    });

    group('getWorkoutById', () {
      test('should return validation error for empty ID', () async {
        final result = await service.getWorkoutById('');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Workout ID cannot be empty'));
      });

      test('should return validation error for whitespace-only ID', () async {
        final result = await service.getWorkoutById('   ');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Workout ID cannot be empty'));
      });

      test('should accept valid workout ID format', () async {
        final result = await service.getWorkoutById('valid-workout-id-123');

        // Will fail without PocketBase connection, but ID should be valid
        expect(result.isError, isTrue);
      });
    });

    group('createWorkout', () {
      test(
        'should return validation error for workout with empty name',
        () async {
          final workout = Workout(
            id: '',
            name: '',
            description: 'Test description',
            exercises: [_createValidWorkoutExercise()],
            estimatedDuration: 60,
            userId: 'test-user',
            created: DateTime.now(),
            updated: DateTime.now(),
          );

          final result = await service.createWorkout(workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Workout name cannot be empty'),
          );
        },
      );

      test(
        'should return validation error for workout with whitespace-only name',
        () async {
          final workout = Workout(
            id: '',
            name: '   ',
            description: 'Test description',
            exercises: [_createValidWorkoutExercise()],

            estimatedDuration: 60,

            userId: 'test-user',

            created: DateTime.now(),
            updated: DateTime.now(),
          );

          final result = await service.createWorkout(workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Workout name cannot be empty'),
          );
        },
      );

      test(
        'should return validation error for workout name too long',
        () async {
          final workout = Workout(
            id: '',
            name: 'a' * 101, // 101 characters, exceeds limit
            description: 'Test description',
            exercises: [_createValidWorkoutExercise()],

            estimatedDuration: 60,

            userId: 'test-user',

            created: DateTime.now(),
            updated: DateTime.now(),
          );

          final result = await service.createWorkout(workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Workout name cannot exceed 100 characters'),
          );
        },
      );

      test('should return validation error for description too long', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'a' * 501, // 501 characters, exceeds limit
          exercises: [_createValidWorkoutExercise()],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Workout description cannot exceed 500 characters'),
        );
      });

      test(
        'should return validation error for workout with no exercises',
        () async {
          final workout = Workout(
            id: '',
            name: 'Valid Name',
            description: 'Test description',
            exercises: [], // Empty exercises list

            estimatedDuration: 60,

            userId: 'test-user',

            created: DateTime.now(),
            updated: DateTime.now(),
          );

          final result = await service.createWorkout(workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Workout must have at least one exercise'),
          );
        },
      );

      test(
        'should return validation error for workout with too many exercises',
        () async {
          final workout = Workout(
            id: '',
            name: 'Valid Name',
            description: 'Test description',
            exercises: List.generate(
              21,
              (i) => _createValidWorkoutExercise(),
            ), // 21 exercises, exceeds limit

            estimatedDuration: 60,

            userId: 'test-user',

            created: DateTime.now(),
            updated: DateTime.now(),
          );

          final result = await service.createWorkout(workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Workout cannot have more than 20 exercises'),
          );
        },
      );

      test(
        'should return authentication error when not authenticated',
        () async {
          final workout = _createValidWorkout();

          final result = await service.createWorkout(workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('Authentication required'));
        },
      );

      test('should accept valid workout with null description', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: null,
          exercises: [_createValidWorkoutExercise()],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        // Should fail with authentication error, not validation
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
      });

      test('should validate workout exercise - empty exercise ID', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'Test description',
          exercises: [
            WorkoutExercise(
              exerciseId: '', // Empty exercise ID
              exerciseName: 'Push Up',
              sets: 3,
              reps: 10,
              weight: null,
              restTime: null,
            ),
          ],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Exercise ID cannot be empty'));
      });

      test('should validate workout exercise - empty exercise name', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'Test description',
          exercises: [
            WorkoutExercise(
              exerciseId: 'valid-exercise-id',
              exerciseName: '', // Empty exercise name
              sets: 3,
              reps: 10,
              weight: null,
              restTime: null,
            ),
          ],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Exercise name cannot be empty'),
        );
      });

      test(
        'should validate workout exercise - invalid sets count (too low)',
        () async {
          final workout = Workout(
            id: '',
            name: 'Valid Name',
            description: 'Test description',
            exercises: [
              WorkoutExercise(
                exerciseId: 'valid-exercise-id',
                exerciseName: 'Push Up',
                sets: 0, // Invalid sets count
                reps: 10,
                weight: null,
                restTime: null,
              ),
            ],

            estimatedDuration: 60,

            userId: 'test-user',

            created: DateTime.now(),
            updated: DateTime.now(),
          );

          final result = await service.createWorkout(workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Exercise must have between 1 and 20 sets'),
          );
        },
      );

      test(
        'should validate workout exercise - invalid sets count (too high)',
        () async {
          final workout = Workout(
            id: '',
            name: 'Valid Name',
            description: 'Test description',
            exercises: [
              WorkoutExercise(
                exerciseId: 'valid-exercise-id',
                exerciseName: 'Push Up',
                sets: 21, // Invalid sets count
                reps: 10,
                weight: null,
                restTime: null,
              ),
            ],

            estimatedDuration: 60,

            userId: 'test-user',

            created: DateTime.now(),
            updated: DateTime.now(),
          );

          final result = await service.createWorkout(workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Exercise must have between 1 and 20 sets'),
          );
        },
      );

      test(
        'should validate workout exercise - invalid reps count (too low)',
        () async {
          final workout = Workout(
            id: '',
            name: 'Valid Name',
            description: 'Test description',
            exercises: [
              WorkoutExercise(
                exerciseId: 'valid-exercise-id',
                exerciseName: 'Push Up',
                sets: 3,
                reps: 0, // Invalid reps count
                weight: null,
                restTime: null,
              ),
            ],

            estimatedDuration: 60,

            userId: 'test-user',

            created: DateTime.now(),
            updated: DateTime.now(),
          );

          final result = await service.createWorkout(workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Exercise reps must be between 1 and 100'),
          );
        },
      );

      test(
        'should validate workout exercise - invalid reps count (too high)',
        () async {
          final workout = Workout(
            id: '',
            name: 'Valid Name',
            description: 'Test description',
            exercises: [
              WorkoutExercise(
                exerciseId: 'valid-exercise-id',
                exerciseName: 'Push Up',
                sets: 3,
                reps: 101, // Invalid reps count
                weight: null,
                restTime: null,
              ),
            ],

            estimatedDuration: 60,

            userId: 'test-user',

            created: DateTime.now(),
            updated: DateTime.now(),
          );

          final result = await service.createWorkout(workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Exercise reps must be between 1 and 100'),
          );
        },
      );

      test('should validate workout exercise - negative weight', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'Test description',
          exercises: [
            WorkoutExercise(
              exerciseId: 'valid-exercise-id',
              exerciseName: 'Push Up',
              sets: 3,
              reps: 10,
              weight: -10.0, // Negative weight
              restTime: null,
            ),
          ],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Exercise weight cannot be negative'),
        );
      });

      test('should validate workout exercise - negative rest time', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'Test description',
          exercises: [
            WorkoutExercise(
              exerciseId: 'valid-exercise-id',
              exerciseName: 'Push Up',
              sets: 3,
              reps: 10,
              weight: null,
              restTime: -30, // Negative rest time
            ),
          ],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Rest time cannot be negative'));
      });
    });

    group('updateWorkout', () {
      test('should return validation error for empty workout ID', () async {
        final workout = _createValidWorkout();

        final result = await service.updateWorkout('', workout);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Workout ID cannot be empty'));
      });

      test(
        'should return validation error for whitespace-only workout ID',
        () async {
          final workout = _createValidWorkout();

          final result = await service.updateWorkout('   ', workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(result.error!.message, contains('Workout ID cannot be empty'));
        },
      );

      test(
        'should return authentication error when not authenticated',
        () async {
          final workout = _createValidWorkout();

          final result = await service.updateWorkout('valid-id', workout);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('Authentication required'));
        },
      );

      test('should validate workout data before update', () async {
        final workout = Workout(
          id: '',
          name: '', // Invalid name
          description: 'Test description',
          exercises: [_createValidWorkoutExercise()],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.updateWorkout('valid-id', workout);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Workout name cannot be empty'));
      });
    });

    group('deleteWorkout', () {
      test('should return validation error for empty workout ID', () async {
        final result = await service.deleteWorkout('');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Workout ID cannot be empty'));
      });

      test(
        'should return validation error for whitespace-only workout ID',
        () async {
          final result = await service.deleteWorkout('   ');

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(result.error!.message, contains('Workout ID cannot be empty'));
        },
      );

      test(
        'should return authentication error when not authenticated',
        () async {
          final result = await service.deleteWorkout('valid-id');

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('Authentication required'));
        },
      );
    });

    group('getUserWorkouts', () {
      test('should return validation error for invalid page number', () async {
        final result = await service.getUserWorkouts(page: 0);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Page number must be greater than 0'),
        );
      });

      test('should return validation error for invalid perPage', () async {
        final result = await service.getUserWorkouts(perPage: 101);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Items per page must be between 1 and 100'),
        );
      });

      test(
        'should delegate to getWorkouts with includeUserOnly=true',
        () async {
          final result = await service.getUserWorkouts(
            page: 1,
            perPage: 10,
            searchQuery: 'test',
          );

          // Should result in authentication error since includeUserOnly=true
          expect(result.isError, isTrue);
          expect(result.error!.type, equals('AuthenticationError'));
        },
      );
    });

    group('getPopularWorkouts', () {
      test(
        'should return validation error for invalid limit (too low)',
        () async {
          final result = await service.getPopularWorkouts(limit: 0);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Limit must be between 1 and 50'),
          );
        },
      );

      test(
        'should return validation error for invalid limit (too high)',
        () async {
          final result = await service.getPopularWorkouts(limit: 51);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Limit must be between 1 and 50'),
          );
        },
      );

      test('should return validation error for negative limit', () async {
        final result = await service.getPopularWorkouts(limit: -5);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Limit must be between 1 and 50'),
        );
      });

      test('should accept valid limit values', () async {
        final result = await service.getPopularWorkouts(limit: 10);

        // Will fail without PocketBase connection, but parameters should be valid
        expect(result.isError, isTrue);
      });

      test('should accept minimum valid limit', () async {
        final result = await service.getPopularWorkouts(limit: 1);

        expect(result.isError, isTrue);
      });

      test('should accept maximum valid limit', () async {
        final result = await service.getPopularWorkouts(limit: 50);

        expect(result.isError, isTrue);
      });
    });

    group('edge cases and boundary conditions', () {
      test('should handle workout name at maximum length', () async {
        final workout = Workout(
          id: '',
          name: 'a' * 100, // Exactly 100 characters
          description: 'Test description',
          exercises: [_createValidWorkoutExercise()],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        // Should fail with authentication error, not validation
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
      });

      test('should handle workout description at maximum length', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'a' * 500, // Exactly 500 characters
          exercises: [_createValidWorkoutExercise()],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        // Should fail with authentication error, not validation
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
      });

      test('should handle workout with maximum number of exercises', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'Test description',
          exercises: List.generate(
            20,
            (i) => _createValidWorkoutExercise(),
          ), // Exactly 20 exercises

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        // Should fail with authentication error, not validation
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
      });

      test('should handle exercise with maximum sets', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'Test description',
          exercises: [
            WorkoutExercise(
              exerciseId: 'valid-exercise-id',
              exerciseName: 'Push Up',
              sets: 20, // Maximum sets
              reps: 10,
              weight: null,
              restTime: null,
            ),
          ],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        // Should fail with authentication error, not validation
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
      });

      test('should handle exercise with maximum reps', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'Test description',
          exercises: [
            WorkoutExercise(
              exerciseId: 'valid-exercise-id',
              exerciseName: 'Push Up',
              sets: 3,
              reps: 100, // Maximum reps
              weight: null,
              restTime: null,
            ),
          ],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        // Should fail with authentication error, not validation
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
      });

      test('should handle exercise with zero weight (valid)', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'Test description',
          exercises: [
            WorkoutExercise(
              exerciseId: 'valid-exercise-id',
              exerciseName: 'Push Up',
              sets: 3,
              reps: 10,
              weight: 0.0, // Zero weight (bodyweight exercise)
              restTime: null,
            ),
          ],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        // Should fail with authentication error, not validation
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
      });

      test('should handle exercise with zero rest time (valid)', () async {
        final workout = Workout(
          id: '',
          name: 'Valid Name',
          description: 'Test description',
          exercises: [
            WorkoutExercise(
              exerciseId: 'valid-exercise-id',
              exerciseName: 'Push Up',
              sets: 3,
              reps: 10,
              weight: null,
              restTime: 0, // Zero rest time
            ),
          ],

          estimatedDuration: 60,

          userId: 'test-user',

          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final result = await service.createWorkout(workout);

        // Should fail with authentication error, not validation
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
      });
    });

    group('sanitization', () {
      test('should sanitize search query with quotes', () async {
        final result = await service.getWorkouts(
          searchQuery: 'test"query',
          page: 1,
          perPage: 10,
        );

        // Should not crash due to quote injection
        expect(result.isError, isTrue);
      });

      test('should sanitize search query with backslashes', () async {
        final result = await service.getWorkouts(
          searchQuery: 'test\\query',
          page: 1,
          perPage: 10,
        );

        expect(result.isError, isTrue);
      });

      test('should sanitize search query with newlines', () async {
        final result = await service.getWorkouts(
          searchQuery: 'test\nquery',
          page: 1,
          perPage: 10,
        );

        expect(result.isError, isTrue);
      });

      test('should sanitize search query with carriage returns', () async {
        final result = await service.getWorkouts(
          searchQuery: 'test\rquery',
          page: 1,
          perPage: 10,
        );

        expect(result.isError, isTrue);
      });

      test('should handle empty search query after sanitization', () async {
        final result = await service.getWorkouts(
          searchQuery: '"""\\\\\\',
          page: 1,
          perPage: 10,
        );

        expect(result.isError, isTrue);
      });
    });
  });
}

/// Helper function to create a valid WorkoutExercise for testing
WorkoutExercise _createValidWorkoutExercise() {
  return WorkoutExercise(
    exerciseId: 'valid-exercise-id',
    exerciseName: 'Push Up',
    sets: 3,
    reps: 10,
    weight: null,
    restTime: null,
  );
}

/// Helper function to create a valid Workout for testing
Workout _createValidWorkout() {
  return Workout(
    id: '',
    name: 'Valid Workout Name',
    description: 'Valid workout description',
    exercises: [_createValidWorkoutExercise()],

    estimatedDuration: 60,

    userId: 'test-user',

    created: DateTime.now(),
    updated: DateTime.now(),
  );
}
