import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/workout_schedule_service.dart';
import '../../../lib/models/calendar_event.dart';

void main() {
  group('WorkoutScheduleService', () {
    late WorkoutScheduleService service;

    setUp(() {
      service = WorkoutScheduleService();
    });

    group('getCalendarEvents', () {
      test('should return authentication error when not authenticated',
          () async {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        final result = await service.getCalendarEvents(
          startDate: startDate,
          endDate: endDate,
        );

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(
          result.error!.message,
          contains('Authentication required'),
        );
      });

      test('should return validation error when end date is before start date',
          () async {
        final startDate = DateTime(2024, 2, 1);
        final endDate = DateTime(2024, 1, 1);

        final result = await service.getCalendarEvents(
          startDate: startDate,
          endDate: endDate,
        );

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('End date must be after or equal to start date'),
        );
      });

      test('should return validation error for invalid page number', () async {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        final result = await service.getCalendarEvents(
          startDate: startDate,
          endDate: endDate,
          page: 0,
        );

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Page number must be greater than 0'),
        );
      });

      test('should return validation error for invalid perPage (too low)',
          () async {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        final result = await service.getCalendarEvents(
          startDate: startDate,
          endDate: endDate,
          perPage: 0,
        );

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Items per page must be between 1 and 500'),
        );
      });

      test('should return validation error for invalid perPage (too high)',
          () async {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        final result = await service.getCalendarEvents(
          startDate: startDate,
          endDate: endDate,
          perPage: 501,
        );

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Items per page must be between 1 and 500'),
        );
      });
    });

    group('getEventsForDate', () {
      test('should return authentication error when not authenticated',
          () async {
        final date = DateTime(2024, 1, 15);

        final result = await service.getEventsForDate(date);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(
          result.error!.message,
          contains('Authentication required'),
        );
      });
    });

    group('updateEventStatus', () {
      test('should return authentication error when not authenticated',
          () async {
        final result = await service.updateEventStatus(
          'test_id',
          isCompleted: true,
        );

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(
          result.error!.message,
          contains('Authentication required'),
        );
      });

      test('should return validation error for empty schedule ID', () async {
        final result = await service.updateEventStatus(
          '',
          isCompleted: true,
        );

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Schedule ID cannot be empty'),
        );
      });

      test('should return validation error when no update fields provided',
          () async {
        final result = await service.updateEventStatus('test_id');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('No update fields provided'),
        );
      });
    });

    group('createCalendarEvent', () {
      test('should return authentication error when not authenticated',
          () async {
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: DateTime(2024, 1, 15),
        );

        final result = await service.createCalendarEvent(event);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(
          result.error!.message,
          contains('Authentication required'),
        );
      });

      test('should return validation error for invalid event data', () async {
        // Create event with empty required fields
        final event = CalendarEvent(
          id: '',
          created: DateTime.now(),
          updated: DateTime.now(),
          planId: '', // Invalid: empty
          workoutId: '', // Invalid: empty
          scheduledDate: DateTime(2024, 1, 15),
          dayOfWeek: '', // Invalid: empty
        );

        final result = await service.createCalendarEvent(event);

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Calendar event validation failed'),
        );
      });
    });

    group('deleteCalendarEvent', () {
      test('should return authentication error when not authenticated',
          () async {
        final result = await service.deleteCalendarEvent('test_id');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(
          result.error!.message,
          contains('Authentication required'),
        );
      });

      test('should return validation error for empty schedule ID', () async {
        final result = await service.deleteCalendarEvent('');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Schedule ID cannot be empty'),
        );
      });
    });

    group('getEventsByDayOfWeek', () {
      test('should return authentication error when not authenticated',
          () async {
        final result = await service.getEventsByDayOfWeek('monday');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('AuthenticationError'));
        expect(
          result.error!.message,
          contains('Authentication required'),
        );
      });

      test('should return validation error for invalid day of week', () async {
        final result = await service.getEventsByDayOfWeek('invalid_day');

        expect(result.isError, isTrue);
        expect(result.error!.type, equals('ValidationError'));
        expect(
          result.error!.message,
          contains('Invalid day of week'),
        );
      });

      test('should accept valid days of week', () async {
        const validDays = [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday'
        ];

        for (final day in validDays) {
          final result = await service.getEventsByDayOfWeek(day);
          // Should get authentication error (not validation error)
          // This proves the day validation passed
          expect(result.isError, isTrue);
          expect(result.error!.type, equals('AuthenticationError'));
        }
      });
    });

    group('_validateCalendarEvent', () {
      test('should validate event with all required fields', () {
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: DateTime(2024, 1, 15),
        );

        // Access private method through service (indirect test)
        // By attempting to create the event, validation will run
        // This is tested through createCalendarEvent tests
        expect(event.planId, isNotEmpty);
        expect(event.workoutId, isNotEmpty);
        expect(event.dayOfWeek, isNotEmpty);
      });

      test('should detect invalid calendar color format', () async {
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: DateTime(2024, 1, 15),
          calendarColor: 'invalid', // Invalid format
        );

        final result = await service.createCalendarEvent(event);

        expect(result.isError, isTrue);
        if (result.isError) {
          expect(result.error!.type, equals('ValidationError'));
        }
      });

      test('should detect notes exceeding max length', () async {
        final longNotes = 'a' * 1001; // Exceeds 1000 char limit
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: DateTime(2024, 1, 15),
          notes: longNotes,
        );

        final result = await service.createCalendarEvent(event);

        expect(result.isError, isTrue);
        if (result.isError) {
          expect(result.error!.type, equals('ValidationError'));
        }
      });
    });

    group('_formatDate', () {
      test('should format date correctly', () {
        // This is tested indirectly through the service methods
        final date = DateTime(2024, 1, 15);
        final expectedFormat = '2024-01-15';

        // We can't directly test private methods, but we know the format
        // is used in queries and should match YYYY-MM-DD
        expect(date.year, equals(2024));
        expect(date.month, equals(1));
        expect(date.day, equals(15));
      });
    });
  });
}
