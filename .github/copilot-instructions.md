# GitHub Copilot Custom Instructions for PerioLifts

## Project Overview

PerioLifts is a comprehensive fitness tracking application optimized for menstrual cycle phases. It's built with **Flutter 3.9.2+** and **Dart 3.0+**, using **PocketBase** as the backend and **Riverpod** for state management.

### Core Architecture

```
┌─ Presentation Layer ─────────────────────────────┐
│  Screens & Widgets (Flutter)                     │
├─ State Management ───────────────────────────────┤
│  Riverpod Providers (AsyncValue, StateNotifier)  │
├─ Business Logic ─────────────────────────────────┤
│  Services (Result<T> Pattern)                    │
├─ Data Layer ─────────────────────────────────────┤
│  Models (BasePocketBaseModel)                    │
├─ Backend ────────────────────────────────────────┤
│  PocketBase (Real-time Database & Auth)          │
└──────────────────────────────────────────────────┘
```

## Code Style and Formatting

### General Style
- **Follow Effective Dart guidelines** as documented in `.github/instructions/dart-n-flutter.instructions.md`
- Use `dart format` for all code formatting (enforced in CI/CD)
- Prefer lines **80 characters or fewer**
- Use **single quotes** for strings (enforced by linter)
- Use **const constructors** wherever possible for performance

### Naming Conventions
- **Types, Classes, Extensions**: `UpperCamelCase` (e.g., `WorkoutSession`, `BasePocketBaseModel`)
- **Files, Directories**: `lowercase_with_underscores` (e.g., `workout_session.dart`, `base_model.dart`)
- **Variables, Methods, Parameters**: `lowerCamelCase` (e.g., `workoutId`, `fetchWorkouts`)
- **Constants**: `lowerCamelCase` (preferred over SCREAMING_CAPS per Dart guidelines)
- **Private members**: Prefix with `_` (e.g., `_internalState`)

### Architectural Naming Patterns
Follow these suffixes for architectural components:
- Models: `WorkoutPlan`, `Exercise`, `User` (inherit from `BasePocketBaseModel`)
- Services: `WorkoutService`, `AuthService` (inherit from `BasePocketBaseService`)
- Providers: `workoutProvider`, `authStateProvider` (Riverpod providers)
- Screens: `LoginScreen`, `WorkoutHistoryScreen`
- Widgets: `WorkoutCard`, `ExerciseListItem` (avoid generic names like "Widget")

## Project Structure

```
lib/
├── config/              # App configuration (themes, PocketBase config)
├── constants/           # Application constants
├── models/              # Data models (all extend BasePocketBaseModel)
├── providers/           # Riverpod state providers
├── screens/             # UI screens and pages
├── services/            # Business logic and API services
├── utils/               # Utility functions (Result<T>, validators, error handlers)
├── widgets/             # Reusable UI components
└── main.dart           # Application entry point

test/
├── integration/         # Integration tests
├── services/            # Service unit tests
├── screens/             # Screen widget tests
└── widget/              # Widget tests
```

## Core Domains

The application is organized around **five core domains**:

1. **Exercise Domain**: Exercise database, categories, muscle groups, equipment
2. **Workout Domain**: Individual workout definitions and sequencing
3. **Workout Plan Domain**: Multi-workout programs optimized for cycle phases
4. **Workout Session Domain**: Real-time workout execution and tracking
5. **Workout History Domain**: Performance analytics and historical data

## State Management with Riverpod

- Use **flutter_riverpod** (version 2.4.9+) for all state management
- Prefer `AsyncValue<T>` for async operations that can be loading/error/success
- Use `StateNotifier` for complex state that needs to be updated incrementally
- Provider naming: use descriptive names like `workoutSessionProvider`, `authStateProvider`
- Always handle all `AsyncValue` states: loading, error, and data
- Use `ref.watch` in widgets, `ref.read` in callbacks/methods

**Example Provider Pattern:**
```dart
final workoutProvider = FutureProvider.autoDispose<List<Workout>>((ref) async {
  final service = ref.read(workoutServiceProvider);
  final result = await service.getWorkouts();
  return result.getOrThrow(); // Throws AppError on failure
});
```

## PocketBase Integration

### Models
- **All models must extend `BasePocketBaseModel`** which provides `id`, `created`, `updated` fields
- Implement `toJson()` for serialization
- Implement `copyWith()` for immutability
- Use `fromJson()` factory constructor for deserialization
- Use `BasePocketBaseModel.parseTimestamp()` for parsing PocketBase timestamps

**Example Model:**
```dart
class Exercise extends BasePocketBaseModel {
  final String name;
  final String category;
  
  const Exercise({
    required String id,
    required DateTime created,
    required DateTime updated,
    required this.name,
    required this.category,
  }) : super(id: id, created: created, updated: updated);
  
  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    created: BasePocketBaseModel.parseTimestamp(json, 'created'),
    updated: BasePocketBaseModel.parseTimestamp(json, 'updated'),
    name: json['name'] as String,
    category: json['category'] as String,
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
  };
  
  @override
  Exercise copyWith({String? name, String? category}) => Exercise(
    id: id,
    created: created,
    updated: updated,
    name: name ?? this.name,
    category: category ?? this.category,
  );
}
```

### Services
- **All services must extend `BasePocketBaseService`** which provides:
  - `pb` instance for PocketBase access
  - `handleError()` method for error handling (legacy string-based)
  - Common pagination methods
- Use the **Result<T> pattern** for all service methods (see `lib/utils/result.dart`)
- Use **ErrorHandler.handlePocketBaseError()** to convert PocketBase exceptions to `AppError`
- Never throw exceptions from service methods; wrap in `Result.error()`
- Use descriptive error messages

**Example Service Method:**
```dart
class ExerciseService extends BasePocketBaseService {
  Future<Result<List<Exercise>>> getExercises() async {
    try {
      final records = await pb.collection('exercises').getFullList();
      final exercises = records.map((r) => Exercise.fromJson(r.toJson())).toList();
      return Result.success(exercises);
    } on ClientException catch (e) {
      return Result.error(ErrorHandler.handlePocketBaseError(e));
    } catch (e) {
      return Result.error(
        AppError.unknown(
          message: 'Unexpected error fetching exercises',
          details: {'originalError': e.toString()},
        ),
      );
    }
  }
}
```

## Error Handling

### Result Pattern
- Use `Result<T>` from `lib/utils/result.dart` for all operations that can fail
- Result has two states: `Result.success(data)` and `Result.error(AppError)`
- Result is a sealed class with `Success<T>` and `Error<T>` subtypes
- Use switch expressions or methods to handle results:
  ```dart
  // Using switch expressions (pattern matching)
  final result = await service.getWorkouts();
  final workouts = switch (result) {
    Success(data: final data) => data,
    Error(error: final error) => throw error,
  };
  
  // Using getOrThrow() method
  final workouts = result.getOrThrow();
  
  // Using getOrDefault() method
  final workouts = result.getOrDefault([]);
  
  // Using map() for transformation
  final names = result.map((workouts) => workouts.map((w) => w.name).toList());
  ```

### Exception Handling
- Catch specific exceptions with `on` clauses when possible
- Use **ErrorHandler.handlePocketBaseError()** from `lib/utils/error_handler.dart` to convert PocketBase `ClientException` to `AppError`
- Never silently catch errors; always log or return error state
- Use `rethrow` to propagate exceptions when appropriate

### AppError Types
The `AppError` class (in `lib/utils/result.dart`) provides factory methods for different error types:
- `AppError.validation()` - For validation errors
- `AppError.authentication()` - For authentication errors
- `AppError.network()` - For network errors
- `AppError.server()` - For server errors
- `AppError.notFound()` - For resource not found errors
- `AppError.permission()` - For permission errors
- `AppError.unknown()` - For unexpected errors

**Example Error Handling Pattern:**
```dart
try {
  final result = await pb.collection('exercises').getOne(id);
  return Result.success(Exercise.fromJson(result.toJson()));
} on ClientException catch (e) {
  // Use ErrorHandler to convert to AppError
  return Result.error(ErrorHandler.handlePocketBaseError(e));
} catch (e) {
  // Handle unexpected errors
  return Result.error(
    AppError.unknown(
      message: 'Unexpected error',
      details: {'error': e.toString()},
    ),
  );
}
```

## Testing Requirements

### Unit Tests
- Write unit tests for **every service class**
- Test the logic of **every public method**
- Use `mockito` for mocking dependencies (see `pubspec.yaml`)
- Place service tests in `test/services/`
- Naming: `[service_name]_test.dart` (e.g., `auth_service_test.dart`)

### Widget Tests
- Write widget tests for all screens
- Test routing, dependency injection, and user interactions
- Place widget tests in `test/widget/` or `test/screens/`
- Use `WidgetTester` and `pumpWidget` for testing

### Integration Tests
- Place integration tests in `test/integration/`
- Test complete user flows (e.g., authentication flow, workout session flow)
- Use test helpers from `test/test_helpers.dart`

### Test Configuration
- Use `test_config.dart` for test-specific configuration
- Use `sqflite_common_ffi` for testing database operations (see `pubspec.yaml`)

**Example Test Structure:**
```dart
void main() {
  group('ExerciseService', () {
    late ExerciseService service;
    
    setUp(() {
      service = ExerciseService();
    });
    
    test('getExercises returns success with list', () async {
      // Arrange
      // Act
      final result = await service.getExercises();
      // Assert
      expect(result.isSuccess, true);
    });
  });
}
```

## Security Practices

### Authentication
- Use `AuthService` (in `lib/services/auth_service.dart`) for all authentication operations
- Store authentication tokens securely using PocketBase's built-in auth store
- Never hard-code credentials
- Use `.env.example` as a template and configure actual values in `.env` (gitignored)

### Data Validation
- Use validators from `lib/utils/validators.dart`
- Validate all user inputs before sending to backend
- Sanitize data when displaying user-generated content

### API Security
- All API calls go through PocketBase, which handles authentication automatically
- Use `pb.authStore.isValid` to check authentication status
- Never expose PocketBase admin credentials in client code

## Performance Considerations

### Lazy Loading
- Use pagination for large data sets
- Implement on-demand data loading with `autoDispose` providers
- Use `FutureProvider.autoDispose` for data that doesn't need to persist

### Caching
- Leverage Riverpod's provider-level caching
- Use `StateNotifier` for data that needs to be cached across rebuilds
- Consider offline-first approach with local SQLite database (using `sqflite`)

### Optimization
- Use `const` constructors wherever possible (enforced by linter)
- Prefer `final` for immutability (enforced by linter)
- Avoid rebuilding widgets unnecessarily; use `Consumer` or `watch` selectively

## Documentation

### Doc Comments
- Use `///` for public API documentation
- Start with a single-sentence summary
- Document parameters with `[paramName]` in prose
- Include code examples for complex APIs using triple backticks
- Document exceptions that can be thrown

**Example:**
```dart
/// Fetches all exercises from the database.
///
/// Returns a [Result] containing the list of exercises on success,
/// or an [AppError] on failure.
///
/// Example:
/// ```dart
/// final result = await exerciseService.getExercises();
/// final exercises = switch (result) {
///   Success(data: final data) => data,
///   Error(error: final error) => throw error,
/// };
/// // Or simply: final exercises = result.getOrThrow();
/// ```
Future<Result<List<Exercise>>> getExercises() async { ... }
```

### Code Comments
- Avoid obvious comments
- Explain **why**, not **what**
- Use comments for complex algorithms or business logic
- Keep comments up-to-date with code changes

## Dependencies

### Core Dependencies
- `flutter`: ^3.9.2
- `flutter_riverpod`: ^2.4.9 - State management
- `pocketbase`: ^0.23.0+1 - Backend integration
- `provider`: ^6.1.1 - Additional state management utilities
- `sqflite`: ^2.3.0 - Local database for offline support
- `shared_preferences`: ^2.5.3 - Local key-value storage
- `uuid`: ^4.2.1 - Unique identifier generation
- `intl`: ^0.19.0 - Internationalization

### UI Dependencies
- `cupertino_icons`: ^1.0.8 - iOS-style icons
- `table_calendar`: ^3.1.3 - Calendar widget for cycle tracking
- `vibration`: ^3.1.4 - Haptic feedback
- `flutter_local_notifications`: ^19.5.0 - Local notifications

### Dev Dependencies
- `flutter_test`: SDK
- `flutter_lints`: ^5.0.0 - Linting rules
- `mockito`: ^5.4.4 - Mocking for tests
- `build_runner`: ^2.4.9 - Code generation
- `sqflite_common_ffi`: ^2.3.0+4 - SQLite for testing

## Build and Deployment

### Running the App
```bash
flutter pub get
flutter run
```

### Running Tests
```bash
# All tests
flutter test

# Specific test
flutter test test/services/auth_service_test.dart

# With coverage
flutter test --coverage
```

### Code Quality Checks
```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Fix common issues
dart fix --apply
```

### Environment Configuration
- Copy `.env.example` to `.env` and configure values
- Required env vars: `POCKETBASE_ADMIN_EMAIL`, `POCKETBASE_ADMIN_PASSWORD`
- Development PocketBase URL: `http://localhost:8090` (configured in `lib/constants/app_constants.dart`)

## Common Patterns and Anti-Patterns

### ✅ DO
- Use the Result<T> pattern for operations that can fail
- Extend BasePocketBaseModel for all models
- Extend BasePocketBaseService for all services
- Use Riverpod providers for state management
- Write tests for all services and screens
- Use const constructors
- Make fields final when they won't change
- Use single quotes for strings
- Handle all AsyncValue states (loading, error, data)

### ❌ DON'T
- Don't put business logic in widgets
- Don't throw exceptions from services; use Result<T>
- Don't use `new` keyword (deprecated in Dart)
- Don't use `print()` in production code (use proper logging)
- Don't hardcode credentials or sensitive data
- Don't create mutable models
- Don't use `dynamic` unless absolutely necessary
- Don't ignore linter warnings without good reason

## Additional Resources

- **Effective Dart**: https://dart.dev/effective-dart
- **Flutter Architecture**: https://docs.flutter.dev/app-architecture/recommendations
- **Riverpod Documentation**: https://riverpod.dev
- **PocketBase Documentation**: https://pocketbase.io/docs
- **Project-specific Dart/Flutter rules**: `.github/instructions/dart-n-flutter.instructions.md`

## Changelog Notes

When making changes, follow semantic versioning and update relevant documentation. The current version is **1.0.0+1** as specified in `pubspec.yaml`.
