#!/usr/bin/env dart

// ignore_for_file: avoid_print, prefer_const_constructors

import 'dart:io';

import 'package:pocketbase/pocketbase.dart';

/// PocketBase Collection Initialization Script
///
/// This script creates missing collections in PocketBase based on the
/// application's data models. It should be run when setting up a new
/// PocketBase instance or when new collections are added.

// Configuration from environment variables
final pocketbaseHost = Platform.environment['POCKETBASE_HOST'] ?? 'localhost';
final pocketbasePort = Platform.environment['POCKETBASE_PORT'] ?? '8090';
final adminEmail = Platform.environment['POCKETBASE_ADMIN_EMAIL'] ?? 'admin@example.com';
final adminPassword = Platform.environment['POCKETBASE_ADMIN_PASSWORD'] ?? 'password';
final baseUrl = 'http://$pocketbaseHost:$pocketbasePort';

/// Collection schema definition
class CollectionSchema {
  final String name;
  final String type;
  final List<FieldSchema> schema;
  final String? listRule;
  final String? viewRule;
  final String? createRule;
  final String? updateRule;
  final String? deleteRule;

  const CollectionSchema({
    required this.name,
    required this.type,
    required this.schema,
    this.listRule,
    this.viewRule,
    this.createRule,
    this.updateRule,
    this.deleteRule,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'schema': schema.map((field) => field.toJson()).toList(),
      'listRule': listRule,
      'viewRule': viewRule,
      'createRule': createRule,
      'updateRule': updateRule,
      'deleteRule': deleteRule,
    };
  }
}

/// Field schema definition
class FieldSchema {
  final String name;
  final String type;
  final bool required;
  final Map<String, dynamic>? options;

  const FieldSchema({
    required this.name,
    required this.type,
    this.required = false,
    this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'required': required,
      if (options != null) 'options': options,
    };
  }
}

/// Collection definitions based on the Flutter models
final collections = <String, CollectionSchema>{
  'users': CollectionSchema(
    name: 'users',
    type: 'auth',
    schema: [
      FieldSchema(name: 'name', type: 'text', required: true),
      FieldSchema(name: 'username', type: 'text', required: true),
      FieldSchema(name: 'avatar_url', type: 'url'),
      FieldSchema(
        name: 'preferred_units',
        type: 'select',
        options: {'values': ['metric', 'imperial']},
      ),
      FieldSchema(
        name: 'preferred_theme',
        type: 'select',
        options: {'values': ['light', 'dark', 'system']},
      ),
      FieldSchema(name: 'timezone', type: 'text'),
      FieldSchema(name: 'onboarding_completed', type: 'bool'),
      FieldSchema(name: 'fitness_goals', type: 'json'),
      FieldSchema(name: 'current_cycle_phase', type: 'text'),
      FieldSchema(name: 'average_cycle_length', type: 'number'),
      FieldSchema(name: 'birth_date', type: 'date'),
      FieldSchema(name: 'height', type: 'number'),
      FieldSchema(name: 'weight', type: 'number'),
      FieldSchema(
        name: 'activity_level',
        type: 'select',
        options: {
          'values': [
            'sedentary',
            'lightly_active',
            'moderately_active',
            'very_active',
            'extremely_active'
          ]
        },
      ),
      FieldSchema(name: 'notifications_enabled', type: 'bool'),
      FieldSchema(name: 'workout_reminders_enabled', type: 'bool'),
      FieldSchema(name: 'period_reminders_enabled', type: 'bool'),
      FieldSchema(
        name: 'subscription_status',
        type: 'select',
        options: {'values': ['free', 'premium']},
      ),
      FieldSchema(name: 'subscription_expires_at', type: 'date'),
      FieldSchema(
        name: 'role',
        type: 'select',
        options: {'values': ['user', 'admin']},
      ),
      FieldSchema(name: 'is_active', type: 'bool'),
      FieldSchema(name: 'last_active_at', type: 'date'),
    ],
    listRule: 'id = @request.auth.id',
    viewRule: 'id = @request.auth.id',
    createRule: '',
    updateRule: 'id = @request.auth.id',
    deleteRule: 'id = @request.auth.id',
  ),

  'exercises': CollectionSchema(
    name: 'exercises',
    type: 'base',
    schema: [
      FieldSchema(name: 'name', type: 'text', required: true),
      FieldSchema(name: 'category', type: 'text', required: true),
      FieldSchema(name: 'description', type: 'text', required: true),
      FieldSchema(name: 'muscle_groups', type: 'json', required: true),
      FieldSchema(name: 'image_url', type: 'url'),
      FieldSchema(name: 'video_url', type: 'url'),
      FieldSchema(name: 'is_custom', type: 'bool', required: true),
      FieldSchema(
        name: 'user_id',
        type: 'relation',
        options: {'collectionId': 'users'},
      ),
    ],
    listRule: 'is_custom = false || user_id = @request.auth.id',
    viewRule: 'is_custom = false || user_id = @request.auth.id',
    createRule: '@request.auth.id != ""',
    updateRule: 'user_id = @request.auth.id',
    deleteRule: 'user_id = @request.auth.id',
  ),

  'workouts': CollectionSchema(
    name: 'workouts',
    type: 'base',
    schema: [
      FieldSchema(name: 'name', type: 'text', required: true),
      FieldSchema(name: 'description', type: 'text'),
      FieldSchema(name: 'estimated_duration', type: 'number'),
      FieldSchema(name: 'exercises', type: 'json', required: true),
      FieldSchema(
        name: 'user_id',
        type: 'relation',
        options: {'collectionId': 'users'},
        required: true,
      ),
      FieldSchema(name: 'scheduled_date', type: 'date'),
      FieldSchema(name: 'is_completed', type: 'bool'),
      FieldSchema(name: 'completed_date', type: 'date'),
      FieldSchema(name: 'is_in_progress', type: 'bool'),
      FieldSchema(name: 'progress', type: 'json'),
    ],
    listRule: 'user_id = @request.auth.id',
    viewRule: 'user_id = @request.auth.id',
    createRule: '@request.auth.id != ""',
    updateRule: 'user_id = @request.auth.id',
    deleteRule: 'user_id = @request.auth.id',
  ),

  'workout_plans': CollectionSchema(
    name: 'workout_plans',
    type: 'base',
    schema: [
      FieldSchema(name: 'name', type: 'text', required: true),
      FieldSchema(name: 'description', type: 'text', required: true),
      FieldSchema(name: 'start_date', type: 'date', required: true),
      FieldSchema(name: 'schedule', type: 'json', required: true),
      FieldSchema(name: 'is_active', type: 'bool'),
      FieldSchema(
        name: 'user_id',
        type: 'relation',
        options: {'collectionId': 'users'},
        required: true,
      ),
    ],
    listRule: 'user_id = @request.auth.id',
    viewRule: 'user_id = @request.auth.id',
    createRule: '@request.auth.id != ""',
    updateRule: 'user_id = @request.auth.id',
    deleteRule: 'user_id = @request.auth.id',
  ),

  'workout_sessions': CollectionSchema(
    name: 'workout_sessions',
    type: 'base',
    schema: [
      FieldSchema(
        name: 'workout_id',
        type: 'relation',
        options: {'collectionId': 'workouts'},
        required: true,
      ),
      FieldSchema(
        name: 'user_id',
        type: 'relation',
        options: {'collectionId': 'users'},
        required: true,
      ),
      FieldSchema(name: 'started_at', type: 'date', required: true),
      FieldSchema(name: 'completed_at', type: 'date'),
      FieldSchema(name: 'is_completed', type: 'bool'),
      FieldSchema(name: 'notes', type: 'text'),
      FieldSchema(name: 'exercise_data', type: 'json', required: true),
      FieldSchema(name: 'total_duration', type: 'number'),
      FieldSchema(name: 'calories_burned', type: 'number'),
    ],
    listRule: 'user_id = @request.auth.id',
    viewRule: 'user_id = @request.auth.id',
    createRule: '@request.auth.id != ""',
    updateRule: 'user_id = @request.auth.id',
    deleteRule: 'user_id = @request.auth.id',
  ),

  'workout_history': CollectionSchema(
    name: 'workout_history',
    type: 'base',
    schema: [
      FieldSchema(
        name: 'user_id',
        type: 'relation',
        options: {'collectionId': 'users'},
        required: true,
      ),
      FieldSchema(
        name: 'workout_session_id',
        type: 'relation',
        options: {'collectionId': 'workout_sessions'},
        required: true,
      ),
      FieldSchema(name: 'workout_name', type: 'text', required: true),
      FieldSchema(name: 'completed_at', type: 'date', required: true),
      FieldSchema(name: 'duration', type: 'number'),
      FieldSchema(name: 'exercises_completed', type: 'number'),
      FieldSchema(name: 'total_sets', type: 'number'),
      FieldSchema(name: 'total_reps', type: 'number'),
      FieldSchema(name: 'total_weight', type: 'number'),
      FieldSchema(name: 'notes', type: 'text'),
      FieldSchema(name: 'performance_data', type: 'json'),
    ],
    listRule: 'user_id = @request.auth.id',
    viewRule: 'user_id = @request.auth.id',
    createRule: '@request.auth.id != ""',
    updateRule: 'user_id = @request.auth.id',
    deleteRule: 'user_id = @request.auth.id',
  ),
};

/// PocketBase collection initializer
class PocketBaseInitializer {
  late final PocketBase pb;
  
  PocketBaseInitializer() {
    pb = PocketBase(baseUrl);
  }

  /// Wait for PocketBase to be ready
  Future<void> waitForPocketBase() async {
    print('🔍 Waiting for PocketBase to be ready...');
    
    const maxAttempts = 30;
    var attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        await pb.health.check();
        print('✅ PocketBase is ready!');
        return;
      } catch (e) {
        // Connection failed, continue waiting
      }
      
      attempts++;
      print('⏳ Attempt $attempts/$maxAttempts - PocketBase not ready yet...');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    
    throw Exception('❌ PocketBase failed to start within expected time');
  }

  /// Authenticate as admin
  Future<bool> authenticate() async {
    print('🔐 Authenticating as admin...');
    
    try {
      await pb.collection('_superusers').authWithPassword(adminEmail, adminPassword);
      print('✅ Admin authentication successful');
      return true;
    } catch (e) {
      print('❌ Admin authentication failed: $e');
      return false;
    }
  }

  /// Get existing collections
  Future<List<CollectionModel>> getExistingCollections() async {
    try {
      final result = await pb.collections.getFullList();
      return result;
    } catch (e) {
      print('❌ Error fetching collections: $e');
      return [];
    }
  }

  /// Create a collection
  Future<bool> createCollection(CollectionSchema collectionConfig) async {
    try {
      print('📄 Creating collection: ${collectionConfig.name}');
      
      await pb.collections.create(body: collectionConfig.toJson());
      
      print('✅ Collection \'${collectionConfig.name}\' created successfully');
      return true;
    } catch (e) {
      print('❌ Failed to create collection \'${collectionConfig.name}\': $e');
      return false;
    }
  }

  /// Initialize all collections
  Future<({int created, int skipped})> initializeCollections() async {
    print('🚀 Starting collection initialization...');

    // Wait for PocketBase to be ready
    await waitForPocketBase();

    // Authenticate as admin
    final authSuccess = await authenticate();
    if (!authSuccess) {
      throw Exception('Failed to authenticate with PocketBase admin');
    }

    // Get existing collections
    final existingCollections = await getExistingCollections();
    final existingNames = existingCollections.map((col) => col.name).toSet();

    print('📋 Existing collections: $existingNames');

    // Create missing collections
    var created = 0;
    var skipped = 0;

    for (final entry in collections.entries) {
      final collectionName = entry.key;
      final collectionConfig = entry.value;

      if (existingNames.contains(collectionName)) {
        print('⏭️  Collection \'$collectionName\' already exists, skipping');
        skipped++;
      } else {
        final success = await createCollection(collectionConfig);
        if (success) {
          created++;
        }
        // Small delay between requests
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    print('🎉 Collection initialization complete!');
    print('📊 Summary: $created created, $skipped skipped');
    
    return (created: created, skipped: skipped);
  }
}

/// Main execution function
Future<void> main(List<String> args) async {
  try {
    print('🚀 PocketBase Collection Initialization Script');
    print('==============================================');
    print('📋 Configuration:');
    print('  - Host: $pocketbaseHost');
    print('  - Port: $pocketbasePort');
    print('  - Admin Email: $adminEmail');
    print('  - Base URL: $baseUrl');
    print('');

    final initializer = PocketBaseInitializer();
    await initializer.initializeCollections();
    
    print('');
    print('✅ Initialization completed successfully!');
    exit(0);
  } catch (error) {
    print('');
    print('💥 Initialization failed: $error');
    exit(1);
  }
}