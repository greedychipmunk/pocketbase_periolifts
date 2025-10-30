# Exercise API Contract

**Collection**: `exercises`  
**Purpose**: Exercise database with built-in and custom user exercises

## Collection Schema

```json
{
  "id": "TEXT PRIMARY KEY",
  "name": "TEXT NOT NULL",
  "category": "TEXT NOT NULL",
  "description": "TEXT",
  "muscle_groups": "JSON DEFAULT '[]'",
  "image_url": "TEXT",
  "video_url": "TEXT", 
  "is_custom": "BOOLEAN DEFAULT false",
  "user_id": "TEXT",
  "created": "DATETIME DEFAULT CURRENT_TIMESTAMP",
  "updated": "DATETIME DEFAULT CURRENT_TIMESTAMP"
}
```

## REST API Endpoints

### GET /api/collections/exercises/records

**Description**: List exercises with filtering and search

**Query Parameters**:

- `page`: Page number (default: 1)
- `perPage`: Records per page (default: 30, max: 100)
- `filter`: Filter expression
- `sort`: Sort expression (default: `name`)
- `search`: Full-text search in name and description

**Common Filters**:

- Built-in exercises: `is_custom = false`
- User custom exercises: `user_id = "USER_ID"`
- Category filter: `category = "strength"`
- Muscle group filter: `muscle_groups ~ "chest"`

**Example Request**:

```http
GET /api/collections/exercises/records?filter=category="strength"&sort=name&page=1&perPage=50
```

**Success Response (200)**:

```json
{
  "page": 1,
  "perPage": 50,
  "totalItems": 150,
  "totalPages": 3,
  "items": [
    {
      "id": "RECORD_ID",
      "name": "Bench Press",
      "category": "strength",
      "description": "Compound chest exercise performed lying on a bench",
      "muscle_groups": ["chest", "triceps", "shoulders"],
      "image_url": "https://example.com/bench-press.jpg",
      "video_url": "https://example.com/bench-press-demo.mp4",
      "is_custom": false,
      "user_id": "",
      "created": "2025-01-01 00:00:00.000Z",
      "updated": "2025-01-01 00:00:00.000Z"
    },
    {
      "id": "CUSTOM_RECORD_ID",
      "name": "My Custom Exercise",
      "category": "strength",
      "description": "Personal variation of traditional movement",
      "muscle_groups": ["chest", "core"],
      "image_url": "",
      "video_url": "",
      "is_custom": true,
      "user_id": "USER_ID",
      "created": "2025-01-01 10:00:00.123Z",
      "updated": "2025-01-01 10:00:00.123Z"
    }
  ]
}
```

### GET /api/collections/exercises/records/{id}

**Description**: Get single exercise by ID

**Success Response (200)**:

```json
{
  "id": "RECORD_ID",
  "name": "Bench Press",
  "category": "strength",
  "description": "Compound chest exercise performed lying on a bench",
  "muscle_groups": ["chest", "triceps", "shoulders"],
  "image_url": "https://example.com/bench-press.jpg",
  "video_url": "https://example.com/bench-press-demo.mp4",
  "is_custom": false,
  "user_id": "",
  "created": "2025-01-01 00:00:00.000Z",
  "updated": "2025-01-01 00:00:00.000Z"
}
```

### POST /api/collections/exercises/records

**Description**: Create custom exercise (authenticated users only)

**Request Body**:

```json
{
  "name": "My Custom Push-up Variation",
  "category": "bodyweight",
  "description": "Modified push-up with elevated feet",
  "muscle_groups": ["chest", "shoulders", "triceps", "core"],
  "image_url": "",
  "video_url": "",
  "is_custom": true,
  "user_id": "USER_ID"
}
```

**Success Response (200)**:

```json
{
  "id": "NEW_RECORD_ID",
  "name": "My Custom Push-up Variation",
  "category": "bodyweight",
  "description": "Modified push-up with elevated feet",
  "muscle_groups": ["chest", "shoulders", "triceps", "core"],
  "image_url": "",
  "video_url": "",
  "is_custom": true,
  "user_id": "USER_ID",
  "created": "2025-01-01 10:00:00.123Z",
  "updated": "2025-01-01 10:00:00.123Z"
}
```

### PATCH /api/collections/exercises/records/{id}

**Description**: Update custom exercise (owner only)

**Request Body**:

```json
{
  "name": "Updated Exercise Name",
  "description": "Updated description with more details",
  "muscle_groups": ["chest", "shoulders", "triceps"]
}
```

**Success Response (200)**:

```json
{
  "id": "RECORD_ID",
  "name": "Updated Exercise Name",
  "category": "bodyweight",
  "description": "Updated description with more details",
  "muscle_groups": ["chest", "shoulders", "triceps"],
  "image_url": "",
  "video_url": "",
  "is_custom": true,
  "user_id": "USER_ID",
  "created": "2025-01-01 10:00:00.123Z",
  "updated": "2025-01-01 11:00:00.456Z"
}
```

### DELETE /api/collections/exercises/records/{id}

**Description**: Delete custom exercise (owner only)

**Success Response (204)**: No content

## Dart Client Usage

```dart
// Get all built-in exercises by category
final response = await pb.collection('exercises').getList(
  page: 1,
  perPage: 50,
  filter: 'is_custom = false && category = "strength"',
  sort: 'name',
);
final exercises = response.items.map((item) => Exercise.fromJson(item.toJson())).toList();

// Search exercises by name
final searchResponse = await pb.collection('exercises').getList(
  page: 1,
  perPage: 20,
  filter: 'name ~ "push"',
  sort: 'name',
);

// Get user's custom exercises
final customResponse = await pb.collection('exercises').getList(
  page: 1,
  perPage: 50,
  filter: 'user_id = "${pb.authStore.model?.id}"',
  sort: '-created',
);

// Create custom exercise
final newExercise = await pb.collection('exercises').create(body: {
  'name': 'My Custom Exercise',
  'category': 'strength',
  'description': 'Personal exercise variation',
  'muscle_groups': ['chest', 'arms'],
  'is_custom': true,
  'user_id': pb.authStore.model?.id,
});

// Update custom exercise
final updatedExercise = await pb.collection('exercises').update(exerciseId, body: {
  'name': 'Updated Exercise Name',
  'description': 'Updated description',
});

// Delete custom exercise
await pb.collection('exercises').delete(exerciseId);
```

## Data Validation Rules

### PocketBase Collection Rules

**List Rule**: 
```javascript
// Users can view all built-in exercises and their own custom exercises
@request.auth.id != "" && (is_custom = false || user_id = @request.auth.id)
```

**View Rule**:
```javascript
// Same as list rule
@request.auth.id != "" && (is_custom = false || user_id = @request.auth.id)
```

**Create Rule**:
```javascript
// Authenticated users can create custom exercises
@request.auth.id != "" && @request.data.user_id = @request.auth.id && @request.data.is_custom = true
```

**Update Rule**:
```javascript
// Users can only update their own custom exercises
@request.auth.id != "" && user_id = @request.auth.id && is_custom = true
```

**Delete Rule**:
```javascript
// Users can only delete their own custom exercises  
@request.auth.id != "" && user_id = @request.auth.id && is_custom = true
```

### Client-side Validation

```dart
class ExerciseValidator {
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Exercise name is required';
    }
    if (name.trim().length < 2) {
      return 'Exercise name must be at least 2 characters';
    }
    if (name.trim().length > 100) {
      return 'Exercise name must be less than 100 characters';
    }
    return null;
  }
  
  static String? validateCategory(String? category) {
    const validCategories = ['strength', 'cardio', 'flexibility', 'bodyweight', 'sports'];
    if (category == null || !validCategories.contains(category)) {
      return 'Please select a valid category';
    }
    return null;
  }
  
  static String? validateMuscleGroups(List<String>? muscleGroups) {
    if (muscleGroups == null || muscleGroups.isEmpty) {
      return 'At least one muscle group is required';
    }
    const validMuscleGroups = [
      'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms',
      'abs', 'obliques', 'lower_back', 'glutes', 'quadriceps', 
      'hamstrings', 'calves', 'core', 'full_body'
    ];
    
    for (final group in muscleGroups) {
      if (!validMuscleGroups.contains(group)) {
        return 'Invalid muscle group: $group';
      }
    }
    return null;
  }
}
```

## Performance Optimizations

- **Indexing**: Database indexes on `category`, `user_id`, `is_custom`, and `name` fields
- **Pagination**: Limit queries to 50 exercises per page for optimal loading
- **Caching**: Cache built-in exercises locally since they don't change frequently
- **Search**: Use PocketBase full-text search for exercise name/description queries
- **Filtering**: Always include user context in filters to ensure proper data isolation
