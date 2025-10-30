import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import '../models/workout_session.dart';

class WorkoutSessionService {
  final Databases databases;
  final Account account;
  final String databaseId;
  final String workoutSessionsCollectionId;

  WorkoutSessionService({
    required this.databases,
    required Client client,
    this.databaseId = '685884d800152b208c1a',
    this.workoutSessionsCollectionId = 'workout-sessions',
  }) : account = Account(client);

  // GET /workout-sessions (get user's workout sessions with pagination)
  Future<List<WorkoutSession>> getWorkoutSessions({
    int limit = 20,
    int offset = 0,
    WorkoutSessionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final currentUser = await account.get();
      List<String> queries = [
        Query.equal('userId', currentUser.$id),
        Query.limit(limit),
        Query.offset(offset),
        Query.orderDesc('createdAt'),
      ];

      if (status != null) {
        queries.add(Query.equal('status', status.name));
      }

      if (startDate != null) {
        queries.add(Query.greaterThanEqual('scheduledDate', startDate.toIso8601String()));
      }

      if (endDate != null) {
        queries.add(Query.lessThanEqual('scheduledDate', endDate.toIso8601String()));
      }

      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: workoutSessionsCollectionId,
        queries: queries,
      );

      return response.documents
          .map((doc) => WorkoutSession.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        throw Exception('Authentication required');
      }
      print('Error fetching workout sessions: $e');
      throw Exception('Failed to load workout sessions: ${e.message}');
    } catch (e) {
      print('Error fetching workout sessions: $e');
      throw Exception('Failed to load workout sessions');
    }
  }

  // POST /workout-sessions (create new workout session)
  Future<WorkoutSession> createWorkoutSession(WorkoutSession session) async {
    try {
      final currentUser = await account.get();
      final now = DateTime.now();
      final sessionWithUser = session.copyWith(
        userId: currentUser.$id,
        createdAt: now,
        updatedAt: now,
      );

      final document = await databases.createDocument(
        databaseId: databaseId,
        collectionId: workoutSessionsCollectionId,
        documentId: ID.unique(),
        data: sessionWithUser.toJson(),
      );

      return WorkoutSession.fromJson(document.data);
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        throw Exception('Authentication required');
      }
      print('Error creating workout session: $e');
      throw Exception('Failed to create workout session: ${e.message}');
    } catch (e) {
      print('Error creating workout session: $e');
      throw Exception('Failed to create workout session');
    }
  }

  // GET /workout-sessions/{sessionId} (get specific workout session)
  Future<WorkoutSession> getWorkoutSession(String sessionId) async {
    try {
      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: workoutSessionsCollectionId,
        documentId: sessionId,
      );

      return WorkoutSession.fromJson(document.data);
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        throw Exception('Authentication required');
      } else if (e.code == 404) {
        throw Exception('Workout session not found');
      }
      print('Error fetching workout session: $e');
      throw Exception('Failed to load workout session: ${e.message}');
    } catch (e) {
      print('Error fetching workout session: $e');
      throw Exception('Failed to load workout session');
    }
  }

  // PUT /workout-sessions/{sessionId} (update workout session)
  Future<WorkoutSession> updateWorkoutSession(WorkoutSession session) async {
    try {
      final updatedSession = session.copyWith(updatedAt: DateTime.now());
      
      final document = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: workoutSessionsCollectionId,
        documentId: session.sessionId,
        data: updatedSession.toJson(),
      );

      return WorkoutSession.fromJson(document.data);
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        throw Exception('Authentication required');
      } else if (e.code == 404) {
        throw Exception('Workout session not found');
      }
      print('Error updating workout session: $e');
      throw Exception('Failed to update workout session: ${e.message}');
    } catch (e) {
      print('Error updating workout session: $e');
      throw Exception('Failed to update workout session');
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
        updatedAt: DateTime.now(),
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
        updatedAt: now,
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
      final updatedExercises = List<WorkoutSessionExercise>.from(session.exercises);
      updatedExercises[exerciseIndex] = updatedExercise;

      // Update the session
      final updatedSession = session.copyWith(
        exercises: updatedExercises,
        updatedAt: DateTime.now(),
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
      final currentUser = await account.get();
      final now = DateTime.now();
      final defaultStartDate = startDate ?? DateTime(now.year, now.month - 1, now.day);
      final defaultEndDate = endDate ?? now;

      final sessions = await getWorkoutSessions(
        limit: 1000, // Get all sessions for stats calculation
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
            if (set.completed && set.actualWeight != null && set.actualReps != null) {
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
    int limit = 20,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await getWorkoutSessions(
      limit: limit,
      offset: offset,
      status: WorkoutSessionStatus.completed,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Delete workout session
  Future<void> deleteWorkoutSession(String sessionId) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: workoutSessionsCollectionId,
        documentId: sessionId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        throw Exception('Authentication required');
      } else if (e.code == 404) {
        throw Exception('Workout session not found');
      }
      print('Error deleting workout session: $e');
      throw Exception('Failed to delete workout session: ${e.message}');
    } catch (e) {
      print('Error deleting workout session: $e');
      throw Exception('Failed to delete workout session');
    }
  }

  // Create workout session from existing template/workout plan
  Future<WorkoutSession> createSessionFromTemplate({
    required String templateName,
    required String templateDescription,
    required List<WorkoutSessionExercise> exercises,
    DateTime? scheduledDate,
  }) async {
    final session = WorkoutSession(
      sessionId: '',  // Will be generated by Appwrite
      userId: '',     // Will be set in createWorkoutSession
      name: templateName,
      description: templateDescription,
      exercises: exercises,
      scheduledDate: scheduledDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await createWorkoutSession(session);
  }

  // Get active/in-progress workout session
  Future<WorkoutSession?> getActiveWorkoutSession() async {
    try {
      final sessions = await getWorkoutSessions(
        limit: 1,
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