# Data Model Design: PocketBase Migration

**Feature**: Backend Migration from Appwrite to PocketBase  
**Created**: 2025-10-29  
**Purpose**: Define PocketBase collection schemas and migration mapping from existing Appwrite data model

## Current Appwrite Data Model Analysis

### User Collection (Authentication)
```dart
// Current Appwrite User structure
{
  "\$id": String,           // Unique user identifier
  "email": String,          // User email for authentication
  "name": String,           // Display name
  "\$createdAt": DateTime,  // Account creation timestamp
  "\$updatedAt": DateTime   // Last modification timestamp
}
```

### Exercise Collection
```dart
// Current model: lib/models/exercise.dart
class Exercise {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> muscleGroups;
  final String? imageUrl;
  final String? videoUrl;
  final bool isCustom;
  final String userId;      // References user who created custom exercise
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### WorkoutPlan Collection
```dart
// Current model: lib/models/workout_plan.dart
class WorkoutPlan {
  final String id;
  final String name;
  final String description;
  final int durationWeeks;
  final String difficulty;  // Beginner, Intermediate, Advanced
  final List<String> tags;
  final bool isPublic;
  final String userId;      // Plan creator
  final List<String> workoutIds; // References to Workout documents
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Workout Collection
```dart
// Current model: lib/models/workout.dart
class Workout {
  final String id;
  final String name;
  final String? description;
  final int estimatedDuration; // Minutes
  final List<WorkoutExercise> exercises;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class WorkoutExercise {
  final String exerciseId;   // References Exercise document
  final int sets;
  final int reps;
  final double? weight;      // Optional weight in user's preferred unit
  final int? restTime;       // Rest time in seconds
  final String? notes;
}
```

### WorkoutSession Collection
```dart
// Current model: lib/models/workout_session.dart
class WorkoutSession {
  final String id;
  final String workoutId;    // References Workout document
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionStatus status; // planned, active, completed, cancelled
  final List<SessionExercise> exercises;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class SessionExercise {
  final String exerciseId;   // References Exercise document
  final List<ExerciseSet> sets;
  final String? notes;
}

class ExerciseSet {
  final int reps;
  final double? weight;
  final bool completed;
  final DateTime? completedAt;
  final String? notes;
}
```

### WorkoutHistory Collection
```dart
// Current model: lib/models/workout_history.dart
class WorkoutHistory {
  final String id;
  final String workoutSessionId; // References WorkoutSession document
  final String userId;
  final DateTime completedAt;
  final int totalDuration;   // Actual duration in minutes
  final int totalSets;
  final int totalReps;
  final double? totalWeight;
  final Map<String, dynamic> analytics; // Performance metrics
  final DateTime createdAt;
}
```

## PocketBase Schema Design

### Collection: users (Built-in Authentication)
```sql
-- PocketBase auto-generates this collection
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  username TEXT,
  name TEXT,
  avatar TEXT,
  created DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Migration Notes**:
- Use PocketBase built-in users collection
- Map Appwrite `name` to PocketBase `name` field
- PocketBase handles password hashing and session management automatically

### Collection: exercises
```sql
CREATE TABLE exercises (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  muscle_groups JSON DEFAULT '[]',
  image_url TEXT,
  video_url TEXT,
  is_custom BOOLEAN DEFAULT false,
  user_id TEXT,
  created DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_exercises_category ON exercises(category);
CREATE INDEX idx_exercises_user_id ON exercises(user_id);
CREATE INDEX idx_exercises_is_custom ON exercises(is_custom);
```

**Migration Notes**:
- `muscle_groups` stored as JSON array for flexibility
- Custom exercises linked to user, built-in exercises have `user_id` NULL
- Indexes on frequently queried fields for performance

### Collection: workout_plans
```sql
CREATE TABLE workout_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  duration_weeks INTEGER NOT NULL,
  difficulty TEXT CHECK(difficulty IN ('Beginner', 'Intermediate', 'Advanced')),
  tags JSON DEFAULT '[]',
  is_public BOOLEAN DEFAULT false,
  user_id TEXT NOT NULL,
  workout_ids JSON DEFAULT '[]',
  created DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_workout_plans_user_id ON workout_plans(user_id);
CREATE INDEX idx_workout_plans_is_public ON workout_plans(is_public);
CREATE INDEX idx_workout_plans_difficulty ON workout_plans(difficulty);
```

**Migration Notes**:
- `tags` and `workout_ids` stored as JSON arrays
- Difficulty constraint ensures data integrity
- Public plans can be discovered by other users

### Collection: workouts
```sql
CREATE TABLE workouts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  estimated_duration INTEGER, -- Minutes
  exercises JSON NOT NULL DEFAULT '[]',
  user_id TEXT NOT NULL,
  created DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_workouts_user_id ON workouts(user_id);
```

**Migration Notes**:
- `exercises` stored as JSON array of WorkoutExercise objects
- Denormalized structure for better performance during workout execution
- JSON structure: `[{"exerciseId": "...", "sets": 3, "reps": 10, "weight": 50.0, "restTime": 60, "notes": "..."}]`

### Collection: workout_sessions
```sql
CREATE TABLE workout_sessions (
  id TEXT PRIMARY KEY,
  workout_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME,
  status TEXT CHECK(status IN ('planned', 'active', 'completed', 'cancelled')) DEFAULT 'planned',
  exercises JSON NOT NULL DEFAULT '[]',
  notes TEXT,
  created DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_status ON workout_sessions(status);
CREATE INDEX idx_workout_sessions_start_time ON workout_sessions(start_time);
```

**Migration Notes**:
- `exercises` stored as JSON array of SessionExercise objects with nested sets
- Status constraint prevents invalid session states
- Optimized for querying active sessions and workout history

### Collection: workout_history
```sql
CREATE TABLE workout_history (
  id TEXT PRIMARY KEY,
  workout_session_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  completed_at DATETIME NOT NULL,
  total_duration INTEGER NOT NULL, -- Minutes
  total_sets INTEGER NOT NULL,
  total_reps INTEGER NOT NULL,
  total_weight REAL,
  analytics JSON DEFAULT '{}',
  created DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (workout_session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_workout_history_user_id ON workout_history(user_id);
CREATE INDEX idx_workout_history_completed_at ON workout_history(completed_at);
```

**Migration Notes**:
- One history record per completed workout session
- `analytics` JSON field stores performance metrics and trends
- Optimized for progress tracking and analytics queries

## Dart Model Updates Required

### Base Model Changes
```dart
// Add PocketBase-specific fields to all models
abstract class PocketBaseModel {
  final String id;
  final DateTime created;
  final DateTime updated;
  
  const PocketBaseModel({
    required this.id,
    required this.created,
    required this.updated,
  });
}
```

### Exercise Model Updates
```dart
class Exercise extends PocketBaseModel {
  // ... existing fields ...
  
  // Updated JSON serialization for PocketBase
  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'description': description,
    'muscle_groups': muscleGroups,  // PocketBase field naming
    'image_url': imageUrl,
    'video_url': videoUrl,
    'is_custom': isCustom,
    'user_id': userId,
  };
  
  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    description: json['description'],
    muscleGroups: List<String>.from(json['muscle_groups'] ?? []),
    imageUrl: json['image_url'],
    videoUrl: json['video_url'],
    isCustom: json['is_custom'] ?? false,
    userId: json['user_id'],
    created: DateTime.parse(json['created']),
    updated: DateTime.parse(json['updated']),
  );
}
```

## Migration Strategy

### Data Migration Process
1. **Export Appwrite Data**: Use Appwrite CLI to export all collections to JSON
2. **Transform Data**: Convert field names and structure to match PocketBase schema
3. **Import to PocketBase**: Use PocketBase admin API to bulk import data
4. **Validate Migration**: Compare record counts and sample data integrity

### Field Mapping Table
| Appwrite Field | PocketBase Field | Transformation |
|---------------|------------------|----------------|
| `$id` | `id` | Direct mapping |
| `$createdAt` | `created` | Direct mapping |
| `$updatedAt` | `updated` | Direct mapping |
| `muscleGroups` | `muscle_groups` | Snake case conversion |
| `imageUrl` | `image_url` | Snake case conversion |
| `videoUrl` | `video_url` | Snake case conversion |
| `isCustom` | `is_custom` | Snake case conversion |
| `isPublic` | `is_public` | Snake case conversion |
| `userId` | `user_id` | Snake case conversion |

### Real-time Subscription Mapping
| Current Appwrite | PocketBase Equivalent |
|------------------|----------------------|
| `subscribe('exercises')` | `pb.collection('exercises').subscribe('*')` |
| `subscribe('workout_sessions')` | `pb.collection('workout_sessions').subscribe('*')` |
| User-specific filtering | `pb.collection('workouts').subscribe('*', {'filter': 'user_id = "USER_ID"'})` |