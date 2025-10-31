# PerioLifts

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![PocketBase](https://img.shields.io/badge/PocketBase-0.23.0-B8860B?style=flat-square)](https://pocketbase.io)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.4.9-blue?style=flat-square)](https://riverpod.dev)

A comprehensive fitness tracking application designed to optimize workouts around menstrual cycles using Flutter and PocketBase.

## Overview

PerioLifts is a modern, cross-platform fitness tracking application that helps users plan and track their workouts with consideration for hormonal fluctuations throughout the menstrual cycle. Built with Flutter and powered by PocketBase, it provides a seamless, offline-capable experience across all platforms.

The application features a robust architecture built on modern patterns including:
- **Provider-based state management** with Riverpod
- **Offline-first architecture** with automatic synchronization
- **Type-safe backend integration** using PocketBase
- **Result pattern error handling** for robust data operations
- **Comprehensive workout tracking** with session management

## Features

- **Period-Optimized Workouts**: Tailor your fitness routine to your menstrual cycle phases
- **Comprehensive Exercise Database**: Extensive library of exercises with detailed instructions
- **Workout Planning**: Create and manage custom workout plans and programs
- **Session Tracking**: Real-time workout session monitoring with progress tracking
- **History & Analytics**: Detailed workout history with performance insights
- **Offline Support**: Full offline functionality with automatic sync when connected
- **Cross-Platform**: Native iOS, Android, web, and desktop applications
- **Modern UI**: Clean, intuitive interface following Material Design principles

## Architecture

PerioLifts is built using a modern, scalable architecture:

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

### Key Components

- **Models**: Type-safe data models with JSON serialization
- **Services**: Business logic layer with comprehensive error handling
- **Providers**: Reactive state management using Riverpod
- **Screens**: User interface components built with Flutter

## Getting Started

### Prerequisites

- **Flutter SDK** (3.9.2 or later)
- **Dart SDK** (3.0 or later)
- **PocketBase** server instance
- **Git** for version control

### Development Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/greedychipmunk/pocketbase_periolifts.git
   cd pocketbase_periolifts
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Set up PocketBase server**:
   - Download PocketBase from [pocketbase.io](https://pocketbase.io)
   - Start the server: `./pocketbase serve`
   - Configure collections using the provided schema

4. **Configure environment**:
   ```dart
   // Update lib/constants/app_constants.dart
   static const String pocketBaseDevUrl = 'http://localhost:8090';
   ```

5. **Run the application**:
   ```bash
   flutter run
   ```

### PocketBase Setup

The application requires several PocketBase collections:

- `users` - User authentication and profiles
- `exercises` - Exercise database
- `workouts` - Individual workout definitions
- `workout_plans` - Structured workout programs
- `workout_sessions` - Active workout tracking
- `workout_history` - Historical workout data

> [!NOTE]
> Collection schemas and sample data will be provided in future releases.

## Project Structure

```
lib/
├── config/              # App configuration and themes
├── constants/           # Application constants
├── models/              # Data models and entities
├── providers/           # Riverpod state providers
├── screens/             # UI screens and pages
├── services/            # Business logic and API services
├── utils/               # Utility functions and helpers
├── widgets/             # Reusable UI components
└── main.dart           # Application entry point

test/                    # Test files and utilities
docs/                    # Documentation and guides
```

## Core Domains

The application is organized around five core domains:

### 1. Exercise Domain
- Exercise database with categories and instructions
- Muscle group targeting and difficulty levels
- Equipment requirements and alternatives

### 2. Workout Domain
- Individual workout definitions
- Exercise sequencing and timing
- Difficulty progression tracking

### 3. Workout Plan Domain
- Multi-workout programs and schedules
- Period-phase optimization
- Progressive overload planning

### 4. Workout Session Domain
- Real-time workout execution
- Set and rep tracking
- Timer and rest period management

### 5. Workout History Domain
- Performance analytics and trends
- Historical data visualization
- Progress tracking metrics

## Development

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/auth_service_test.dart

# Run with coverage
flutter test --coverage
```

### Code Quality

The project maintains high code quality standards:

- **Linting**: Enforced via `flutter_lints`
- **Type Safety**: Comprehensive TypeScript-style type annotations
- **Architecture**: Consistent patterns across all domains
- **Testing**: Unit, widget, and integration tests

### Performance

The application is optimized for performance:

- **Lazy Loading**: On-demand data loading with pagination
- **Caching**: Intelligent provider-level caching
- **Offline Support**: Local database with sync capabilities
- **Bundle Optimization**: Tree-shaking and code splitting

## Contributing

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

Please ensure your code follows the established patterns and includes appropriate tests.

## Roadmap

- [ ] **Phase 1**: Core workout tracking functionality
- [ ] **Phase 2**: Period cycle integration and optimization
- [ ] **Phase 3**: Social features and community challenges
- [ ] **Phase 4**: AI-powered workout recommendations
- [ ] **Phase 5**: Wearable device integration

## Technical Specifications

### Dependencies

- **flutter**: ^3.9.2
- **flutter_riverpod**: ^2.4.9 - State management
- **pocketbase**: ^0.23.0+1 - Backend integration
- **uuid**: ^4.2.1 - Unique identifier generation
- **intl**: ^0.19.0 - Internationalization
- **sqflite**: ^2.3.0 - Local database

### Platform Support

- ✅ **iOS** (12.0+)
- ✅ **Android** (API 21+)
- ✅ **Web** (Modern browsers)
- ✅ **macOS** (10.14+)
- ✅ **Windows** (Windows 10+)
- ✅ **Linux** (Ubuntu 18.04+)

### Performance Requirements

- **Startup Time**: < 3 seconds
- **Tracking Response**: < 100ms
- **Sync Performance**: Background operation
- **Memory Usage**: Optimized for mobile devices

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions, issues, or contributions:

- **Issues**: [GitHub Issues](https://github.com/greedychipmunk/pocketbase_periolifts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/greedychipmunk/pocketbase_periolifts/discussions)
- **Documentation**: [Project Wiki](https://github.com/greedychipmunk/pocketbase_periolifts/wiki)

---

Built with ❤️ using [Flutter](https://flutter.dev) and [PocketBase](https://pocketbase.io)
