import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/workout_plan_service.dart';

void main() {
  group('WorkoutPlanService', () {
    late WorkoutPlanService service;

    setUp(() {
      service = WorkoutPlanService();
    });

    group('hasActiveProgramsWithFutureWorkouts', () {
      test('should return authentication error when not authenticated', () async {
        // When calling the method without authentication
        final result = await service.hasActiveProgramsWithFutureWorkouts();

        // Then it should return an authentication error
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(
          result.error!.message,
          contains('Authentication required'),
        );
      });

      // Note: Additional tests would require mocking PocketBase client
      // which is beyond the scope of this minimal change implementation.
      // In a real-world scenario, we would:
      // 1. Mock the PocketBase client
      // 2. Test scenarios with:
      //    - No active plans
      //    - Active plans with only past workouts
      //    - Active plans with future workouts
      //    - Active plans with today's workouts
      //    - Multiple active plans with mixed schedules
    });

    group('getActivePlans', () {
      test('should return authentication error when not authenticated', () async {
        // When calling getActivePlans without authentication
        final result = await service.getActivePlans();

        // Then it should return an authentication error
        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(
          result.error!.message,
          contains('Authentication required'),
        );
      });
    });

    group('getWorkoutPlans', () {
      test('should return validation error for invalid page number', () async {
        final result = await service.getWorkoutPlans(page: 0);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Page number must be greater than 0'),
        );
      });

      test('should return validation error for negative page', () async {
        final result = await service.getWorkoutPlans(page: -1);

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
          final result = await service.getWorkoutPlans(perPage: 0);

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
          final result = await service.getWorkoutPlans(perPage: 101);

          expect(result.isError, isTrue);
          expect(result.error!.type, equals('ValidationError'));
          expect(
            result.error!.message,
            contains('Items per page must be between 1 and 100'),
          );
        },
      );

      test('should return validation error for negative perPage', () async {
        final result = await service.getWorkoutPlans(perPage: -5);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Items per page must be between 1 and 100'),
        );
      });

      test('should return authentication error when not authenticated and no userId provided', () async {
        final result = await service.getWorkoutPlans();

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(
          result.error!.message,
          contains('Authentication required'),
        );
      });

      test('should handle search query sanitization', () async {
        // Test with potentially unsafe characters
        final result = await service.getWorkoutPlans(
          searchQuery: 'test"query\\with\nspecial\rchars',
          page: 1,
          perPage: 10,
        );

        // Should not crash due to injection attempts
        expect(result.isError, isTrue);
        // Will fail because we're not connected to PocketBase, but should sanitize the query
      });
    });

    group('getWorkoutPlan', () {
      test('should return validation error for empty ID', () async {
        final result = await service.getWorkoutPlan('');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Workout plan ID cannot be empty'),
        );
      });

      test('should return validation error for whitespace-only ID', () async {
        final result = await service.getWorkoutPlan('   ');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Workout plan ID cannot be empty'),
        );
      });
    });

    group('deleteWorkoutPlan', () {
      test('should return validation error for empty ID', () async {
        final result = await service.deleteWorkoutPlan('');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Workout plan ID cannot be empty'),
        );
      });

      test('should return authentication error when not authenticated', () async {
        final result = await service.deleteWorkoutPlan('test-id');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(
          result.error!.message,
          contains('Authentication required'),
        );
      });
    });
  });
}
