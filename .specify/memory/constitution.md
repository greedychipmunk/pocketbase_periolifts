<!--
Sync Impact Report:
- Version change: N/A → 1.0.0 (Initial constitution)
- Added sections: All core principles and governance
- Modified principles: N/A (new constitution)
- Templates requiring updates:
  ✅ Updated: plan-template.md - added constitution compliance checks
  ✅ Updated: spec-template.md - maintains requirements alignment  
  ✅ Updated: tasks-template.md - updated for TDD mandate and Flutter paths
  ⚠ N/A: commands/ directory does not exist
- Follow-up TODOs: None - all placeholders filled and templates updated
-->

# PerioLifts Constitution

## Core Principles

### I. Code Quality (NON-NEGOTIABLE)

Every code contribution MUST meet strict quality standards before merge. All code MUST pass static analysis with zero warnings, follow Dart/Flutter style guidelines exactly, and include comprehensive documentation for public APIs. Code reviews are mandatory with at least two reviewers - one for functionality and one for quality/style. No exceptions for "quick fixes" or "urgent features."

**Rationale**: Fitness tracking apps handle personal health data requiring reliability. Poor code quality leads to bugs that can impact user safety and trust in workout recommendations.

### II. Test-Driven Development (NON-NEGOTIABLE)

TDD cycle is strictly enforced: Write failing tests → Implement minimum code to pass → Refactor. Every feature MUST have unit tests achieving 90%+ coverage, integration tests for service layer interactions, and widget tests for UI components. Tests MUST be written before implementation begins.

**Rationale**: Workout data accuracy is critical for user progress and safety. Untested code risks corrupting workout history, incorrect calculations, or fitness tracking failures that could harm user goals.

### III. User Experience Consistency

All UI components MUST follow Material Design 3 guidelines and maintain consistent interaction patterns across the app. Navigation flows MUST be predictable, loading states visible, and error messages actionable. Accessibility standards (WCAG 2.1 AA) are mandatory for inclusive fitness tracking.

**Rationale**: Fitness apps are used during physical activity when users have limited attention and dexterity. Inconsistent UX can lead to incorrect exercise logging or missed workout tracking, directly impacting fitness progress.

### IV. Performance Requirements

App MUST launch in under 3 seconds on mid-range devices (5-year-old Android/iOS). Workout tracking screens MUST respond to user input within 100ms. Database operations MUST complete within 500ms on 3G connections. Memory usage MUST stay under 200MB during active workout sessions.

**Rationale**: Performance issues during workouts break focus and can cause users to abandon exercises mid-set. Real-time tracking demands ensure accurate workout timing and rep counting.

### V. Data Integrity & Security

All workout data MUST be validated client-side and server-side with type-safe models. Offline-first architecture required - users MUST be able to track workouts without internet connectivity. All API communications MUST use HTTPS with proper certificate validation. Personal health data encrypted at rest and in transit.

**Rationale**: Fitness tracking involves sensitive personal data and must work reliably in gyms with poor connectivity. Data loss of workout progress can severely impact user motivation and long-term fitness goals.

## Performance Standards

### Response Time Requirements

- App startup: <3 seconds (cold start)
- Screen transitions: <200ms
- Workout tracking operations: <100ms
- Database sync operations: <500ms on 3G

### Resource Constraints

- Memory usage: <200MB during workout sessions
- Battery drain: <5% per hour during active tracking
- Storage: Efficient local caching with automatic cleanup
- Network: Graceful degradation on poor connections

### Reliability Standards

- Crash rate: <0.1% of user sessions
- Data loss tolerance: Zero tolerance for workout data loss
- Offline capability: Full workout tracking without internet
- Recovery: Automatic data sync when connectivity restored

## Development Workflow

### Quality Gates

All feature branches MUST pass automated CI checks before merge review. Manual testing required on both iOS and Android before production deployment. Performance profiling mandatory for any change affecting workout tracking or data operations.

### Code Review Process

Two-stage review process: Technical review for functionality and architecture review for performance/scalability. All reviews MUST verify constitution compliance. Breaking changes require explicit justification and migration plan documentation.

### Testing Strategy

Unit tests for all business logic and data models. Integration tests for backend service interactions. Widget tests for all user-facing components. End-to-end tests for critical user journeys (workout creation, tracking, completion).

## Governance

This constitution supersedes all other development practices and guidelines. All pull requests and code reviews MUST verify compliance with these principles. Any complexity that violates these principles MUST be explicitly justified with documented alternatives that were considered and rejected.

Constitution amendments require team consensus, documentation of rationale, and migration plan for existing code. Use `README.md` and inline code documentation for runtime development guidance beyond constitutional requirements.

**Version**: 1.0.0 | **Ratified**: 2025-10-29 | **Last Amended**: 2025-10-29
