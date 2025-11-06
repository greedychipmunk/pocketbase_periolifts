# Testing Collection Initialization

## Purpose
This document explains how to test the PocketBase collection initialization script after the fix for collection creation errors.

## The Fix
The script was updated to use actual collection IDs instead of collection names when creating relation fields. This is required for PocketBase v0.23.0+.

### What Changed
1. Added `get_collection_id()` function to fetch collection IDs by name
2. Updated all collection creation functions to accept collection IDs as parameters
3. Modified the main execution flow to:
   - Create collections in dependency order
   - Fetch collection IDs after creation
   - Pass actual IDs to dependent collections

### Collection Creation Order
1. **users** (no dependencies)
2. **exercises** (depends on users)
3. **workouts** (depends on users)
4. **workout_plans** (depends on users)
5. **workout_sessions** (depends on workouts and users)
6. **workout_history** (depends on users and workout_sessions)

## Testing Steps

### Prerequisites
1. Ensure `.env` file exists with proper credentials:
   ```bash
   cp .env.example .env
   # Edit .env with your admin credentials
   ```

2. Clean start (optional, to test from scratch):
   ```bash
   docker compose down -v
   rm -rf pocketbase/pb_data/*
   ```

### Running the Test

1. Start PocketBase and initialization:
   ```bash
   docker compose up
   ```

2. Watch for success messages:
   - ✅ PocketBase is ready!
   - ✅ Superuser exists and credentials are correct
   - ✅ Superuser authentication successful
   - 📄 Creating collection: users
   - ✅ Collection 'users' created successfully
   - 📄 Creating collection: exercises
   - ✅ Collection 'exercises' created successfully
   - ... (and so on for all collections)
   - 🎉 Collection initialization complete!

3. Expected output on success:
   ```
   📊 Summary: 6 created, 0 skipped
   ```

### Verifying Collections

1. Access PocketBase admin UI:
   ```
   http://localhost:8090/_/
   ```

2. Log in with your superuser credentials

3. Navigate to "Collections" and verify:
   - All 6 collections exist (users, exercises, workouts, workout_plans, workout_sessions, workout_history)
   - Each collection has the correct schema
   - Relation fields use actual collection IDs (visible in the admin UI)

### Troubleshooting

#### Error: "Superuser authentication failed"
- Ensure you've created a superuser via the PocketBase admin UI on first run
- Update `.env` with the correct credentials
- Restart: `docker compose down && docker compose up`

#### Error: "Failed to get users collection ID"
- Check PocketBase logs for API errors
- Verify the `get_collection_id()` function is working
- Try cleaning and restarting: `docker compose down -v && docker compose up`

#### Collections already exist
- The script will skip existing collections
- To recreate, delete via admin UI or remove `pocketbase/pb_data/`

## Manual Testing

You can also test the script manually:

```bash
# Set environment variables
export POCKETBASE_HOST=localhost
export POCKETBASE_PORT=8090
export POCKETBASE_ADMIN_EMAIL=your-email@example.com
export POCKETBASE_ADMIN_PASSWORD=your-password

# Run the script
./scripts/init-collections-curl.sh
```

## Expected Behavior

### First Run (no collections exist)
- Creates users collection
- Fetches users collection ID
- Creates exercises with relation to users (using ID)
- Creates workouts with relation to users (using ID)
- Creates workout_plans with relation to users (using ID)
- Creates workout_sessions with relations to workouts and users (using IDs)
- Creates workout_history with relations to users and workout_sessions (using IDs)
- Summary: 6 created, 0 skipped

### Second Run (collections exist)
- Skips all existing collections
- Summary: 0 created, 6 skipped

### Partial Run (some collections exist)
- Skips existing collections
- Creates missing collections
- Uses existing collection IDs for relations
- Summary: X created, Y skipped (where X + Y = 6)

## Validation

To validate the fix resolved the original error:

1. The original error was:
   ```
   Failed to create collection 'exercises': {"data":{"deleteRule":{"code":"validation_invalid_rule","message":"Invalid rule. Raw error: invalid left operand \"user_id\" - unknown field \"user_id\"."}
   ```

2. After the fix:
   - No "unknown field" errors should occur
   - All relation fields should use actual collection IDs
   - Collections should be created successfully in dependency order

## Debugging

Enable debug output by setting the DEBUG environment variable:

```bash
DEBUG=1 docker compose up
```

Or for manual testing:

```bash
export DEBUG=1
./scripts/init-collections-curl.sh
```

Debug output includes:
- API endpoint usage
- Authentication responses
- Collection ID fetching
- Token information (first 20 characters only)

Check the script logs:

```bash
docker compose logs pocketbase-init
```

Look for:
- `Debug: users collection ID: <id>` - confirms ID was fetched
- `Debug: Created users collection with ID: <id>` - confirms creation
- `Debug: Token length: <length>` - confirms authentication

## Cleanup

To reset for another test:

```bash
# Stop containers
docker compose down

# Remove all data (WARNING: deletes all PocketBase data)
rm -rf pocketbase/pb_data/*

# Restart
docker compose up
```
