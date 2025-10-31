import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/error_handler.dart';

/// Offline storage service using SQLite for local data persistence
///
/// Provides offline-first capabilities by storing workout data locally
/// and syncing with PocketBase when online.
class OfflineStorageService {
  static Database? _database;
  static const String _databaseName = 'periolifts_offline.db';
  static const int _databaseVersion = 1;

  /// Get the database instance (singleton)
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database
  static Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _upgradeTables,
      );
    } catch (e) {
      throw AppException(
        'Failed to initialize offline database',
        originalError: e,
      );
    }
  }

  /// Create database tables
  static Future<void> _createTables(Database db, int version) async {
    await db.transaction((txn) async {
      // Exercises table
      await txn.execute('''
        CREATE TABLE exercises (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          description TEXT,
          muscle_groups TEXT, -- JSON array
          image_url TEXT,
          video_url TEXT,
          is_custom INTEGER DEFAULT 0,
          user_id TEXT,
          created TEXT NOT NULL,
          updated TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0 -- 0: synced, 1: pending, 2: conflict
        )
      ''');

      // Workouts table
      await txn.execute('''
        CREATE TABLE workouts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          estimated_duration INTEGER,
          exercises TEXT NOT NULL, -- JSON array
          user_id TEXT NOT NULL,
          created TEXT NOT NULL,
          updated TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0
        )
      ''');

      // Workout sessions table
      await txn.execute('''
        CREATE TABLE workout_sessions (
          id TEXT PRIMARY KEY,
          workout_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT,
          status TEXT NOT NULL,
          exercises TEXT NOT NULL, -- JSON array
          notes TEXT,
          created TEXT NOT NULL,
          updated TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0
        )
      ''');

      // Workout plans table
      await txn.execute('''
        CREATE TABLE workout_plans (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          duration_weeks INTEGER NOT NULL,
          difficulty TEXT NOT NULL,
          tags TEXT, -- JSON array
          is_public INTEGER DEFAULT 0,
          user_id TEXT NOT NULL,
          workout_ids TEXT, -- JSON array
          created TEXT NOT NULL,
          updated TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0
        )
      ''');

      // Workout history table
      await txn.execute('''
        CREATE TABLE workout_history (
          id TEXT PRIMARY KEY,
          workout_session_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          completed_at TEXT NOT NULL,
          total_duration INTEGER NOT NULL,
          total_sets INTEGER NOT NULL,
          total_reps INTEGER NOT NULL,
          total_weight REAL,
          analytics TEXT, -- JSON object
          created TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0
        )
      ''');

      // Sync queue table for tracking pending operations
      await txn.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          record_id TEXT NOT NULL,
          operation TEXT NOT NULL, -- create, update, delete
          data TEXT, -- JSON data for create/update operations
          timestamp TEXT NOT NULL,
          retry_count INTEGER DEFAULT 0
        )
      ''');

      // Create indexes for better performance
      await txn.execute(
        'CREATE INDEX idx_exercises_user_id ON exercises(user_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_exercises_category ON exercises(category)',
      );
      await txn.execute(
        'CREATE INDEX idx_workouts_user_id ON workouts(user_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_workout_sessions_status ON workout_sessions(status)',
      );
      await txn.execute(
        'CREATE INDEX idx_workout_plans_user_id ON workout_plans(user_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_workout_history_user_id ON workout_history(user_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_sync_queue_table ON sync_queue(table_name)',
      );
    });
  }

  /// Handle database upgrades
  static Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database schema migrations here when needed
    // For now, we'll just drop and recreate (development only)
    if (oldVersion < newVersion) {
      // In production, implement proper migration logic
      await db.transaction((txn) async {
        await txn.execute('DROP TABLE IF EXISTS exercises');
        await txn.execute('DROP TABLE IF EXISTS workouts');
        await txn.execute('DROP TABLE IF EXISTS workout_sessions');
        await txn.execute('DROP TABLE IF EXISTS workout_plans');
        await txn.execute('DROP TABLE IF EXISTS workout_history');
        await txn.execute('DROP TABLE IF EXISTS sync_queue');
      });
      await _createTables(db, newVersion);
    }
  }

  /// Store a record in the offline database
  ///
  /// [tableName] The table to store the record in
  /// [record] The record data as a Map
  /// [syncStatus] The sync status (0: synced, 1: pending, 2: conflict)
  static Future<void> storeRecord(
    String tableName,
    Map<String, dynamic> record, {
    int syncStatus = 0,
  }) async {
    try {
      final db = await database;
      final recordWithSync = Map<String, dynamic>.from(record);
      recordWithSync['sync_status'] = syncStatus;

      // Convert JSON fields to strings
      _encodeJsonFields(tableName, recordWithSync);

      await db.insert(
        tableName,
        recordWithSync,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw AppException('Failed to store record offline', originalError: e);
    }
  }

  /// Retrieve records from the offline database
  ///
  /// [tableName] The table to query
  /// [where] Optional WHERE clause
  /// [whereArgs] Arguments for the WHERE clause
  /// [orderBy] Optional ORDER BY clause
  /// [limit] Optional LIMIT
  static Future<List<Map<String, dynamic>>> getRecords(
    String tableName, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    try {
      final db = await database;
      final records = await db.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );

      // Decode JSON fields
      return records.map((record) {
        final decoded = Map<String, dynamic>.from(record);
        _decodeJsonFields(tableName, decoded);
        return decoded;
      }).toList();
    } catch (e) {
      throw AppException(
        'Failed to retrieve records from offline storage',
        originalError: e,
      );
    }
  }

  /// Update a record in the offline database
  ///
  /// [tableName] The table to update
  /// [record] The updated record data
  /// [syncStatus] The sync status to set
  static Future<void> updateRecord(
    String tableName,
    Map<String, dynamic> record, {
    int syncStatus = 1, // Default to pending sync
  }) async {
    try {
      final db = await database;
      final recordWithSync = Map<String, dynamic>.from(record);
      recordWithSync['sync_status'] = syncStatus;

      _encodeJsonFields(tableName, recordWithSync);

      await db.update(
        tableName,
        recordWithSync,
        where: 'id = ?',
        whereArgs: [record['id']],
      );
    } catch (e) {
      throw AppException('Failed to update record offline', originalError: e);
    }
  }

  /// Delete a record from the offline database
  ///
  /// [tableName] The table to delete from
  /// [recordId] The ID of the record to delete
  static Future<void> deleteRecord(String tableName, String recordId) async {
    try {
      final db = await database;
      await db.delete(tableName, where: 'id = ?', whereArgs: [recordId]);
    } catch (e) {
      throw AppException('Failed to delete record offline', originalError: e);
    }
  }

  /// Add an operation to the sync queue
  ///
  /// [tableName] The table the operation affects
  /// [recordId] The ID of the record
  /// [operation] The operation type (create, update, delete)
  /// [data] Optional data for create/update operations
  static Future<void> addToSyncQueue(
    String tableName,
    String recordId,
    String operation, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final db = await database;
      await db.insert('sync_queue', {
        'table_name': tableName,
        'record_id': recordId,
        'operation': operation,
        'data': data != null ? jsonEncode(data) : null,
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    } catch (e) {
      throw AppException(
        'Failed to add operation to sync queue',
        originalError: e,
      );
    }
  }

  /// Get pending sync operations
  static Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    try {
      final db = await database;
      return await db.query('sync_queue', orderBy: 'timestamp ASC');
    } catch (e) {
      throw AppException(
        'Failed to get pending sync operations',
        originalError: e,
      );
    }
  }

  /// Remove a sync operation from the queue
  static Future<void> removeSyncOperation(int syncId) async {
    try {
      final db = await database;
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [syncId]);
    } catch (e) {
      throw AppException('Failed to remove sync operation', originalError: e);
    }
  }

  /// Clear all data from the database
  static Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('exercises');
        await txn.delete('workouts');
        await txn.delete('workout_sessions');
        await txn.delete('workout_plans');
        await txn.delete('workout_history');
        await txn.delete('sync_queue');
      });
    } catch (e) {
      throw AppException('Failed to clear offline data', originalError: e);
    }
  }

  /// Encode JSON fields as strings for SQLite storage
  static void _encodeJsonFields(String tableName, Map<String, dynamic> record) {
    switch (tableName) {
      case 'exercises':
        if (record['muscle_groups'] is List) {
          record['muscle_groups'] = jsonEncode(record['muscle_groups']);
        }
        break;
      case 'workouts':
        if (record['exercises'] is List) {
          record['exercises'] = jsonEncode(record['exercises']);
        }
        break;
      case 'workout_sessions':
        if (record['exercises'] is List) {
          record['exercises'] = jsonEncode(record['exercises']);
        }
        break;
      case 'workout_plans':
        if (record['tags'] is List) {
          record['tags'] = jsonEncode(record['tags']);
        }
        if (record['workout_ids'] is List) {
          record['workout_ids'] = jsonEncode(record['workout_ids']);
        }
        break;
      case 'workout_history':
        if (record['analytics'] is Map) {
          record['analytics'] = jsonEncode(record['analytics']);
        }
        break;
    }
  }

  /// Decode JSON fields from SQLite storage
  static void _decodeJsonFields(String tableName, Map<String, dynamic> record) {
    try {
      switch (tableName) {
        case 'exercises':
          if (record['muscle_groups'] is String &&
              record['muscle_groups'] != null) {
            record['muscle_groups'] = jsonDecode(
              record['muscle_groups'] as String,
            );
          }
          break;
        case 'workouts':
          if (record['exercises'] is String && record['exercises'] != null) {
            record['exercises'] = jsonDecode(record['exercises'] as String);
          }
          break;
        case 'workout_sessions':
          if (record['exercises'] is String && record['exercises'] != null) {
            record['exercises'] = jsonDecode(record['exercises'] as String);
          }
          break;
        case 'workout_plans':
          if (record['tags'] is String && record['tags'] != null) {
            record['tags'] = jsonDecode(record['tags'] as String);
          }
          if (record['workout_ids'] is String &&
              record['workout_ids'] != null) {
            record['workout_ids'] = jsonDecode(record['workout_ids'] as String);
          }
          break;
        case 'workout_history':
          if (record['analytics'] is String && record['analytics'] != null) {
            record['analytics'] = jsonDecode(record['analytics'] as String);
          }
          break;
      }
    } catch (e) {
      // If JSON decoding fails, leave the field as is
      // This prevents crashes from corrupted data
    }
  }

  /// Close the database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
