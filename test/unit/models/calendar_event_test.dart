import 'package:flutter_test/flutter_test.dart';
import '../../../lib/models/calendar_event.dart';

void main() {
  group('CalendarEvent', () {
    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final json = {
          'id': 'event_123',
          'created': '2024-01-01T10:00:00Z',
          'updated': '2024-01-01T10:00:00Z',
          'plan_id': 'plan_456',
          'workout_id': 'workout_789',
          'scheduled_date': '2024-01-15T00:00:00Z',
          'day_of_week': 'monday',
          'sort_order': 0,
          'is_rest_day': false,
        };

        final event = CalendarEvent.fromJson(json);

        expect(event.id, equals('event_123'));
        expect(event.planId, equals('plan_456'));
        expect(event.workoutId, equals('workout_789'));
        expect(event.scheduledDate.day, equals(15));
        expect(event.dayOfWeek, equals('monday'));
        expect(event.sortOrder, equals(0));
        expect(event.isRestDay, isFalse);
      });

      test('should parse JSON with optional fields', () {
        final json = {
          'id': 'event_123',
          'created': '2024-01-01T10:00:00Z',
          'updated': '2024-01-01T10:00:00Z',
          'plan_id': 'plan_456',
          'workout_id': 'workout_789',
          'scheduled_date': '2024-01-15T00:00:00Z',
          'day_of_week': 'tuesday',
          'sort_order': 1,
          'is_rest_day': true,
          'notes': 'Test notes',
          'calendar_color': '#FF5733',
          'is_completed': true,
          'completion_date': '2024-01-15T18:30:00Z',
        };

        final event = CalendarEvent.fromJson(json);

        expect(event.notes, equals('Test notes'));
        expect(event.calendarColor, equals('#FF5733'));
        expect(event.isCompleted, isTrue);
        expect(event.completionDate, isNotNull);
        expect(event.completionDate!.day, equals(15));
      });

      test('should parse JSON with expanded plan data', () {
        final json = {
          'id': 'event_123',
          'created': '2024-01-01T10:00:00Z',
          'updated': '2024-01-01T10:00:00Z',
          'plan_id': 'plan_456',
          'workout_id': 'workout_789',
          'scheduled_date': '2024-01-15T00:00:00Z',
          'day_of_week': 'wednesday',
          'expand': {
            'plan_id': {
              'name': 'Test Plan',
              'description': 'Test Description',
            },
          },
        };

        final event = CalendarEvent.fromJson(json);

        expect(event.planName, equals('Test Plan'));
        expect(event.planDescription, equals('Test Description'));
      });

      test('should handle missing optional fields gracefully', () {
        final json = {
          'id': 'event_123',
          'created': '2024-01-01T10:00:00Z',
          'updated': '2024-01-01T10:00:00Z',
          'plan_id': 'plan_456',
          'workout_id': 'workout_789',
          'scheduled_date': '2024-01-15T00:00:00Z',
          'day_of_week': 'thursday',
        };

        final event = CalendarEvent.fromJson(json);

        expect(event.notes, isNull);
        expect(event.calendarColor, isNull);
        expect(event.isCompleted, isNull);
        expect(event.completionDate, isNull);
        expect(event.planName, isNull);
        expect(event.planDescription, isNull);
      });

      test('should throw FormatException for invalid JSON', () {
        final json = {
          'id': 'event_123',
          // Missing required fields
        };

        expect(
          () => CalendarEvent.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final now = DateTime(2024, 1, 1, 10, 0, 0);
        final scheduledDate = DateTime(2024, 1, 15);
        final completionDate = DateTime(2024, 1, 15, 18, 30);

        final event = CalendarEvent(
          id: 'event_123',
          created: now,
          updated: now,
          planId: 'plan_456',
          workoutId: 'workout_789',
          scheduledDate: scheduledDate,
          dayOfWeek: 'monday',
          sortOrder: 1,
          isRestDay: true,
          notes: 'Test notes',
          calendarColor: '#FF5733',
          isCompleted: true,
          completionDate: completionDate,
        );

        final json = event.toJson();

        expect(json['id'], equals('event_123'));
        expect(json['plan_id'], equals('plan_456'));
        expect(json['workout_id'], equals('workout_789'));
        expect(json['day_of_week'], equals('monday'));
        expect(json['sort_order'], equals(1));
        expect(json['is_rest_day'], isTrue);
        expect(json['notes'], equals('Test notes'));
        expect(json['calendar_color'], equals('#FF5733'));
        expect(json['is_completed'], isTrue);
        expect(json.containsKey('completion_date'), isTrue);
      });

      test('should exclude null optional fields from JSON', () {
        final now = DateTime(2024, 1, 1, 10, 0, 0);
        final scheduledDate = DateTime(2024, 1, 15);

        final event = CalendarEvent(
          id: 'event_123',
          created: now,
          updated: now,
          planId: 'plan_456',
          workoutId: 'workout_789',
          scheduledDate: scheduledDate,
          dayOfWeek: 'monday',
        );

        final json = event.toJson();

        expect(json.containsKey('notes'), isFalse);
        expect(json.containsKey('calendar_color'), isFalse);
        expect(json.containsKey('is_completed'), isFalse);
        expect(json.containsKey('completion_date'), isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final now = DateTime(2024, 1, 1, 10, 0, 0);
        final original = CalendarEvent(
          id: 'event_123',
          created: now,
          updated: now,
          planId: 'plan_456',
          workoutId: 'workout_789',
          scheduledDate: DateTime(2024, 1, 15),
          dayOfWeek: 'monday',
        );

        final copy = original.copyWith(
          notes: 'Updated notes',
          isCompleted: true,
        );

        expect(copy.id, equals(original.id));
        expect(copy.planId, equals(original.planId));
        expect(copy.notes, equals('Updated notes'));
        expect(copy.isCompleted, isTrue);
      });

      test('should preserve original values when not updated', () {
        final now = DateTime(2024, 1, 1, 10, 0, 0);
        final original = CalendarEvent(
          id: 'event_123',
          created: now,
          updated: now,
          planId: 'plan_456',
          workoutId: 'workout_789',
          scheduledDate: DateTime(2024, 1, 15),
          dayOfWeek: 'monday',
          notes: 'Original notes',
        );

        final copy = original.copyWith(isCompleted: true);

        expect(copy.notes, equals('Original notes'));
        expect(copy.planId, equals('plan_456'));
        expect(copy.workoutId, equals('workout_789'));
      });
    });

    group('dateKey', () {
      test('should format date key correctly', () {
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: DateTime(2024, 1, 5),
        );

        expect(event.dateKey, equals('2024-01-05'));
      });

      test('should pad single digits with zeros', () {
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: DateTime(2024, 1, 1),
        );

        expect(event.dateKey, equals('2024-01-01'));
      });
    });

    group('isPast', () {
      test('should return true for past dates', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: yesterday,
        );

        expect(event.isPast, isTrue);
      });

      test('should return false for today', () {
        final today = DateTime.now();
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: today,
        );

        expect(event.isPast, isFalse);
      });

      test('should return false for future dates', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: tomorrow,
        );

        expect(event.isPast, isFalse);
      });
    });

    group('isToday', () {
      test('should return true for today', () {
        final today = DateTime.now();
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: today,
        );

        expect(event.isToday, isTrue);
      });

      test('should return false for past dates', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: yesterday,
        );

        expect(event.isToday, isFalse);
      });

      test('should return false for future dates', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: tomorrow,
        );

        expect(event.isToday, isFalse);
      });
    });

    group('isFuture', () {
      test('should return true for future dates', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: tomorrow,
        );

        expect(event.isFuture, isTrue);
      });

      test('should return false for today', () {
        final today = DateTime.now();
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: today,
        );

        expect(event.isFuture, isFalse);
      });

      test('should return false for past dates', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: yesterday,
        );

        expect(event.isFuture, isFalse);
      });
    });

    group('create factory', () {
      test('should create event with default values', () {
        final scheduledDate = DateTime(2024, 1, 15); // Monday
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: scheduledDate,
        );

        expect(event.planId, equals('plan_1'));
        expect(event.workoutId, equals('workout_1'));
        expect(event.scheduledDate, equals(scheduledDate));
        expect(event.dayOfWeek, equals('monday'));
        expect(event.sortOrder, equals(0));
        expect(event.isRestDay, isFalse);
      });

      test('should create event with custom values', () {
        final scheduledDate = DateTime(2024, 1, 15);
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: scheduledDate,
          sortOrder: 2,
          isRestDay: true,
          notes: 'Custom notes',
          calendarColor: '#FF5733',
        );

        expect(event.sortOrder, equals(2));
        expect(event.isRestDay, isTrue);
        expect(event.notes, equals('Custom notes'));
        expect(event.calendarColor, equals('#FF5733'));
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final now = DateTime(2024, 1, 1, 10, 0, 0);
        final scheduledDate = DateTime(2024, 1, 15);

        final event1 = CalendarEvent(
          id: 'event_123',
          created: now,
          updated: now,
          planId: 'plan_456',
          workoutId: 'workout_789',
          scheduledDate: scheduledDate,
          dayOfWeek: 'monday',
        );

        final event2 = CalendarEvent(
          id: 'event_123',
          created: now,
          updated: now,
          planId: 'plan_456',
          workoutId: 'workout_789',
          scheduledDate: scheduledDate,
          dayOfWeek: 'monday',
        );

        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should not be equal for different IDs', () {
        final now = DateTime(2024, 1, 1, 10, 0, 0);
        final scheduledDate = DateTime(2024, 1, 15);

        final event1 = CalendarEvent(
          id: 'event_123',
          created: now,
          updated: now,
          planId: 'plan_456',
          workoutId: 'workout_789',
          scheduledDate: scheduledDate,
          dayOfWeek: 'monday',
        );

        final event2 = CalendarEvent(
          id: 'event_456',
          created: now,
          updated: now,
          planId: 'plan_456',
          workoutId: 'workout_789',
          scheduledDate: scheduledDate,
          dayOfWeek: 'monday',
        );

        expect(event1, isNot(equals(event2)));
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        final event = CalendarEvent.create(
          planId: 'plan_1',
          workoutId: 'workout_1',
          scheduledDate: DateTime(2024, 1, 15),
        );

        final str = event.toString();

        expect(str, contains('CalendarEvent'));
        expect(str, contains('plan_1'));
        expect(str, contains('workout_1'));
        expect(str, contains('2024-01-15'));
        expect(str, contains('monday'));
      });
    });
  });
}
