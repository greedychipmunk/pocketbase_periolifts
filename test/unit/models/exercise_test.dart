import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase_periolifts/models/exercise.dart';

void main() {
  group('Exercise Model Tests', () {
    group('fromJson', () {
      test('should create Exercise from valid PocketBase JSON', () {
        // Arrange
        final json = {
          'id': 'test_exercise_id',
          'created': '2024-01-15T10:30:00.000Z',
          'updated': '2024-01-15T11:45:00.000Z',
          'name': 'Push-up',
          'category': 'Strength',
          'description':
              'A classic bodyweight exercise targeting chest, shoulders, and triceps.',
          'muscle_groups': ['Chest', 'Shoulders', 'Triceps'],
          'image_url': 'https://example.com/pushup.jpg',
          'video_url': 'https://example.com/pushup.mp4',
          'is_custom': false,
          'user_id': null,
        };

        // Act
        final exercise = Exercise.fromJson(json);

        // Assert
        expect(exercise.id, equals('test_exercise_id'));
        expect(
          exercise.created,
          equals(DateTime.parse('2024-01-15T10:30:00.000Z')),
        );
        expect(
          exercise.updated,
          equals(DateTime.parse('2024-01-15T11:45:00.000Z')),
        );
        expect(exercise.name, equals('Push-up'));
        expect(exercise.category, equals('Strength'));
        expect(
          exercise.description,
          equals(
            'A classic bodyweight exercise targeting chest, shoulders, and triceps.',
          ),
        );
        expect(
          exercise.muscleGroups,
          equals(['Chest', 'Shoulders', 'Triceps']),
        );
        expect(exercise.imageUrl, equals('https://example.com/pushup.jpg'));
        expect(exercise.videoUrl, equals('https://example.com/pushup.mp4'));
        expect(exercise.isCustom, equals(false));
        expect(exercise.userId, equals(''));
        expect(exercise.isBuiltIn, equals(true));
      });

      test('should create custom Exercise from PocketBase JSON', () {
        // Arrange
        final json = {
          'id': 'custom_exercise_id',
          'created': '2024-01-20T14:00:00.000Z',
          'updated': '2024-01-20T14:00:00.000Z',
          'name': 'Custom Squat Variation',
          'category': 'Strength',
          'description': 'My personal squat variation',
          'muscle_groups': ['Quadriceps', 'Glutes'],
          'image_url': null,
          'video_url': null,
          'is_custom': true,
          'user_id': 'user123',
        };

        // Act
        final exercise = Exercise.fromJson(json);

        // Assert
        expect(exercise.isCustom, equals(true));
        expect(exercise.userId, equals('user123'));
        expect(exercise.imageUrl, isNull);
        expect(exercise.videoUrl, isNull);
        expect(exercise.isBuiltIn, equals(false));
      });

      test('should handle empty and null values gracefully', () {
        // Arrange
        final json = {
          'id': 'minimal_exercise',
          'created': '2024-01-15T10:30:00.000Z',
          'updated': '2024-01-15T10:30:00.000Z',
          'name': null,
          'category': '',
          'description': null,
          'muscle_groups': <String>[],
          'image_url': null,
          'video_url': null,
          'is_custom': null,
          'user_id': null,
        };

        // Act
        final exercise = Exercise.fromJson(json);

        // Assert
        expect(exercise.name, equals(''));
        expect(exercise.category, equals(''));
        expect(exercise.description, equals(''));
        expect(exercise.muscleGroups, isEmpty);
        expect(exercise.imageUrl, isNull);
        expect(exercise.videoUrl, isNull);
        expect(exercise.isCustom, equals(false));
        expect(exercise.userId, equals(''));
      });

      test('should parse muscle groups from comma-separated string', () {
        // Arrange
        final json = {
          'id': 'string_muscles_exercise',
          'created': '2024-01-15T10:30:00.000Z',
          'updated': '2024-01-15T10:30:00.000Z',
          'name': 'Bench Press',
          'category': 'Strength',
          'description': 'Chest exercise',
          'muscle_groups': 'Chest, Shoulders, Triceps',
          'is_custom': false,
          'user_id': '',
        };

        // Act
        final exercise = Exercise.fromJson(json);

        // Assert
        expect(
          exercise.muscleGroups,
          equals(['Chest', 'Shoulders', 'Triceps']),
        );
      });

      test('should handle invalid muscle groups format', () {
        // Arrange
        final json = {
          'id': 'invalid_muscles_exercise',
          'created': '2024-01-15T10:30:00.000Z',
          'updated': '2024-01-15T10:30:00.000Z',
          'name': 'Test Exercise',
          'category': 'Test',
          'description': 'Test description',
          'muscle_groups': 123, // Invalid format
          'is_custom': false,
          'user_id': '',
        };

        // Act
        final exercise = Exercise.fromJson(json);

        // Assert
        expect(exercise.muscleGroups, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert Exercise to valid PocketBase JSON', () {
        // Arrange
        final exercise = Exercise(
          id: 'test_id',
          created: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updated: DateTime.parse('2024-01-15T11:45:00.000Z'),
          name: 'Deadlift',
          category: 'Strength',
          description: 'Full-body compound exercise',
          muscleGroups: ['Hamstrings', 'Glutes', 'Lower Back'],
          imageUrl: 'https://example.com/deadlift.jpg',
          videoUrl: 'https://example.com/deadlift.mp4',
          isCustom: false,
          userId: '',
        );

        // Act
        final json = exercise.toJson();

        // Assert
        expect(json['name'], equals('Deadlift'));
        expect(json['category'], equals('Strength'));
        expect(json['description'], equals('Full-body compound exercise'));
        expect(
          json['muscle_groups'],
          equals(['Hamstrings', 'Glutes', 'Lower Back']),
        );
        expect(json['image_url'], equals('https://example.com/deadlift.jpg'));
        expect(json['video_url'], equals('https://example.com/deadlift.mp4'));
        expect(json['is_custom'], equals(false));
        expect(json['user_id'], isNull); // Empty string becomes null in JSON
      });

      test('should handle custom exercise JSON conversion', () {
        // Arrange
        final exercise = Exercise(
          id: 'custom_id',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'My Custom Exercise',
          category: 'Custom',
          description: 'Custom description',
          muscleGroups: ['Custom Muscle'],
          isCustom: true,
          userId: 'user456',
        );

        // Act
        final json = exercise.toJson();

        // Assert
        expect(json['name'], equals('My Custom Exercise'));
        expect(json['is_custom'], equals(true));
        expect(json['user_id'], equals('user456'));
        expect(json['image_url'], isNull);
        expect(json['video_url'], isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        final original = Exercise(
          id: 'original_id',
          created: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updated: DateTime.parse('2024-01-15T10:30:00.000Z'),
          name: 'Original Exercise',
          category: 'Strength',
          description: 'Original description',
          muscleGroups: ['Original Muscle'],
          isCustom: false,
          userId: '',
        );

        // Act
        final copy = original.copyWith(
          name: 'Updated Exercise',
          category: 'Cardio',
          muscleGroups: ['Updated Muscle'],
        );

        // Assert
        expect(copy.id, equals('original_id')); // Unchanged
        expect(copy.name, equals('Updated Exercise')); // Changed
        expect(copy.category, equals('Cardio')); // Changed
        expect(copy.description, equals('Original description')); // Unchanged
        expect(copy.muscleGroups, equals(['Updated Muscle'])); // Changed
        expect(copy.isCustom, equals(false)); // Unchanged
      });

      test('should create identical copy when no parameters provided', () {
        // Arrange
        final original = Exercise(
          id: 'test_id',
          created: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updated: DateTime.parse('2024-01-15T10:30:00.000Z'),
          name: 'Test Exercise',
          category: 'Test',
          description: 'Test description',
          muscleGroups: ['Test Muscle'],
          isCustom: true,
          userId: 'test_user',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, equals(original.id));
        expect(copy.name, equals(original.name));
        expect(copy.category, equals(original.category));
        expect(copy.description, equals(original.description));
        expect(copy.muscleGroups, equals(original.muscleGroups));
        expect(copy.isCustom, equals(original.isCustom));
        expect(copy.userId, equals(original.userId));
      });
    });

    group('Factory Constructors', () {
      test('should create built-in exercise correctly', () {
        // Act
        final exercise = Exercise.builtin(
          id: 'builtin_id',
          created: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updated: DateTime.parse('2024-01-15T10:30:00.000Z'),
          name: 'Built-in Exercise',
          category: 'Strength',
          description: 'System exercise',
          muscleGroups: ['System Muscle'],
          imageUrl: 'https://example.com/builtin.jpg',
        );

        // Assert
        expect(exercise.isCustom, equals(false));
        expect(exercise.isBuiltIn, equals(true));
        expect(exercise.userId, equals(''));
        expect(exercise.name, equals('Built-in Exercise'));
        expect(exercise.imageUrl, equals('https://example.com/builtin.jpg'));
        expect(exercise.videoUrl, isNull);
      });

      test('should create custom exercise correctly', () {
        // Act
        final exercise = Exercise.custom(
          id: 'custom_id',
          created: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updated: DateTime.parse('2024-01-15T10:30:00.000Z'),
          name: 'Custom Exercise',
          category: 'Custom',
          description: 'User exercise',
          muscleGroups: ['Custom Muscle'],
          userId: 'user789',
          videoUrl: 'https://example.com/custom.mp4',
        );

        // Assert
        expect(exercise.isCustom, equals(true));
        expect(exercise.isBuiltIn, equals(false));
        expect(exercise.userId, equals('user789'));
        expect(exercise.name, equals('Custom Exercise'));
        expect(exercise.videoUrl, equals('https://example.com/custom.mp4'));
        expect(exercise.imageUrl, isNull);
      });
    });

    group('Mixins Functionality', () {
      test('should correctly implement UserOwnedModel mixin', () {
        // Arrange
        final userExercise = Exercise.custom(
          id: 'user_exercise',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'User Exercise',
          category: 'Custom',
          description: 'User-created exercise',
          muscleGroups: ['User Muscle'],
          userId: 'user123',
        );

        final systemExercise = Exercise.builtin(
          id: 'system_exercise',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'System Exercise',
          category: 'Strength',
          description: 'Built-in exercise',
          muscleGroups: ['System Muscle'],
        );

        // Act & Assert
        expect(userExercise.belongsToUser('user123'), equals(true));
        expect(userExercise.belongsToUser('other_user'), equals(false));
        expect(userExercise.belongsToUser(null), equals(false));

        expect(systemExercise.belongsToUser('any_user'), equals(false));
        expect(systemExercise.belongsToUser(null), equals(false));
      });

      test('should correctly implement CustomizableModel mixin', () {
        // Arrange
        final customExercise = Exercise.custom(
          id: 'custom',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Custom',
          category: 'Custom',
          description: 'Custom exercise',
          muscleGroups: ['Custom'],
          userId: 'user123',
        );

        final builtinExercise = Exercise.builtin(
          id: 'builtin',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Built-in',
          category: 'Strength',
          description: 'Built-in exercise',
          muscleGroups: ['Built-in'],
        );

        // Act & Assert
        expect(customExercise.isCustom, equals(true));
        expect(customExercise.isBuiltIn, equals(false));

        expect(builtinExercise.isCustom, equals(false));
        expect(builtinExercise.isBuiltIn, equals(true));
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when IDs match', () {
        // Arrange
        final exercise1 = Exercise.builtin(
          id: 'same_id',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Exercise 1',
          category: 'Strength',
          description: 'Description 1',
          muscleGroups: ['Muscle 1'],
        );

        final exercise2 = Exercise.builtin(
          id: 'same_id',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Exercise 2', // Different name
          category: 'Cardio', // Different category
          description: 'Description 2', // Different description
          muscleGroups: ['Muscle 2'], // Different muscles
        );

        // Act & Assert
        expect(exercise1, equals(exercise2));
        expect(exercise1.hashCode, equals(exercise2.hashCode));
      });

      test('should not be equal when IDs differ', () {
        // Arrange
        final exercise1 = Exercise.builtin(
          id: 'id1',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Same Exercise',
          category: 'Strength',
          description: 'Same description',
          muscleGroups: ['Same Muscle'],
        );

        final exercise2 = Exercise.builtin(
          id: 'id2',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Same Exercise', // Same content
          category: 'Strength',
          description: 'Same description',
          muscleGroups: ['Same Muscle'],
        );

        // Act & Assert
        expect(exercise1, isNot(equals(exercise2)));
        expect(exercise1.hashCode, isNot(equals(exercise2.hashCode)));
      });
    });

    group('toString', () {
      test('should provide meaningful string representation', () {
        // Arrange
        final exercise = Exercise.custom(
          id: 'test_id',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Test Exercise',
          category: 'Test Category',
          description: 'Test description',
          muscleGroups: ['Test Muscle'],
          userId: 'test_user',
        );

        // Act
        final string = exercise.toString();

        // Assert
        expect(string, contains('Exercise'));
        expect(string, contains('test_id'));
        expect(string, contains('Test Exercise'));
        expect(string, contains('Test Category'));
        expect(string, contains('true')); // isCustom
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle malformed JSON gracefully', () {
        // Arrange
        final malformedJson = <String, dynamic>{
          'id': 'test_id',
          'created': 'invalid_date',
          'updated': 'invalid_date',
          // Missing required fields
        };

        // Act & Assert - Should not throw, should use defaults
        expect(() => Exercise.fromJson(malformedJson), returnsNormally);

        final exercise = Exercise.fromJson(malformedJson);
        expect(exercise.id, equals('test_id'));
        expect(exercise.name, equals(''));
        expect(exercise.category, equals(''));
        expect(exercise.description, equals(''));
        expect(exercise.muscleGroups, isEmpty);
      });

      test('should handle very long muscle groups list', () {
        // Arrange
        final longMuscleGroups = List.generate(50, (index) => 'Muscle $index');
        final exercise = Exercise.builtin(
          id: 'test_id',
          created: DateTime.now(),
          updated: DateTime.now(),
          name: 'Complex Exercise',
          category: 'Complex',
          description: 'Exercise with many muscle groups',
          muscleGroups: longMuscleGroups,
        );

        // Act
        final json = exercise.toJson();
        final recreated = Exercise.fromJson({
          'id': 'test_id',
          'created': DateTime.now().toIso8601String(),
          'updated': DateTime.now().toIso8601String(),
          ...json,
        });

        // Assert
        expect(recreated.muscleGroups.length, equals(50));
        expect(recreated.muscleGroups, equals(longMuscleGroups));
      });
    });
  });
}
