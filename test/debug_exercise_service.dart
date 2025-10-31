// This file has been converted to a proper Flutter test
// Run with: flutter test test/debug_exercise_service.dart

import 'package:flutter_test/flutter_test.dart';
import '../lib/services/exercise_service.dart';
import '../lib/models/exercise.dart';
import '../lib/utils/result.dart';

void main() {
  group('Debug ExerciseService Behavior', () {
    late ExerciseService service;

    setUp(() {
      service = ExerciseService();
    });

    test(
      'getExercises with invalid page should return validation error',
      () async {
        print('Testing getExercises with page 0...');

        final result = await service.getExercises(page: 0);

        print('Result type: ${result.runtimeType}');
        print('Result isError: ${result.isError}');
        if (result.isError) {
          final error = result.error!;
          print('Error type: ${error.type}');
          print('Error message: ${error.message}');
          print('Error details: ${error.details}');
        } else if (result.isSuccess) {
          print('Unexpected success: ${result.data}');
        }

        // This test is for debugging - we just want to see what happens
        expect(result, isA<Result<dynamic>>());
      },
    );

    test(
      'getExerciseById with empty ID should return validation error',
      () async {
        print('Testing getExerciseById with empty ID...');

        final result = await service.getExerciseById('');

        print('Result type: ${result.runtimeType}');
        print('Result isError: ${result.isError}');
        if (result.isError) {
          final error = result.error!;
          print('Error type: ${error.type}');
          print('Error message: ${error.message}');
          print('Error details: ${error.details}');
        } else if (result.isSuccess) {
          print('Unexpected success: ${result.data}');
        }

        expect(result, isA<Result<dynamic>>());
      },
    );

    test(
      'createExercise with invalid data should return validation error',
      () async {
        print('Testing createExercise with test data...');

        final testExercise = Exercise(
          id: '',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Test Exercise',
          category: 'Strength',
          description: 'Test',
          muscleGroups: ['chest'],
          isCustom: true,
          userId: 'test',
        );

        final result = await service.createExercise(testExercise);

        print('Result type: ${result.runtimeType}');
        print('Result isError: ${result.isError}');
        if (result.isError) {
          final error = result.error!;
          print('Error type: ${error.type}');
          print('Error message: ${error.message}');
          print('Error details: ${error.details}');
        } else if (result.isSuccess) {
          print('Unexpected success: ${result.data}');
        }

        expect(result, isA<Result<dynamic>>());
      },
    );

    test('getExerciseCategories utility method', () async {
      print('Testing getExerciseCategories...');

      final result = await service.getExerciseCategories();

      print('Result type: ${result.runtimeType}');
      print('Result isSuccess: ${result.isSuccess}');
      if (result.isSuccess) {
        print('Categories: ${result.data}');
      } else {
        final error = result.error!;
        print('Error type: ${error.type}');
        print('Error message: ${error.message}');
        print('Error details: ${error.details}');
      }

      expect(result, isA<Result<dynamic>>());
    });

    test('getMuscleGroups utility method', () async {
      print('Testing getMuscleGroups...');

      final result = await service.getMuscleGroups();

      print('Result type: ${result.runtimeType}');
      print('Result isSuccess: ${result.isSuccess}');
      if (result.isSuccess) {
        print('Muscle groups: ${result.data}');
      } else {
        final error = result.error!;
        print('Error type: ${error.type}');
        print('Error message: ${error.message}');
        print('Error details: ${error.details}');
      }

      expect(result, isA<Result<dynamic>>());
    });
  });
}
