import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/exercise_service.dart';
import '../../../lib/models/exercise.dart';
import '../../../lib/utils/result.dart';

void main() {
  group('ExerciseService', () {
    late ExerciseService service;

    setUp(() {
      service = ExerciseService();
    });

    group('getExercises', () {
      test('should return validation error for invalid page number', () async {
        final result = await service.getExercises(page: 0);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Page number must be greater than 0'),
        );
      });

      test('should return validation error for invalid perPage', () async {
        final result = await service.getExercises(perPage: 0);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Items per page must be between 1 and 100'),
        );
      });

      test('should return validation error for negative page', () async {
        final result = await service.getExercises(page: -1);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Page number must be greater than 0'),
        );
      });

      test('should return validation error for excessive perPage', () async {
        final result = await service.getExercises(perPage: 101);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Items per page must be between 1 and 100'),
        );
      });

      test('should attempt network connection with valid parameters', () async {
        // Valid parameters should pass validation but fail on network (no PocketBase running)
        final result = await service.getExercises(
          category: 'strength',
          muscleGroup: 'chest',
          page: 1,
          perPage: 10,
        );

        expect(result.isError, isTrue);
        // Should fail on network, not validation
        expect(result.error!.type, equals('NetworkError'));
      });
    });

    group('getExerciseById', () {
      test('should return validation error for empty ID', () async {
        final result = await service.getExerciseById('');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(result.error!.message, contains('Exercise ID cannot be empty'));
      });

      test('should attempt network connection with valid ID', () async {
        final result = await service.getExerciseById('valid_id_123');

        expect(result.isError, isTrue);
        // Should fail on network, not validation
        expect(result.error!.type, equals('NetworkError'));
      });
    });

    group('createExercise', () {
      test(
        'should return authentication error for exercise with empty name when user not authenticated',
        () async {
          final exercise = Exercise(
            id: '',
            created: DateTime.now(),
            updated: DateTime.now(),
            name: '', // Invalid: empty name, but auth checked first
            category: 'strength',
            description: 'Test exercise',
            muscleGroups: ['chest'],
            isCustom: true,
            userId: 'user123',
          );

          final result = await service.createExercise(exercise);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('User must be authenticated'));
        },
      );

      test(
        'should return authentication error for exercise with empty category when user not authenticated',
        () async {
          final exercise = Exercise(
            id: '',
            created: DateTime.now(),
            updated: DateTime.now(),
            name: 'Test Exercise',
            category: '', // Invalid: empty category, but auth checked first
            description: 'Test exercise',
            muscleGroups: ['chest'],
            isCustom: true,
            userId: 'user123',
          );

          final result = await service.createExercise(exercise);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('User must be authenticated'));
        },
      );

      test(
        'should return authentication error for exercise with empty muscle groups when user not authenticated',
        () async {
          final exercise = Exercise(
            id: '',
            created: DateTime.now(),
            updated: DateTime.now(),
            name: 'Test Exercise',
            category: 'strength',
            description: 'Test exercise',
            muscleGroups:
                [], // Invalid: empty muscle groups, but auth checked first
            isCustom: true,
            userId: 'user123',
          );

          final result = await service.createExercise(exercise);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('User must be authenticated'));
        },
      );

      test(
        'should return authentication error when user not authenticated',
        () async {
          final exercise = Exercise(
            id: '',
            created: DateTime.now(),
            updated: DateTime.now(),
            name: 'Test Exercise',
            category: 'strength',
            description: 'Test exercise',
            muscleGroups: ['chest'],
            isCustom: true,
            userId: 'user123',
          );

          final result = await service.createExercise(exercise);

          expect(result.isError, isTrue);
          // Should pass validation but fail on authentication (no user logged in)
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('User must be authenticated'));
        },
      );
    });

    group('updateExercise', () {
      test(
        'should return authentication error for exercise with empty ID when user not authenticated',
        () async {
          final exercise = Exercise(
            id: '', // Invalid: empty ID, but auth checked first
            created: DateTime.now(),
            updated: DateTime.now(),
            name: 'Test Exercise',
            category: 'strength',
            description: 'Test exercise',
            muscleGroups: ['chest'],
            isCustom: true,
            userId: 'user123',
          );

          final result = await service.updateExercise(exercise);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('User must be authenticated'));
        },
      );

      test(
        'should return authentication error when user not authenticated',
        () async {
          final exercise = Exercise(
            id: 'valid_id_123',
            created: DateTime.now(),
            updated: DateTime.now(),
            name: 'Test Exercise',
            category: 'strength',
            description: 'Test exercise',
            muscleGroups: ['chest'],
            isCustom: true,
            userId: 'user123',
          );

          final result = await service.updateExercise(exercise);

          expect(result.isError, isTrue);
          // Should pass validation but fail on authentication
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('User must be authenticated'));
        },
      );
    });

    group('deleteExercise', () {
      test(
        'should return authentication error for empty ID when user not authenticated',
        () async {
          final result = await service.deleteExercise('');

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('User must be authenticated'));
        },
      );

      test(
        'should return authentication error when user not authenticated',
        () async {
          final result = await service.deleteExercise('valid_id');

          expect(result.isError, isTrue);
          // Should pass validation but fail on authentication
          expect(result.error!.type, equals('AuthenticationError'));
          expect(result.error!.message, contains('User must be authenticated'));
        },
      );
    });

    group('getExerciseCategories', () {
      test(
        'should return network error when PocketBase not available',
        () async {
          final result = await service.getExerciseCategories();

          expect(result.isError, isTrue);
          // No validation to fail, should fail on network connection
          expect(result.error!.type, equals('NetworkError'));
          expect(result.error!.message, contains('Request failed'));
        },
      );
    });

    group('getMuscleGroups', () {
      test(
        'should return network error when PocketBase not available',
        () async {
          final result = await service.getMuscleGroups();

          expect(result.isError, isTrue);
          // No validation to fail, should fail on network connection
          expect(result.error!.type, equals('NetworkError'));
          expect(result.error!.message, contains('Request failed'));
        },
      );
    });

    group('Performance Requirements', () {
      test('getExercises should complete within 500ms', () async {
        final stopwatch = Stopwatch()..start();

        await service.getExercises(page: 1, perPage: 10);

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('getExerciseById should complete within 500ms', () async {
        final stopwatch = Stopwatch()..start();

        await service.getExerciseById('test_id');

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('createExercise should complete within 500ms', () async {
        final exercise = Exercise(
          id: '',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Test Exercise',
          category: 'strength',
          description: 'Test exercise',
          muscleGroups: ['chest'],
          isCustom: true,
          userId: 'user123',
        );

        final stopwatch = Stopwatch()..start();

        await service.createExercise(exercise);

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });

    group('Edge Cases', () {
      test('should handle special characters in search query', () async {
        final result = await service.getExercises(
          searchQuery: '!@#\$%^&*()_+={}[]|\\:";\'<>?,./',
          page: 1,
          perPage: 10,
        );

        expect(result.isError, isTrue);
        // Should fail on network, not crash on special characters
        expect(result.error!.type, equals('NetworkError'));
      });

      test('should handle very long search query', () async {
        final longQuery = 'a' * 1000;
        final result = await service.getExercises(
          searchQuery: longQuery,
          page: 1,
          perPage: 10,
        );

        expect(result.isError, isTrue);
        // Should fail on network or validation, not crash
        expect(
          result.error!.type,
          anyOf(equals('NetworkError'), equals('ValidationError')),
        );
      });

      test('should handle unicode characters in exercise name', () async {
        final exercise = Exercise(
          id: '',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: '测试练习 🏋️‍♂️ Übung',
          category: 'strength',
          description: 'Test exercise with unicode',
          muscleGroups: ['chest'],
          isCustom: true,
          userId: 'user123',
        );

        final result = await service.createExercise(exercise);

        expect(result.isError, isTrue);
        // Should fail on authentication, not crash on unicode
        expect(result.error!.type, equals('AuthenticationError'));
      });
    });
  });
}
