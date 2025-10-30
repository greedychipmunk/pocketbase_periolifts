import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/workout_history_service.dart';
import '../../../lib/models/workout_history.dart';

void main() {
  group('WorkoutHistoryService', () {
    test('should require authentication for all operations', () async {
      final service = WorkoutHistoryService();
      final result = await service.getWorkoutHistory();

      expect(result.isError, isTrue);
      expect(result.error!.type, 'AuthenticationError');
      expect(result.error!.message, contains('Authentication required'));
    });

    test('should complete operations within performance bounds', () async {
      final service = WorkoutHistoryService();
      final stopwatch = Stopwatch()..start();

      final result = await service.getWorkoutHistory();

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(result.isError, isTrue);
    });
  });
}
