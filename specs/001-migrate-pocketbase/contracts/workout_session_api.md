# Workout Session API Contract

**Collection**: `workout_sessions`  
**Purpose**: Real-time workout tracking and session management

## Collection Schema

```json
{
  "id": "TEXT PRIMARY KEY",
  "workout_id": "TEXT NOT NULL",
  "user_id": "TEXT NOT NULL", 
  "start_time": "DATETIME NOT NULL",
  "end_time": "DATETIME",
  "status": "TEXT CHECK(status IN ('planned', 'active', 'completed', 'cancelled'))",
  "exercises": "JSON NOT NULL DEFAULT '[]'",
  "notes": "TEXT",
  "created": "DATETIME DEFAULT CURRENT_TIMESTAMP",
  "updated": "DATETIME DEFAULT CURRENT_TIMESTAMP"
}
```

## REST API Endpoints

### GET /api/collections/workout_sessions/records

**Description**: List workout sessions with filtering and pagination

**Query Parameters**:

- `page`: Page number (default: 1)
- `perPage`: Records per page (default: 30, max: 500)  
- `filter`: Filter expression (e.g., `status = "active"`)
- `sort`: Sort expression (e.g., `-start_time`)

**Example Request**:

```
GET /api/collections/workout_sessions/records?filter=user_id="USER_ID"&sort=-start_time&page=1&perPage=20
```

**Success Response (200)**:

```json
{
  "page": 1,
  "perPage": 20,
  "totalItems": 45,
  "totalPages": 3,
  "items": [
    {
      "id": "RECORD_ID",
      "workout_id": "WORKOUT_ID",
      "user_id": "USER_ID",
      "start_time": "2025-01-01 10:00:00.123Z",
      "end_time": "2025-01-01 11:30:00.123Z",
      "status": "completed",
      "exercises": [
        {
          "exerciseId": "EXERCISE_ID",
          "sets": [
            {
              "reps": 10,
              "weight": 50.0,
              "completed": true,
              "completedAt": "2025-01-01 10:15:00.123Z",
              "notes": "Felt good"
            }
          ],
          "notes": "Great form today"
        }
      ],
      "notes": "Excellent workout session",
      "created": "2025-01-01 10:00:00.123Z",
      "updated": "2025-01-01 11:30:00.123Z"
    }
  ]
}
```

### POST /api/collections/workout_sessions/records

**Description**: Create new workout session

**Request Body**:

```json
{
  "workout_id": "WORKOUT_ID",
  "user_id": "USER_ID",
  "start_time": "2025-01-01 10:00:00.123Z",
  "status": "active",
  "exercises": [
    {
      "exerciseId": "EXERCISE_ID",
      "sets": [
        {
          "reps": 10,
          "weight": 50.0,
          "completed": false,
          "notes": ""
        },
        {
          "reps": 10,
          "weight": 50.0,
          "completed": false,
          "notes": ""
        }
      ],
      "notes": ""
    }
  ]
}
```

**Success Response (200)**:

```json
{
  "id": "RECORD_ID",
  "workout_id": "WORKOUT_ID",
  "user_id": "USER_ID",
  "start_time": "2025-01-01 10:00:00.123Z",
  "end_time": "",
  "status": "active",
  "exercises": [
    {
      "exerciseId": "EXERCISE_ID",
      "sets": [
        {
          "reps": 10,
          "weight": 50.0,
          "completed": false,
          "completedAt": null,
          "notes": ""
        }
      ],
      "notes": ""
    }
  ],
  "notes": "",
  "created": "2025-01-01 10:00:00.123Z",
  "updated": "2025-01-01 10:00:00.123Z"
}
```

### PATCH /api/collections/workout_sessions/records/{id}

**Description**: Update workout session progress (real-time updates)

**Request Body**:

```json
{
  "exercises": [
    {
      "exerciseId": "EXERCISE_ID",
      "sets": [
        {
          "reps": 12,
          "weight": 52.5,
          "completed": true,
          "completedAt": "2025-01-01 10:15:00.123Z",
          "notes": "Increased weight slightly"
        }
      ],
      "notes": "Form was excellent"
    }
  ],
  "status": "active"
}
```

**Success Response (200)**:

```json
{
  "id": "RECORD_ID",
  "workout_id": "WORKOUT_ID", 
  "user_id": "USER_ID",
  "start_time": "2025-01-01 10:00:00.123Z",
  "end_time": "",
  "status": "active",
  "exercises": [
    {
      "exerciseId": "EXERCISE_ID",
      "sets": [
        {
          "reps": 12,
          "weight": 52.5,
          "completed": true,
          "completedAt": "2025-01-01 10:15:00.123Z",
          "notes": "Increased weight slightly"
        }
      ],
      "notes": "Form was excellent"
    }
  ],
  "notes": "",
  "created": "2025-01-01 10:00:00.123Z",
  "updated": "2025-01-01 10:15:30.456Z"
}
```

## Real-time Subscriptions

### Subscribe to User's Active Sessions

**WebSocket Connection**: `ws://localhost:8090/api/realtime`

**Subscription Message**:

```json
{
  "clientId": "CLIENT_ID",
  "command": "subscribe",
  "data": {
    "topic": "workout_sessions",
    "filter": "user_id = 'USER_ID' && status = 'active'"
  }
}
```

**Real-time Update Event**:

```json
{
  "action": "update",
  "topic": "workout_sessions",
  "record": {
    "id": "RECORD_ID",
    "workout_id": "WORKOUT_ID",
    "user_id": "USER_ID",
    "start_time": "2025-01-01 10:00:00.123Z",
    "end_time": "",
    "status": "active",
    "exercises": [
      {
        "exerciseId": "EXERCISE_ID",
        "sets": [
          {
            "reps": 12,
            "weight": 52.5,
            "completed": true,
            "completedAt": "2025-01-01 10:15:00.123Z",
            "notes": "Great set!"
          }
        ],
        "notes": ""
      }
    ],
    "notes": "",
    "created": "2025-01-01 10:00:00.123Z",
    "updated": "2025-01-01 10:15:30.456Z"
  }
}
```

## Dart Client Usage

```dart
// Create new session
final session = await pb.collection('workout_sessions').create(body: {
  'workout_id': workoutId,
  'user_id': pb.authStore.model?.id,
  'start_time': DateTime.now().toIso8601String(),
  'status': 'active',
  'exercises': exercisesJson,
});

// Update session progress
final updatedSession = await pb.collection('workout_sessions').update(sessionId, body: {
  'exercises': updatedExercisesJson,
  'status': 'active',
});

// Subscribe to real-time updates
pb.collection('workout_sessions').subscribe('*', (e) {
  if (e.action == 'update' && e.record != null) {
    final session = WorkoutSession.fromJson(e.record!.toJson());
    // Handle session update
  }
}, filter: 'user_id = "${pb.authStore.model?.id}" && status = "active"');

// Complete session
final completedSession = await pb.collection('workout_sessions').update(sessionId, body: {
  'status': 'completed',
  'end_time': DateTime.now().toIso8601String(),
});
```

## Performance Considerations

- **Real-time Updates**: Use WebSocket subscriptions for live workout tracking
- **Pagination**: Limit session lists to 20-50 items per page for optimal performance
- **Filtering**: Always filter by `user_id` to ensure user isolation
- **Indexing**: Leverage database indexes on `user_id`, `status`, and `start_time` fields
- **JSON Validation**: Validate exercise JSON structure on client side before sending
