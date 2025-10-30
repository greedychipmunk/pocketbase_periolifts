import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/workout_session.dart';
import 'workout_session_service.dart';

class CachedWorkoutSessionService {
  final WorkoutSessionService _remoteService;
  static const String _cacheFileName = 'workout_sessions_cache.json';
  static const String _statsFileName = 'workout_stats_cache.json';
  static const Duration _cacheTimeout = Duration(hours: 1);

  CachedWorkoutSessionService(this._remoteService);

  // Cache management
  Future<File> _getCacheFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  Future<Map<String, dynamic>?> _readCache(String fileName) async {
    try {
      final file = await _getCacheFile(fileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        
        // Check if cache is expired
        final timestamp = DateTime.tryParse(data['timestamp'] as String? ?? '');
        if (timestamp != null && 
            DateTime.now().difference(timestamp) < _cacheTimeout) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (e) {
      print('Error reading cache: $e');
    }
    return null;
  }

  Future<void> _writeCache(String fileName, Map<String, dynamic> data) async {
    try {
      final file = await _getCacheFile(fileName);
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      await file.writeAsString(jsonEncode(cacheData));
    } catch (e) {
      print('Error writing cache: $e');
    }
  }

  Future<void> _clearCache(String fileName) async {
    try {
      final file = await _getCacheFile(fileName);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Cached methods
  Future<List<WorkoutSession>> getWorkoutSessions({
    int limit = 20,
    int offset = 0,
    WorkoutSessionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'sessions_${limit}_${offset}_${status?.name}_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}';
    
    if (!forceRefresh) {
      final cached = await _readCache(_cacheFileName);
      if (cached != null && cached.containsKey(cacheKey)) {
        final sessionsList = cached[cacheKey] as List;
        return sessionsList.map((json) => WorkoutSession.fromJson(json)).toList();
      }
    }

    try {
      final sessions = await _remoteService.getWorkoutSessions(
        limit: limit,
        offset: offset,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      // Cache the result
      final cached = await _readCache(_cacheFileName) ?? {};
      cached[cacheKey] = sessions.map((s) => s.toJson()).toList();
      await _writeCache(_cacheFileName, cached);

      return sessions;
    } catch (e) {
      // If remote fails, try to return cached data even if expired
      final cached = await _getCacheFile(_cacheFileName);
      if (await cached.exists()) {
        try {
          final content = await cached.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          final cachedData = data['data'] as Map<String, dynamic>?;
          if (cachedData != null && cachedData.containsKey(cacheKey)) {
            final sessionsList = cachedData[cacheKey] as List;
            return sessionsList.map((json) => WorkoutSession.fromJson(json)).toList();
          }
        } catch (cacheError) {
          print('Error reading expired cache: $cacheError');
        }
      }
      rethrow;
    }
  }

  Future<WorkoutSession> createWorkoutSession(WorkoutSession session) async {
    try {
      final createdSession = await _remoteService.createWorkoutSession(session);
      
      // Clear cache to ensure fresh data on next fetch
      await _clearCache(_cacheFileName);
      
      return createdSession;
    } catch (e) {
      // Store for later sync when online
      await _storePendingOperation('create', session.toJson());
      rethrow;
    }
  }

  Future<WorkoutSession> getWorkoutSession(String sessionId) async {
    final cacheKey = 'session_$sessionId';
    
    final cached = await _readCache(_cacheFileName);
    if (cached != null && cached.containsKey(cacheKey)) {
      return WorkoutSession.fromJson(cached[cacheKey]);
    }

    try {
      final session = await _remoteService.getWorkoutSession(sessionId);
      
      // Cache the result
      final cachedData = await _readCache(_cacheFileName) ?? {};
      cachedData[cacheKey] = session.toJson();
      await _writeCache(_cacheFileName, cachedData);
      
      return session;
    } catch (e) {
      // If remote fails, try to return cached data even if expired
      final cached = await _getCacheFile(_cacheFileName);
      if (await cached.exists()) {
        try {
          final content = await cached.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          final cachedData = data['data'] as Map<String, dynamic>?;
          if (cachedData != null && cachedData.containsKey(cacheKey)) {
            return WorkoutSession.fromJson(cachedData[cacheKey]);
          }
        } catch (cacheError) {
          print('Error reading expired cache: $cacheError');
        }
      }
      rethrow;
    }
  }

  Future<WorkoutSession> updateWorkoutSession(WorkoutSession session) async {
    try {
      final updatedSession = await _remoteService.updateWorkoutSession(session);
      
      // Update cache
      final cacheKey = 'session_${session.sessionId}';
      final cached = await _readCache(_cacheFileName) ?? {};
      cached[cacheKey] = updatedSession.toJson();
      await _writeCache(_cacheFileName, cached);
      
      return updatedSession;
    } catch (e) {
      // Store for later sync when online
      await _storePendingOperation('update', session.toJson());
      
      // Update local cache optimistically
      final cacheKey = 'session_${session.sessionId}';
      final cached = await _readCache(_cacheFileName) ?? {};
      cached[cacheKey] = session.toJson();
      await _writeCache(_cacheFileName, cached);
      
      return session;
    }
  }

  Future<WorkoutSession> startWorkoutSession(String sessionId) async {
    try {
      return await _remoteService.startWorkoutSession(sessionId);
    } catch (e) {
      // For starting a session, we need to be online
      rethrow;
    }
  }

  Future<WorkoutSession> completeWorkoutSession(String sessionId) async {
    try {
      final completedSession = await _remoteService.completeWorkoutSession(sessionId);
      
      // Clear cache to ensure fresh stats
      await _clearCache(_cacheFileName);
      await _clearCache(_statsFileName);
      
      return completedSession;
    } catch (e) {
      // Store for later sync when online
      await _storePendingOperation('complete', {'sessionId': sessionId});
      rethrow;
    }
  }

  Future<WorkoutSession> updateSetData(
    String sessionId,
    String exerciseId,
    String setId,
    WorkoutSessionSet updatedSet,
  ) async {
    try {
      final updatedSession = await _remoteService.updateSetData(
        sessionId,
        exerciseId,
        setId,
        updatedSet,
      );
      
      // Update cache
      final cacheKey = 'session_$sessionId';
      final cached = await _readCache(_cacheFileName) ?? {};
      cached[cacheKey] = updatedSession.toJson();
      await _writeCache(_cacheFileName, cached);
      
      return updatedSession;
    } catch (e) {
      // For set updates during workout, try to continue offline
      final session = await getWorkoutSession(sessionId);
      final exerciseIndex = session.exercises.indexWhere(
        (ex) => ex.exerciseId == exerciseId,
      );
      
      if (exerciseIndex != -1) {
        final exercise = session.exercises[exerciseIndex];
        final setIndex = exercise.sets.indexWhere((set) => set.setId == setId);
        
        if (setIndex != -1) {
          final updatedSets = List<WorkoutSessionSet>.from(exercise.sets);
          updatedSets[setIndex] = updatedSet;
          
          final updatedExercise = exercise.copyWith(sets: updatedSets);
          final updatedExercises = List<WorkoutSessionExercise>.from(session.exercises);
          updatedExercises[exerciseIndex] = updatedExercise;
          
          final updatedSession = session.copyWith(
            exercises: updatedExercises,
            updatedAt: DateTime.now(),
          );
          
          // Store for later sync
          await _storePendingOperation('updateSet', {
            'sessionId': sessionId,
            'exerciseId': exerciseId,
            'setId': setId,
            'updatedSet': updatedSet.toJson(),
          });
          
          // Update local cache
          final cacheKey = 'session_$sessionId';
          final cached = await _readCache(_cacheFileName) ?? {};
          cached[cacheKey] = updatedSession.toJson();
          await _writeCache(_cacheFileName, cached);
          
          return updatedSession;
        }
      }
      
      rethrow;
    }
  }

  Future<WorkoutSessionStats> getWorkoutStats({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'stats_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}';
    
    if (!forceRefresh) {
      final cached = await _readCache(_statsFileName);
      if (cached != null && cached.containsKey(cacheKey)) {
        return WorkoutSessionStats.fromJson(cached[cacheKey]);
      }
    }

    try {
      final stats = await _remoteService.getWorkoutStats(
        startDate: startDate,
        endDate: endDate,
      );

      // Cache the result
      final cached = await _readCache(_statsFileName) ?? {};
      cached[cacheKey] = stats.toJson();
      await _writeCache(_statsFileName, cached);

      return stats;
    } catch (e) {
      // If remote fails, try to return cached data even if expired
      final cached = await _getCacheFile(_statsFileName);
      if (await cached.exists()) {
        try {
          final content = await cached.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          final cachedData = data['data'] as Map<String, dynamic>?;
          if (cachedData != null && cachedData.containsKey(cacheKey)) {
            return WorkoutSessionStats.fromJson(cachedData[cacheKey]);
          }
        } catch (cacheError) {
          print('Error reading expired stats cache: $cacheError');
        }
      }
      rethrow;
    }
  }

  Future<List<WorkoutSession>> getWorkoutHistory({
    int limit = 20,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    return getWorkoutSessions(
      limit: limit,
      offset: offset,
      status: WorkoutSessionStatus.completed,
      startDate: startDate,
      endDate: endDate,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> deleteWorkoutSession(String sessionId) async {
    try {
      await _remoteService.deleteWorkoutSession(sessionId);
      
      // Clear cache
      await _clearCache(_cacheFileName);
    } catch (e) {
      // Store for later sync when online
      await _storePendingOperation('delete', {'sessionId': sessionId});
      rethrow;
    }
  }

  Future<WorkoutSession?> getActiveWorkoutSession() async {
    try {
      return await _remoteService.getActiveWorkoutSession();
    } catch (e) {
      // Try to find active session in cache
      final cached = await _readCache(_cacheFileName);
      if (cached != null) {
        for (final entry in cached.entries) {
          if (entry.key.startsWith('session_')) {
            try {
              final session = WorkoutSession.fromJson(entry.value);
              if (session.status == WorkoutSessionStatus.inProgress) {
                return session;
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
      return null;
    }
  }

  // Pending operations management
  Future<void> _storePendingOperation(String type, Map<String, dynamic> data) async {
    try {
      final file = await _getCacheFile('pending_operations.json');
      List<Map<String, dynamic>> operations = [];
      
      if (await file.exists()) {
        final content = await file.readAsString();
        final existing = jsonDecode(content) as List;
        operations = existing.cast<Map<String, dynamic>>();
      }
      
      operations.add({
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await file.writeAsString(jsonEncode(operations));
    } catch (e) {
      print('Error storing pending operation: $e');
    }
  }

  Future<void> syncPendingOperations() async {
    try {
      final file = await _getCacheFile('pending_operations.json');
      if (!await file.exists()) return;
      
      final content = await file.readAsString();
      final operations = jsonDecode(content) as List;
      
      final List<Map<String, dynamic>> failedOperations = [];
      
      for (final operation in operations) {
        try {
          final type = operation['type'] as String;
          final data = operation['data'] as Map<String, dynamic>;
          
          switch (type) {
            case 'create':
              await _remoteService.createWorkoutSession(WorkoutSession.fromJson(data));
              break;
            case 'update':
              await _remoteService.updateWorkoutSession(WorkoutSession.fromJson(data));
              break;
            case 'complete':
              await _remoteService.completeWorkoutSession(data['sessionId']);
              break;
            case 'updateSet':
              await _remoteService.updateSetData(
                data['sessionId'],
                data['exerciseId'],
                data['setId'],
                WorkoutSessionSet.fromJson(data['updatedSet']),
              );
              break;
            case 'delete':
              await _remoteService.deleteWorkoutSession(data['sessionId']);
              break;
          }
        } catch (e) {
          // Keep failed operations for retry
          failedOperations.add(operation);
          print('Failed to sync operation: $e');
        }
      }
      
      // Update pending operations file with only failed operations
      if (failedOperations.isEmpty) {
        await file.delete();
      } else {
        await file.writeAsString(jsonEncode(failedOperations));
      }
      
      // Clear cache to ensure fresh data
      await _clearCache(_cacheFileName);
      await _clearCache(_statsFileName);
      
    } catch (e) {
      print('Error syncing pending operations: $e');
    }
  }

  Future<void> clearAllCache() async {
    await _clearCache(_cacheFileName);
    await _clearCache(_statsFileName);
    
    try {
      final file = await _getCacheFile('pending_operations.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing pending operations: $e');
    }
  }

  // Check if device is online and sync if needed
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> syncIfOnline() async {
    if (await isOnline()) {
      await syncPendingOperations();
    }
  }
}