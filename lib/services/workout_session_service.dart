import '../models/workout_session.dart';
import 'base_pocketbase_service.dart';

class WorkoutSessionService extends BasePocketBaseService {
  static const String collectionName = 'workout_sessions';

  // GET /workout-sessions (get user's workout sessions with pagination)
  Future<List<WorkoutSession>> getWorkoutSessions({
    int page = 1,
    int perPage = 20,
    WorkoutSessionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final filters = <String>[createUserFilter()];

      if (status != null) {
        filters.add('status = "${status.name}"');
      }

      if (startDate != null) {
        filters.add('scheduled_date >= "${startDate.toIso8601String()}"');
      }

      if (endDate != null) {
        filters.add('scheduled_date <= "${endDate.toIso8601String()}"');
      }

      final response = await pb
          .collection(collectionName)
          .getList(
            page: page,
            perPage: perPage,
            filter: combineFilters(filters),
            sort: '-created',
          );

      return response.items
          .map((record) => WorkoutSession.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      final message = handleError(e);
      throw Exception('Failed to load workout sessions: $message');
    }
  }

  // POST /workout-sessions (create new workout session)
  Future<WorkoutSession> createWorkoutSession(WorkoutSession session) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Authentication required');
      }

      final sessionData = session.toJson();
      sessionData['user_id'] = currentUserId;

      final record = await pb
          .collection(collectionName)
          .create(body: sessionData);

      return WorkoutSession.fromJson(record.toJson());
    } catch (e) {
      final message = handleError(e);
      throw Exception('Failed to create workout session: $message');
    }
  }

  // GET /workout-sessions/{sessionId} (get specific workout session)
  Future<WorkoutSession> getWorkoutSession(String sessionId) async {
    try {
      final record = await pb.collection(collectionName).getOne(sessionId);
      return WorkoutSession.fromJson(record.toJson());
    } catch (e) {
      final message = handleError(e);
      if (message.contains('404') || message.contains('not found')) {
        throw Exception('Workout session not found');
      }
      throw Exception('Failed to load workout session: $message');
    }
  }

  // PUT /workout-sessions/{sessionId} (update workout session)
  Future<WorkoutSession> updateWorkoutSession(WorkoutSession session) async {
    try {
      final sessionData = session.toJson();

      final record = await pb
          .collection(collectionName)
          .update(session.id, body: sessionData);

      return WorkoutSession.fromJson(record.toJson());
    } catch (e) {
      final message = handleError(e);
      if (message.contains('404') || message.contains('not found')) {
        throw Exception('Workout session not found');
      }
      throw Exception('Failed to update workout session: $message');
    }
  }

  // POST /workout-sessions/{sessionId}/start (start workout session)
  Future<WorkoutSession> startWorkoutSession(String sessionId) async {
    try {
      final session = await getWorkoutSession(sessionId);

      if (session.status == WorkoutSessionStatus.completed) {
        throw Exception('Cannot start a completed workout session');
      }

      final startedSession = session.copyWith(
        status: WorkoutSessionStatus.inProgress,
        startedAt: DateTime.now(),
        updated: DateTime.now(),
      );

      return await updateWorkoutSession(startedSession);
    } catch (e) {
      print('Error starting workout session: $e');
      rethrow;
    }
  }

  // POST /workout-sessions/{sessionId}/complete (complete workout session)
  Future<WorkoutSession> completeWorkoutSession(String sessionId) async {
    try {
      final session = await getWorkoutSession(sessionId);

      if (session.status == WorkoutSessionStatus.completed) {
        throw Exception('Workout session is already completed');
      }

      final now = DateTime.now();
      final completedSession = session.copyWith(
        status: WorkoutSessionStatus.completed,
        completedAt: now,
        updated: now,
        // If not started yet, set start time to now for duration calculation
        startedAt: session.startedAt ?? now,
      );

      return await updateWorkoutSession(completedSession);
    } catch (e) {
      print('Error completing workout session: $e');
      rethrow;
    }
  }

  // PUT /workout-sessions/{sessionId}/exercises/{exerciseId}/sets/{setId} (update set data)
  Future<WorkoutSession> updateSetData(
    String sessionId,
    String exerciseId,
    String setId,
    WorkoutSessionSet updatedSet,
  ) async {
    try {
      final session = await getWorkoutSession(sessionId);

      final exerciseIndex = session.exercises.indexWhere(
        (ex) => ex.exerciseId == exerciseId,
      );

      if (exerciseIndex == -1) {
        throw Exception('Exercise not found in workout session');
      }

      final exercise = session.exercises[exerciseIndex];
      final setIndex = exercise.sets.indexWhere((set) => set.setId == setId);

      if (setIndex == -1) {
        throw Exception('Set not found in exercise');
      }

      // Update the set
      final updatedSets = List<WorkoutSessionSet>.from(exercise.sets);
      updatedSets[setIndex] = updatedSet;

      // Update the exercise
      final updatedExercise = exercise.copyWith(sets: updatedSets);
      final updatedExercises = List<WorkoutSessionExercise>.from(
        session.exercises,
      );
      updatedExercises[exerciseIndex] = updatedExercise;

      // Update the session
      final updatedSession = session.copyWith(
        exercises: updatedExercises,
        updated: DateTime.now(),
      );

      return await updateWorkoutSession(updatedSession);
    } catch (e) {
      print('Error updating set data: $e');
      rethrow;
    }
  }

  // GET /workout-sessions/stats (get workout statistics)
  Future<WorkoutSessionStats> getWorkoutStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final defaultStartDate =
          startDate ?? DateTime(now.year, now.month - 1, now.day);
      final defaultEndDate = endDate ?? now;

      final sessions = await getWorkoutSessions(
        perPage: 1000, // Get all sessions for stats calculation
        startDate: defaultStartDate,
        endDate: defaultEndDate,
      );

      final completedSessions = sessions.where((s) => s.isCompleted).toList();

      int totalWorkoutTime = 0;
      int totalSets = 0;
      double totalWeightLifted = 0.0;

      for (final session in completedSessions) {
        if (session.duration != null) {
          totalWorkoutTime += session.duration!.inMinutes;
        }

        for (final exercise in session.exercises) {
          for (final set in exercise.sets) {
            if (set.completed &&
                set.actualWeight != null &&
                set.actualReps != null) {
              totalSets += 1;
              totalWeightLifted += set.actualWeight! * set.actualReps!;
            }
          }
        }
      }

      return WorkoutSessionStats(
        totalSessions: sessions.length,
        completedSessions: completedSessions.length,
        totalWorkoutTime: totalWorkoutTime,
        totalSets: totalSets,
        totalWeightLifted: totalWeightLifted,
        periodStart: defaultStartDate,
        periodEnd: defaultEndDate,
      );
    } catch (e) {
      print('Error fetching workout stats: $e');
      throw Exception('Failed to load workout statistics');
    }
  }

  // GET /workout-sessions/history (get workout history with pagination)
  Future<List<WorkoutSession>> getWorkoutHistory({
    int page = 1,
    int perPage = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await getWorkoutSessions(
      page: page,
      perPage: perPage,
      status: WorkoutSessionStatus.completed,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Delete workout session
  Future<void> deleteWorkoutSession(String sessionId) async {
    try {
      await pb.collection(collectionName).delete(sessionId);
    } catch (e) {
      final message = handleError(e);
      if (message.contains('404') || message.contains('not found')) {
        throw Exception('Workout session not found');
      }
      throw Exception('Failed to delete workout session: $message');
    }
  }

  // Create workout session from existing template/workout plan
  Future<WorkoutSession> createSessionFromTemplate({
    required String templateName,
    required String templateDescription,
    required List<WorkoutSessionExercise> exercises,
    DateTime? scheduledDate,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Authentication required');
    }

    final session = WorkoutSession(
      id: '', // Will be generated by PocketBase
      created: DateTime.now(),
      updated: DateTime.now(),
      userId: currentUserId!,
      name: templateName,
      description: templateDescription,
      exercises: exercises,
      scheduledDate: scheduledDate,
    );

    return await createWorkoutSession(session);
  }

  // Get active/in-progress workout session
  Future<WorkoutSession?> getActiveWorkoutSession() async {
    try {
      final sessions = await getWorkoutSessions(
        perPage: 1,
        status: WorkoutSessionStatus.inProgress,
      );

      return sessions.isNotEmpty ? sessions.first : null;
    } catch (e) {
      print('Error fetching active workout session: $e');
      return null;
    }
  }

  // Resume workout session (for offline support)
  Future<WorkoutSession> resumeWorkoutSession(String sessionId) async {
    try {
      final session = await getWorkoutSession(sessionId);

      if (session.status != WorkoutSessionStatus.inProgress) {
        throw Exception('Cannot resume a workout that is not in progress');
      }

      return session;
    } catch (e) {
      print('Error resuming workout session: $e');
      rethrow;
    }
  }
}
