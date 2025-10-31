# Authentication API Contract

**Collection**: `users` (PocketBase built-in)  
**Purpose**: User authentication and session management

## Endpoints

### POST /api/collections/users/auth-with-password

**Description**: Authenticate user with email and password

**Request Body**:
```json
{
  "identity": "user@example.com",
  "password": "userpassword"
}
```

**Success Response (200)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "record": {
    "id": "RECORD_ID",
    "email": "user@example.com",
    "name": "User Name",
    "username": "",
    "avatar": "",
    "created": "2025-01-01 10:00:00.123Z",
    "updated": "2025-01-01 10:00:00.123Z"
  }
}
```

**Error Response (400)**:
```json
{
  "code": 400,
  "message": "Failed to authenticate.",
  "data": {
    "identity": {
      "code": "validation_invalid_email",
      "message": "Must be a valid email address."
    }
  }
}
```

### POST /api/collections/users/records

**Description**: Create new user account

**Request Body**:
```json
{
  "email": "newuser@example.com",
  "password": "securepassword",
  "passwordConfirm": "securepassword",
  "name": "New User"
}
```

**Success Response (200)**:
```json
{
  "id": "RECORD_ID",
  "email": "newuser@example.com",
  "name": "New User",
  "username": "",
  "avatar": "",
  "created": "2025-01-01 10:00:00.123Z",
  "updated": "2025-01-01 10:00:00.123Z"
}
```

### POST /api/collections/users/auth-refresh

**Description**: Refresh authentication token

**Request Headers**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**Success Response (200)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "record": {
    "id": "RECORD_ID",
    "email": "user@example.com",
    "name": "User Name",
    "username": "",
    "avatar": "",
    "created": "2025-01-01 10:00:00.123Z",
    "updated": "2025-01-01 10:00:00.123Z"
  }
}
```

## Dart Client Usage

```dart
// Sign in
final authData = await pb.collection('users').authWithPassword(
  'user@example.com',
  'password',
);

// Create account
final user = await pb.collection('users').create(body: {
  'email': 'newuser@example.com',
  'password': 'securepassword',
  'passwordConfirm': 'securepassword',
  'name': 'New User',
});

// Check if authenticated
final isAuthenticated = pb.authStore.isValid;

// Get current user
final currentUser = pb.authStore.model;

// Sign out
pb.authStore.clear();
```

## Error Handling

```dart
try {
  await pb.collection('users').authWithPassword(email, password);
} on ClientException catch (e) {
  if (e.statusCode == 400) {
    throw 'Invalid email or password';
  }
  throw 'Authentication failed: ${e.response['message']}';
}
```