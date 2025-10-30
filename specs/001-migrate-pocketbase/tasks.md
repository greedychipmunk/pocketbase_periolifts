# Tasks: Backend Migration from Appwrite to PocketBase

**Input**: Design documents from `/specs/001-migrate-pocketbase/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Following PerioLifts Constitution Principle II (TDD), tests are MANDATORY and must be written BEFORE implementation. Tests are not optional - they are required for all features per constitutional requirements.

**Quality Gates**: All tasks must comply with Code Quality (Principle I) and Performance Requirements (Principle IV) from the constitution.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter project**: `lib/`, `test/` at repository root
- **Models**: `lib/models/`
- **Services**: `lib/services/`  
- **Screens**: `lib/screens/`
- **Widgets**: `lib/widgets/`
- **Providers**: `lib/providers/`
- **Tests**: `test/unit/`, `test/widget/`, `test/integration/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and PocketBase SDK integration

- [x] T001 Add PocketBase Dart SDK dependency to pubspec.yaml
- [x] T002 [P] Create PocketBase configuration in lib/config/pocketbase_config.dart
- [x] T003 [P] Create base PocketBase service class in lib/services/base_pocketbase_service.dart
- [x] T004 [P] Update analysis_options.yaml for enhanced static analysis per constitution requirements
- [x] T005 [P] Configure flutter_lints for constitutional code quality compliance

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Remove all Appwrite dependencies from pubspec.yaml
- [x] T007 [P] Create PocketBase-compatible base model class in lib/models/base_model.dart
- [x] T008 [P] Implement error handling utilities in lib/utils/error_handler.dart
- [x] T009 [P] Create offline storage service using sqflite in lib/services/offline_storage_service.dart
- [ ] T010 [P] Setup test mocks for PocketBase SDK in test/mocks/
- [ ] T011 [P] Configure test environment setup in test/test_helper.dart
- [ ] T012 Update environment constants in lib/constants/app_constants.dart to remove Appwrite URLs

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Authentication Migration (Priority: P1) 🎯 MVP

**Goal**: Users can sign in, sign up, and sign out using PocketBase authentication with identical UX

**Independent Test**: Create test account, sign in successfully, access protected content, sign out cleanly

### Tests for User Story 1 (REQUIRED - TDD Constitutional Mandate) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T013 [P] [US1] Unit test for AuthService PocketBase integration in test/unit/services/auth_service_test.dart
- [ ] T014 [P] [US1] Widget test for LoginScreen with PocketBase auth in test/widget/screens/login_screen_test.dart
- [ ] T015 [P] [US1] Widget test for SignUpScreen with PocketBase auth in test/widget/screens/sign_up_screen_test.dart
- [ ] T016 [P] [US1] Integration test for complete auth flow in test/integration/auth_flow_test.dart

### Implementation for User Story 1

- [x] T017 [P] [US1] Update User model for PocketBase schema in lib/models/user.dart
- [x] T018 [US1] Implement PocketBase AuthService in lib/services/auth_service.dart
- [ ] T019 [US1] Update AuthProvider to use PocketBase AuthService in lib/providers/auth_provider.dart
- [ ] T020 [US1] Update LoginScreen to use PocketBase authentication in lib/screens/login_screen.dart
- [ ] T021 [US1] Update SignUpScreen to use PocketBase authentication in lib/screens/sign_up_screen.dart
- [ ] T022 [US1] Update authentication middleware and guards in lib/utils/auth_guard.dart
- [ ] T023 [US1] Remove all Appwrite auth references from existing screens and services
- [ ] T024 [US1] Add authentication error handling and validation per constitutional requirements

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Data Service Migration (Priority: P2)

**Goal**: All CRUD operations for workouts, exercises, and programs work through PocketBase APIs

**Independent Test**: Create, read, update, and delete workout data successfully with proper persistence

### Tests for User Story 2 (REQUIRED - TDD Constitutional Mandate) ⚠️

- [ ] T025 [P] [US2] Unit test for Exercise model PocketBase serialization in test/unit/models/exercise_test.dart
- [ ] T026 [P] [US2] Unit test for Workout model PocketBase serialization in test/unit/models/workout_test.dart
- [ ] T027 [P] [US2] Unit test for WorkoutPlan model PocketBase serialization in test/unit/models/workout_plan_test.dart
- [ ] T028 [P] [US2] Unit test for ExerciseService CRUD operations in test/unit/services/exercise_service_test.dart
- [ ] T029 [P] [US2] Unit test for WorkoutService CRUD operations in test/unit/services/workout_service_test.dart
- [ ] T030 [P] [US2] Widget test for workout creation UI in test/widget/screens/workout_creation_test.dart
- [ ] T031 [P] [US2] Integration test for data synchronization in test/integration/data_sync_test.dart

### Implementation for User Story 2

- [ ] T032 [P] [US2] Update Exercise model for PocketBase schema in lib/models/exercise.dart
- [ ] T033 [P] [US2] Update Workout model for PocketBase schema in lib/models/workout.dart
- [ ] T034 [P] [US2] Update WorkoutPlan model for PocketBase schema in lib/models/workout_plan.dart
- [ ] T035 [P] [US2] Update WorkoutHistory model for PocketBase schema in lib/models/workout_history.dart
- [ ] T036 [US2] Implement PocketBase ExerciseService in lib/services/exercise_service.dart
- [ ] T037 [US2] Implement PocketBase WorkoutService in lib/services/workout_service.dart
- [ ] T038 [US2] Implement PocketBase WorkoutPlanService in lib/services/workout_plan_service.dart
- [ ] T039 [US2] Update ExerciseProvider for PocketBase services in lib/providers/exercise_provider.dart
- [ ] T040 [US2] Update WorkoutProvider for PocketBase services in lib/providers/workout_provider.dart
- [ ] T041 [US2] Update ProgramProvider for PocketBase services in lib/providers/program_provider.dart
- [ ] T042 [US2] Update data-dependent screens to use PocketBase services in lib/screens/
- [ ] T043 [US2] Implement offline data caching and synchronization logic
- [ ] T044 [US2] Remove all Appwrite data service references from codebase
- [ ] T045 [US2] Add data validation and error handling per constitutional performance requirements

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Real-time Features Migration (Priority: P3)

**Goal**: Live workout tracking and real-time synchronization work seamlessly with PocketBase

**Independent Test**: Start workout session, update progress, verify real-time updates across app interface

### Tests for User Story 3 (REQUIRED - TDD Constitutional Mandate) ⚠️

- [ ] T046 [P] [US3] Unit test for WorkoutSession model PocketBase schema in test/unit/models/workout_session_test.dart
- [ ] T047 [P] [US3] Unit test for WorkoutSessionService real-time operations in test/unit/services/workout_session_service_test.dart
- [ ] T048 [P] [US3] Widget test for real-time workout tracking UI in test/widget/screens/workout_tracking_test.dart
- [ ] T049 [P] [US3] Integration test for real-time synchronization in test/integration/realtime_sync_test.dart
- [ ] T050 [P] [US3] Integration test for offline workout tracking in test/integration/offline_workout_test.dart

### Implementation for User Story 3

- [ ] T051 [P] [US3] Update WorkoutSession model for PocketBase real-time schema in lib/models/workout_session.dart
- [ ] T052 [US3] Implement PocketBase WorkoutSessionService with real-time subscriptions in lib/services/workout_session_service.dart
- [ ] T053 [US3] Implement real-time synchronization utilities in lib/utils/realtime_sync.dart
- [ ] T054 [US3] Update WorkoutSessionProvider for real-time updates in lib/providers/workout_session_provider.dart
- [ ] T055 [US3] Update workout tracking screens for real-time features in lib/screens/workout_tracking_screen.dart
- [ ] T056 [US3] Implement offline workout session management with sync queue
- [ ] T057 [US3] Update dashboard and progress screens for real-time data in lib/screens/dashboard_screen.dart
- [ ] T058 [US3] Remove all Appwrite real-time subscription references
- [ ] T059 [US3] Add real-time connection management and error handling per constitutional requirements

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final cleanup

- [ ] T060 [P] Remove all remaining Appwrite imports and references from entire codebase
- [ ] T061 [P] Update app configuration and environment variables in lib/config/
- [ ] T062 [P] Performance optimization for PocketBase queries and caching
- [ ] T063 [P] Add comprehensive error logging and monitoring
- [ ] T064 [P] Update app documentation to reflect PocketBase migration
- [ ] T065 [P] Run constitutional coverage requirements validation (90%+ test coverage)
- [ ] T066 [P] Conduct security audit of PocketBase integration
- [ ] T067 [P] Verify all constitutional performance requirements (<100ms tracking, <3s startup)
- [ ] T068 [P] Execute data migration script validation per quickstart.md
- [ ] T069 Code cleanup and refactoring for maintainability
- [ ] T070 Final integration testing across all user stories

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independent but may reference US1 auth
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD constitutional mandate)
- Models before services that use them
- Services before providers that wrap them
- Core implementation before screen integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for AuthService PocketBase integration in test/unit/services/auth_service_test.dart"
Task: "Widget test for LoginScreen with PocketBase auth in test/widget/screens/login_screen_test.dart"
Task: "Widget test for SignUpScreen with PocketBase auth in test/widget/screens/sign_up_screen_test.dart"
Task: "Integration test for complete auth flow in test/integration/auth_flow_test.dart"

# Launch model updates for User Story 1 together:
Task: "Update User model for PocketBase schema in lib/models/user.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Authentication Migration)
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready - users can now sign in with PocketBase

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP - Authentication works!)
3. Add User Story 2 → Test independently → Deploy/Demo (Core CRUD functionality)
4. Add User Story 3 → Test independently → Deploy/Demo (Full real-time features)
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Authentication Migration)
   - Developer B: User Story 2 (Data Service Migration)
   - Developer C: User Story 3 (Real-time Features Migration)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD mandate)
- Constitutional requirements: 90%+ test coverage, <100ms tracking response, <3s startup
- Remove ALL Appwrite references by completion
- Maintain identical UX throughout migration
- Stop at any checkpoint to validate story independently
