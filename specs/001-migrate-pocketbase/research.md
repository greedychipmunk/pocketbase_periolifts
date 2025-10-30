# Research: Backend Migration from Appwrite to PocketBase

**Feature**: Backend Migration from Appwrite to PocketBase  
**Created**: 2025-10-29  
**Purpose**: Research technical decisions and patterns for migrating Flutter app from Appwrite to PocketBase

## PocketBase Dart SDK Integration

**Decision**: Use official PocketBase Dart SDK (pocketbase) for all backend communications

**Rationale**:

- Official SDK provides type-safe API interactions
- Built-in authentication and real-time subscription support
- Optimized for mobile performance with automatic request batching
- Active maintenance and Flutter-specific optimizations

**Alternatives considered**:

- Direct HTTP calls to PocketBase REST API - rejected due to lack of type safety and increased boilerplate
- Custom wrapper around HTTP client - rejected due to maintenance overhead and missing real-time features

## Authentication Migration Strategy

**Decision**: Migrate to PocketBase's built-in email/password authentication with session management

**Rationale**:

- PocketBase provides similar auth patterns to Appwrite with JWT tokens
- Built-in session management with automatic token refresh
- Email verification and password reset capabilities included
- OAuth providers can be added later if needed

**Alternatives considered**:

- External auth provider (Firebase Auth) - rejected to minimize external dependencies
- Custom JWT implementation - rejected due to security complexity and maintenance burden

## Data Model Migration Approach

**Decision**: Maintain existing Dart model classes with updated fromJson/toJson methods for PocketBase

**Rationale**:

- Preserves existing business logic and validation
- Minimizes UI changes by keeping model interfaces identical
- PocketBase auto-generates collection schemas from first record insertion
- Easy to add PocketBase-specific fields (id, created, updated) to existing models

**Alternatives considered**:

- Complete data model rewrite - rejected due to extensive UI impact
- Generated models from PocketBase schema - rejected due to loss of existing business logic

## Real-time Synchronization Pattern

**Decision**: Use PocketBase real-time subscriptions for workout tracking with manual conflict resolution

**Rationale**:

- PocketBase provides WebSocket-based real-time updates with automatic reconnection
- Can subscribe to specific collections and records for targeted updates
- Manual conflict resolution appropriate for personal fitness data (last-write-wins)
- Reduces server polling and improves battery life

**Alternatives considered**:

- Polling-based updates - rejected due to battery drain and delayed updates
- Automatic conflict resolution - rejected due to complexity and potential data loss risks

## Offline-First Architecture Implementation

**Decision**: Implement local SQLite cache with PocketBase sync on connectivity restoration

**Rationale**:

- Critical for gym environments with poor connectivity
- PocketBase supports batch operations for efficient sync
- Local SQLite provides ACID guarantees for workout data integrity
- Can leverage Dart's sqflite package for local storage

**Alternatives considered**:

- Memory-only offline storage - rejected due to data loss risk on app termination
- File-based storage - rejected due to complexity and lack of transaction support
- Hive database - rejected due to lack of relational capabilities needed for workout data

## Performance Optimization Strategy

**Decision**: Implement lazy loading with pagination and selective field loading

**Rationale**:

- Meets constitutional requirements for <500ms database operations
- PocketBase supports field selection and pagination out of the box
- Reduces memory usage during workout sessions
- Enables efficient loading of large workout histories

**Alternatives considered**:

- Eager loading all data - rejected due to memory constraints
- Client-side pagination only - rejected due to poor performance with large datasets

## Migration Execution Plan

**Decision**: Blue-green deployment approach with parallel PocketBase instance

**Rationale**:

- Minimizes downtime during migration
- Allows testing with production data before switchover
- Easy rollback capability if issues arise
- Users can continue using app during migration setup

**Alternatives considered**:

- Direct cutover migration - rejected due to downtime risk
- Gradual feature-by-feature migration - rejected due to complexity of maintaining two backend systems
