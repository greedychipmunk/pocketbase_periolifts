# Quickstart Guide: PocketBase Migration Implementation

**Feature**: Backend Migration from Appwrite to PocketBase  
**Created**: 2025-10-29  
**Purpose**: Step-by-step implementation guide for developers working on the PocketBase migration

## Prerequisites

### Development Environment Setup

1. **Flutter SDK**: Ensure Flutter 3.9.2+ is installed
2. **PocketBase Server**: Download and run PocketBase locally for development
3. **Dependencies**: Add PocketBase Dart SDK to `pubspec.yaml`

```yaml
dependencies:
  pocketbase: ^0.18.0
  flutter_riverpod: ^2.4.9
  provider: ^6.1.1
  uuid: ^4.2.1
  intl: ^0.19.0
  sqflite: ^2.3.0  # For offline storage
```

### PocketBase Server Setup

```bash
# Download PocketBase for your platform
wget https://github.com/pocketbase/pocketbase/releases/download/v0.20.0/pocketbase_0.20.0_darwin_amd64.zip

# Extract and run
unzip pocketbase_0.20.0_darwin_amd64.zip
./pocketbase serve

# Access admin panel at http://127.0.0.1:8090/_/
# Create admin account and configure collections
```

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1)

#### Step 1: Add PocketBase Configuration

Create `lib/config/pocketbase_config.dart`:

```dart
import 'package:pocketbase/pocketbase.dart';

class PocketBaseConfig {
  static const String baseUrl = 'http://127.0.0.1:8090';
  static const String baseUrlProd = 'https://your-pocketbase-instance.com';
  
  static PocketBase? _instance;
  
  static PocketBase get instance {
    _instance ??= PocketBase(
      kDebugMode ? baseUrl : baseUrlProd,
    );
    return _instance!;
  }
}
```

#### Step 2: Create Base Service Class

Create `lib/services/base_pocketbase_service.dart`:

```dart
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';

abstract class BasePocketBaseService {
  final PocketBase pb = PocketBaseConfig.instance;
  
  // Common error handling
  String handleError(dynamic error) {
    if (error is ClientException) {
      return error.response['message'] ?? 'Unknown error occurred';
    }
    return error.toString();
  }
  
  // Common pagination parameters
  Map<String, dynamic> getPaginationParams({
    int page = 1,
    int perPage = 20,
    String? filter,
    String? sort,
  }) {
    return {
      'page': page,
      'perPage': perPage,
      if (filter != null) 'filter': filter,
      if (sort != null) 'sort': sort,
    };
  }
}
```

#### Step 3: Implement Authentication Service

Create `lib/services/auth_service.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_pocketbase_service.dart';

class AuthService extends BasePocketBaseService {
  // Sign in with email/password
  Future<bool> signIn(String email, String password) async {
    try {
      await pb.collection('users').authWithPassword(email, password);
      return true;
    } catch (e) {
      throw handleError(e);
    }
  }
  
  // Sign up new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await pb.collection('users').create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
      });
      
      // Auto sign in after registration
      return await signIn(email, password);
    } catch (e) {
      throw handleError(e);
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    pb.authStore.clear();
  }
  
  // Check if user is authenticated
  bool get isAuthenticated => pb.authStore.isValid;
  
  // Get current user
  String? get currentUserId => pb.authStore.model?.id;
}

// Provider for dependency injection
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
```

### Phase 2: Data Services Migration (Week 2)

#### Step 4: Exercise Service Implementation

Create `lib/services/exercise_service.dart`:

```dart
import '../models/exercise.dart';
import 'base_pocketbase_service.dart';

class ExerciseService extends BasePocketBaseService {
  static const String collection = 'exercises';
  
  // Get all exercises (built-in + user custom)
  Future<List<Exercise>> getExercises({
    String? category,
    bool? isCustom,
    int page = 1,
  }) async {
    try {
      List<String> filters = [];
      
      if (category != null) {
        filters.add('category = "$category"');
      }
      
      if (isCustom != null) {
        if (isCustom) {
          filters.add('user_id = "${pb.authStore.model?.id}"');
        } else {
          filters.add('user_id = null');
        }
      }
      
      final response = await pb.collection(collection).getList(
        page: page,
        perPage: 50,
        filter: filters.isEmpty ? null : filters.join(' && '),
        sort: 'name',
      );
      
      return response.items.map((item) => Exercise.fromJson(item.toJson())).toList();
    } catch (e) {
      throw handleError(e);
    }
  }
  
  // Create custom exercise
  Future<Exercise> createExercise(Exercise exercise) async {
    try {
      final response = await pb.collection(collection).create(body: {
        ...exercise.toJson(),
        'user_id': pb.authStore.model?.id,
        'is_custom': true,
      });
      
      return Exercise.fromJson(response.toJson());
    } catch (e) {
      throw handleError(e);
    }
  }
  
  // Update exercise (only custom exercises)
  Future<Exercise> updateExercise(Exercise exercise) async {
    try {
      final response = await pb.collection(collection).update(
        exercise.id,
        body: exercise.toJson(),
      );
      
      return Exercise.fromJson(response.toJson());
    } catch (e) {
      throw handleError(e);
    }
  }
  
  // Delete custom exercise
  Future<void> deleteExercise(String exerciseId) async {
    try {
      await pb.collection(collection).delete(exerciseId);
    } catch (e) {
      throw handleError(e);
    }
  }
}
```

#### Step 5: Workout Session Service with Real-time

Create `lib/services/workout_session_service.dart`:

```dart
import 'dart:async';
import '../models/workout_session.dart';
import 'base_pocketbase_service.dart';

class WorkoutSessionService extends BasePocketBaseService {
  static const String collection = 'workout_sessions';
  StreamSubscription? _activeSessionSubscription;
  
  // Start a new workout session
  Future<WorkoutSession> startSession({
    required String workoutId,
    required List<SessionExercise> exercises,
  }) async {
    try {
      final response = await pb.collection(collection).create(body: {
        'workout_id': workoutId,
        'user_id': pb.authStore.model?.id,
        'start_time': DateTime.now().toIso8601String(),
        'status': 'active',
        'exercises': exercises.map((e) => e.toJson()).toList(),
      });
      
      return WorkoutSession.fromJson(response.toJson());
    } catch (e) {
      throw handleError(e);
    }
  }
  
  // Update session progress (real-time)
  Future<WorkoutSession> updateSession(WorkoutSession session) async {
    try {
      final response = await pb.collection(collection).update(
        session.id,
        body: {
          'exercises': session.exercises.map((e) => e.toJson()).toList(),
          'status': session.status.name,
          if (session.endTime != null) 'end_time': session.endTime!.toIso8601String(),
          if (session.notes != null) 'notes': session.notes,
        },
      );
      
      return WorkoutSession.fromJson(response.toJson());
    } catch (e) {
      throw handleError(e);
    }
  }
  
  // Subscribe to active session updates
  Stream<WorkoutSession> subscribeToActiveSession() {
    final controller = StreamController<WorkoutSession>();
    
    _activeSessionSubscription = pb.collection(collection).subscribe(
      '*',
      (e) {
        if (e.action == 'update' && e.record != null) {
          final session = WorkoutSession.fromJson(e.record!.toJson());
          if (session.userId == pb.authStore.model?.id && session.status == SessionStatus.active) {
            controller.add(session);
          }
        }
      },
      filter: 'user_id = "${pb.authStore.model?.id}" && status = "active"',
    );
    
    return controller.stream;
  }
  
  // Complete workout session
  Future<WorkoutSession> completeSession(String sessionId) async {
    try {
      final response = await pb.collection(collection).update(sessionId, body: {
        'status': 'completed',
        'end_time': DateTime.now().toIso8601String(),
      });
      
      return WorkoutSession.fromJson(response.toJson());
    } catch (e) {
      throw handleError(e);
    }
  }
  
  // Cleanup subscriptions
  void dispose() {
    _activeSessionSubscription?.cancel();
  }
}
```

### Phase 3: UI Integration (Week 3)

#### Step 6: Update Providers for PocketBase

Update `lib/providers/workout_session_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/workout_session_service.dart';
import '../models/workout_session.dart';

// Service provider
final workoutSessionServiceProvider = Provider<WorkoutSessionService>((ref) {
  return WorkoutSessionService();
});

// Active session provider with real-time updates
final activeSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  final service = ref.read(workoutSessionServiceProvider);
  return service.subscribeToActiveSession();
});

// Start session provider
final startSessionProvider = FutureProvider.family<WorkoutSession, StartSessionParams>((ref, params) {
  final service = ref.read(workoutSessionServiceProvider);
  return service.startSession(
    workoutId: params.workoutId,
    exercises: params.exercises,
  );
});

class StartSessionParams {
  final String workoutId;
  final List<SessionExercise> exercises;
  
  StartSessionParams({required this.workoutId, required this.exercises});
}
```

#### Step 7: Update UI Screens

Update existing screens to use PocketBase providers:

```dart
// Example: Update workout tracking screen
class WorkoutTrackingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionAsync = ref.watch(activeSessionProvider);
    
    return activeSessionAsync.when(
      data: (session) {
        if (session == null) {
          return StartWorkoutView();
        }
        return ActiveWorkoutView(session: session);
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorView(error: error.toString()),
    );
  }
}
```

## Testing Strategy

### Unit Tests for Services

Create `test/services/auth_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../../lib/services/auth_service.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    
    setUp(() {
      authService = AuthService();
    });
    
    test('should sign in with valid credentials', () async {
      // Test implementation
      final result = await authService.signIn('test@example.com', 'password');
      expect(result, isTrue);
    });
    
    test('should throw error with invalid credentials', () async {
      // Test implementation
      expect(
        () => authService.signIn('invalid@example.com', 'wrong'),
        throwsA(isA<String>()),
      );
    });
  });
}
```

### Integration Tests

Create `test/integration/migration_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocketbase_periolifts/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('PocketBase Migration Integration', () {
    testWidgets('should complete full workout flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Test login flow
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'password');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();
      
      // Test workout creation and execution
      // ... additional test steps
    });
  });
}
```

## Deployment Checklist

### Pre-deployment Validation

- [ ] All unit tests passing (90%+ coverage)
- [ ] Integration tests covering core workflows
- [ ] Performance benchmarks meet constitutional requirements
- [ ] Data migration script validated with test data
- [ ] PocketBase server properly configured and secured

### Production Migration

- [ ] Set up production PocketBase instance
- [ ] Configure SSL/TLS certificates
- [ ] Run data migration script
- [ ] Update app configuration for production URLs
- [ ] Deploy app update to app stores
- [ ] Monitor error rates and performance metrics

### Rollback Plan

- [ ] Keep Appwrite instance running for 30 days post-migration
- [ ] Document rollback procedure if critical issues arise
- [ ] Monitor user feedback and crash reports
- [ ] Plan gradual migration if needed (feature flags)
