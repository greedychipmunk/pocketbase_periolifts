# PocketBase Migrations

This directory contains JavaScript migration files that automatically set up the database schema for the PerioLifts application.

## Overview

PocketBase migrations are JavaScript files that define database schema changes in a version-controlled, repeatable way. Migrations run automatically when PocketBase starts, ensuring your database schema is always up-to-date.

## Migration Files

### Initial Setup

1. **`1732713600_init_superuser.js`** - Initial superuser/admin setup
   - Documents admin credentials from environment variables
   - Provides instructions for admin account creation
   - Reads `POCKETBASE_ADMIN_EMAIL` and `POCKETBASE_ADMIN_PASSWORD` from .env
   - Note: Actual admin creation must be done via CLI or admin UI

### Core Collections (in dependency order)

2. **`1732713601_create_users.js`** - Creates the users auth collection
   - User authentication and profile data
   - Fitness preferences and settings
   - Subscription and notification preferences

3. **`1732713601_create_exercises.js`** - Creates the exercises collection
   - Exercise definitions and metadata
   - Custom vs. default exercises
   - User-specific exercises with relation to users

4. **`1732713602_create_workouts.js`** - Creates the workouts collection
   - Workout templates and definitions
   - User-specific workouts with relation to users
   - Exercise lists and scheduling information

5. **`1732713603_create_workout_plans.js`** - Creates the workout_plans collection
   - Long-term workout planning
   - Scheduling and progression tracking
   - User-specific plans with relation to users

6. **`1732713604_create_workout_sessions.js`** - Creates the workout_sessions collection
   - Individual workout execution records
   - Relations to both users and workouts
   - Session timing and performance data

7. **`1732713605_create_workout_history.js`** - Creates the workout_history collection
   - Historical workout performance data
   - Relations to users and workout_sessions
   - Aggregated statistics and notes

### Data Seeding

8. **`1732713606_seed_default_exercises.js`** - Seeds default exercises
   - Creates a set of common exercises available to all users
   - Includes exercises for strength, cardio, and core training

## Migration Structure

Each migration file follows this pattern:

```javascript
/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  // Up migration - create/modify schema
  const collection = new Collection({
    "name": "collection_name",
    "type": "base", // or "auth"
    "schema": [
      // Field definitions
    ],
    "listRule": "access_rule",
    "viewRule": "access_rule",
    "createRule": "access_rule", 
    "updateRule": "access_rule",
    "deleteRule": "access_rule"
  })
  
  return app.save(collection)
}, (app) => {
  // Down migration - rollback changes (optional)
  const collection = app.findCollectionByNameOrId("collection_name")
  return app.delete(collection)
})
```

## Access Rules

All collections implement user-based access control:

- **Users collection**: Users can only access their own data
- **Other collections**: Users can only access records they own (via `user_id` relation)
- **Exercises**: Public exercises (`is_custom = false`) are visible to all users, custom exercises only to their creator

## Field Types Used

- **`text`** - String fields (names, descriptions)
- **`number`** - Numeric fields (durations, weights, counts)
- **`bool`** - Boolean flags (completion status, preferences)
- **`date`** - Date/time fields (scheduling, completion times)
- **`json`** - Complex data structures (exercise lists, performance data)
- **`url`** - Image and video URLs
- **`select`** - Enumerated values (units, themes, activity levels)
- **`relation`** - References to other collections

## Automatic Execution

Migrations run automatically when:

1. PocketBase starts up (via Docker)
2. The `--migrationsDir` flag points to the `pb_migrations` directory
3. Migration files are detected that haven't been applied yet

## Development Workflow

### Adding New Migrations

1. **Create new migration file:**
   ```bash
   # Use current timestamp for ordering
   touch pb_migrations/$(date +%s)_your_migration_name.js
   ```

2. **Follow naming convention:**
   - `{timestamp}_{descriptive_name}.js`
   - Use snake_case for names
   - Be descriptive but concise

3. **Write migration code:**
   - Always include TypeScript reference
   - Implement both up and down migrations
   - Test locally before committing

### Testing Migrations

1. **Clean start:**
   ```bash
   docker compose down -v
   rm -rf pocketbase/pb_data/*
   docker compose up
   ```

2. **Verify in admin UI:**
   - Visit http://localhost:8090/_/
   - Check Collections tab
   - Verify schema and rules are correct

3. **Test with sample data:**
   - Create test records via API or admin UI
   - Verify access rules work as expected

### Schema Changes

When modifying existing collections:

1. **Never edit existing migration files** - this breaks migration history
2. **Create new migration files** for schema changes
3. **Use appropriate migration operations:**
   - Add fields: `collection.schema.push(newField)`
   - Remove fields: Filter out from `collection.schema`
   - Modify fields: Replace in `collection.schema`
   - Update rules: Modify rule properties

### Example Schema Change Migration

```javascript
migrate((app) => {
  const collection = app.findCollectionByNameOrId("exercises")
  
  // Add new field
  collection.schema.push({
    "name": "difficulty_level",
    "type": "select",
    "required": false,
    "options": {
      "values": ["beginner", "intermediate", "advanced"]
    }
  })
  
  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("exercises") 
  
  // Remove the field (rollback)
  collection.schema = collection.schema.filter(field => field.name !== "difficulty_level")
  
  return app.save(collection)
})
```

## Troubleshooting

### Common Issues

1. **Migration fails to run:**
   - Check file syntax (valid JavaScript)
   - Verify TypeScript reference path
   - Ensure proper migration function structure

2. **Collection already exists error:**
   - Check if collection was created manually
   - Ensure migration ordering is correct
   - Consider adding existence check

3. **Relation field errors:**
   - Verify referenced collections exist first
   - Check collection names match exactly
   - Ensure proper dependency ordering

4. **Access rule validation errors:**
   - Verify field names in rules match schema
   - Check syntax of rule expressions
   - Test rules with sample data

### Debugging

1. **Enable verbose logging:**
   ```bash
   docker compose logs -f pocketbase
   ```

2. **Check migration status:**
   - View admin UI > Settings > Migrations
   - Check which migrations have been applied

3. **Manual migration testing:**
   ```bash
   # Access PocketBase container
   docker exec -it periolifts_pocketbase sh
   
   # Run specific migration
   ./pocketbase migrate up
   ```

## Migration History

PocketBase automatically tracks which migrations have been applied in the internal `_migrations` table. This ensures:

- Migrations only run once
- Order is preserved
- Team members get consistent database state
- Production deployments are predictable

## Best Practices

1. **Always backup** before running migrations in production
2. **Test migrations** thoroughly in development
3. **Keep migrations small** and focused on single changes
4. **Write descriptive names** for easy identification
5. **Include rollback logic** in down migrations
6. **Never modify** existing migration files after they've been applied
7. **Document complex migrations** with comments
8. **Test access rules** with different user scenarios

## Production Deployment

1. **Staging environment:**
   - Test migrations on staging data
   - Verify application compatibility
   - Check performance impact

2. **Production deployment:**
   - Schedule during maintenance window
   - Backup database before deployment
   - Monitor migration execution
   - Verify application functionality

3. **Rollback plan:**
   - Test down migrations in staging
   - Have database backup ready
   - Document rollback procedures

## Migration vs. Admin UI

While PocketBase allows schema changes via the admin UI, migrations are recommended for:

- **Team development** - Ensures everyone has the same schema
- **Production deployments** - Automated, repeatable process
- **Version control** - Track schema changes over time
- **Environment consistency** - Same schema across dev/staging/prod

The admin UI is best for:
- **Prototyping** new features
- **One-off data fixes** 
- **Exploring schema options**
- **Development experiments**

Any schema changes made in the admin UI should eventually be codified as migrations for production use.