# PocketBase Migration Guide

This guide explains how to use the new PocketBase migrations system that replaces the previous custom initialization scripts.

## What Changed

### Before (Custom Scripts)
- Used Dart script (`scripts/init_collections.dart`) and shell script (`scripts/init-collections-curl.sh`)
- Required manual execution or complex Docker init containers
- Collection creation via PocketBase API
- Potential issues with collection ID resolution

### After (Standard Migrations)
- Uses standard PocketBase JavaScript migrations in `pb_migrations/` directory
- Automatic execution on PocketBase startup
- Built-in migration tracking and history
- Standard PocketBase workflow

## Quick Start

### 1. Clean Installation

For a fresh setup:

```bash
# Stop any running containers
docker compose down -v

# Remove existing PocketBase data (optional - only if you want a clean start)
sudo rm -rf pocketbase/pb_data/*

# Start with migrations
docker compose up
```

### 2. First Time Setup

1. **PocketBase will start** and automatically apply all migrations
2. **Visit the admin UI** at http://localhost:8090/_/
3. **Create a superuser account** when prompted
4. **Verify collections** were created correctly in the Collections tab

### 3. Expected Collections

After migrations complete, you should see these collections:

- `users` (auth) - User accounts and profiles
- `exercises` - Exercise definitions (with 10 default exercises)
- `workouts` - Workout templates
- `workout_plans` - Long-term workout planning
- `workout_sessions` - Individual workout executions
- `workout_history` - Historical performance data

## Migration Files

All migration files are in `pb_migrations/`:

```
pb_migrations/
├── 1732713600_create_users.js
├── 1732713601_create_exercises.js
├── 1732713602_create_workouts.js
├── 1732713603_create_workout_plans.js
├── 1732713604_create_workout_sessions.js
├── 1732713605_create_workout_history.js
├── 1732713606_seed_default_exercises.js
└── README.md
```

## Advantages of Migrations

### 1. Automatic Execution
- No manual script running required
- Migrations apply automatically on PocketBase startup
- Consistent across all environments

### 2. Built-in Tracking
- PocketBase tracks which migrations have been applied
- Prevents duplicate execution
- Migration history visible in admin UI

### 3. Team Collaboration
- All team members get the same database schema
- Schema changes are version controlled
- No manual coordination needed

### 4. Production Ready
- Safe for production deployments
- Rollback capabilities with down migrations
- Proper dependency ordering

## Development Workflow

### Adding New Collections or Fields

1. **Create new migration file:**
   ```bash
   # Use current timestamp for ordering
   touch pb_migrations/$(date +%s)_add_your_feature.js
   ```

2. **Write migration:**
   ```javascript
   /// <reference path="../pb_data/types.d.ts" />
   
   migrate((app) => {
     // Your changes here
     const collection = new Collection({...})
     return app.save(collection)
   }, (app) => {
     // Rollback logic here
     const collection = app.findCollectionByNameOrId("your_collection")
     return app.delete(collection)
   })
   ```

3. **Test locally:**
   ```bash
   docker compose restart pocketbase
   ```

### Modifying Existing Collections

**Never edit existing migration files.** Instead, create new migrations:

```javascript
migrate((app) => {
  const collection = app.findCollectionByNameOrId("exercises")
  
  // Add new field
  collection.schema.push({
    "name": "difficulty_level",
    "type": "select",
    "options": {"values": ["easy", "medium", "hard"]}
  })
  
  return app.save(collection)
})
```

## Troubleshooting

### Migration Errors

1. **Check logs:**
   ```bash
   docker compose logs pocketbase
   ```

2. **Verify file syntax:**
   - Ensure valid JavaScript
   - Check TypeScript reference path
   - Verify migration function structure

3. **Check migration status:**
   - Admin UI > Settings > Migrations
   - See which migrations have been applied

### Starting Fresh

If you need to reset everything:

```bash
# Stop containers
docker compose down -v

# Remove all PocketBase data
sudo rm -rf pocketbase/pb_data/*

# Start fresh (migrations will run automatically)
docker compose up
```

### Legacy Script Cleanup

The old initialization scripts are still present but no longer used:

- `scripts/init_collections.dart` - Legacy Dart script
- `scripts/init-collections-curl.sh` - Legacy shell script
- `docker-compose.yml` - Updated to use migrations

You can safely ignore or remove these files after verifying migrations work correctly.

## Verification

### 1. Check Collections Created

```bash
# Via admin UI
open http://localhost:8090/_/

# Via API (after creating a user)
curl http://localhost:8090/api/collections
```

### 2. Test Default Exercises

The migration should create 10 default exercises:

```bash
# List exercises (requires authentication)
curl http://localhost:8090/api/collections/exercises/records
```

### 3. Verify Access Rules

- Users can only see their own data
- Default exercises are visible to all users
- Custom exercises are only visible to their creators

## Next Steps

1. **Verify your application works** with the new database schema
2. **Test user registration and workout creation** 
3. **Create sample data** to test the full workflow
4. **Consider additional migrations** for any missing features

## Support

If you encounter issues:

1. Check the detailed documentation in `pb_migrations/README.md`
2. Review migration files for schema details
3. Check PocketBase logs for specific error messages
4. Verify admin UI shows all collections correctly

The migration system provides a much more robust and maintainable approach to database schema management compared to the previous custom scripts.