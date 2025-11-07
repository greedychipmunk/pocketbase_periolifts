# Collection Creation Fix - Summary

## Problem Solved
Fixed the collection creation error that occurred when running `docker compose up`:
```
Failed to create collection 'exercises': {"data":{"deleteRule":{"code":"validation_invalid_rule","message":"Invalid rule. Raw error: invalid left operand \"user_id\" - unknown field \"user_id\"."},"listRule":{"code":"validation_invalid_rule","message":"Invalid rule. Raw error: invalid left operand \"is_custom\" - unknown field \"is_custom\"."}}
```

## Root Cause
PocketBase validates API rules (listRule, viewRule, createRule, updateRule, deleteRule) against the collection schema **during** the collection creation API call. However, this validation occurs **before** the schema fields are actually created, causing a chicken-and-egg problem where rules reference fields that don't exist yet during the validation phase.

This results in errors like:
- "invalid left operand 'user_id' - unknown field 'user_id'"
- "invalid left operand 'is_custom' - unknown field 'is_custom'"

Even though these fields are defined in the schema being sent in the same API call, PocketBase validates the rules against an empty schema first.

### Note: Different from Previous Fix
A previous fix addressed the issue of using collection **names** instead of collection **IDs** for relation fields (e.g., `"collectionId": "users"` vs `"collectionId": "<actual-uuid>"`). That fix is still in place with the `get_collection_id()` function and dependency-ordered creation. This current fix addresses a **different** issue: the validation timing of rules vs schema fields.

## Solution Implemented

### Two-Step Collection Creation
The fix separates collection creation into two distinct API calls:

1. **Step 1: Create Collection with Schema Only**
   - POST `/api/collections` with schema fields but **without** validation rules
   - This creates the collection and all its fields
   - Returns the collection ID

2. **Step 2: Update Collection with Rules**
   - PATCH `/api/collections/{id}` with validation rules only
   - Now that the fields exist, the rules can be validated successfully
   - Completes the collection setup

### Technical Changes

#### Shell Script (`scripts/init-collections-curl.sh`)

1. **New Function: `update_collection_rules()`**
   - Added function to update collection rules after creation
   - Uses PATCH `/api/collections/{id}` endpoint
   - Takes token, collection ID, rules JSON, and collection name

2. **Separated Collection Definitions**
   - Split each collection into two functions:
     - `create_*_collection_schema()` - Returns schema JSON only
     - `create_*_collection_rules()` - Returns rules JSON only
   - Applied to all collections: users, exercises, workouts, workout_plans, workout_sessions, workout_history

3. **Updated Main Execution Flow**
   - For each collection:
     1. Create with schema-only JSON
     2. Fetch collection ID
     3. Update with rules-only JSON
   - Maintains dependency order (users → exercises/workouts/workout_plans → workout_sessions → workout_history)

#### Dart Script (`scripts/init_collections.dart`)

1. **Modified `CollectionSchema.toJson()` Method**
   - Added optional parameter `includeRules` (default: true for backward compatibility)
   - When `includeRules = false`, returns schema without validation rules
   - When `includeRules = true`, returns complete schema with rules

2. **New Method: `CollectionSchema.toRulesJson()`**
   - Returns only the validation rules
   - Used for the update step

3. **Updated `createCollection()` Method**
   - Step 1: Create collection with `toJson(includeRules: false)`
   - Step 2: Update collection with `toRulesJson()`
   - Both steps include proper logging

### Files Modified
- `scripts/init-collections-curl.sh` - Main fix implementation (shell script)
- `scripts/init_collections.dart` - Main fix implementation (Dart script)
- `COLLECTION_FIX_SUMMARY.md` - Updated documentation

### Key Benefits
1. **Eliminates validation errors** - Rules are only validated after fields exist
2. **Works with all PocketBase versions** - Compatible with v0.23.0+
3. **Maintains backward compatibility** - Existing collections are not affected
4. **Clear separation of concerns** - Schema and rules are independent
5. **Better error messages** - Separate steps make debugging easier

## How to Test

### Quick Test
```bash
# Ensure .env file exists with superuser credentials
cp .env.example .env
# Edit .env with your credentials

# Clean start (optional)
docker compose down -v
rm -rf pocketbase/pb_data/*

# Start and watch for success
docker compose up
```

### Expected Success Output
```
✅ PocketBase is ready!
✅ Superuser exists and credentials are correct
✅ Superuser authentication successful
📄 Creating collection: users
✅ Collection 'users' created successfully
🔧 Updating rules for collection: users
✅ Rules for 'users' updated successfully
📄 Creating collection: exercises
✅ Collection 'exercises' created successfully
🔧 Updating rules for collection: exercises
✅ Rules for 'exercises' updated successfully
...
🎉 Collection initialization complete!
📊 Summary: 6 created, 0 skipped
```

### Enable Debug Output
```bash
DEBUG=1 docker compose up
```

## Verification
After successful initialization:
1. Visit http://localhost:8090/_/
2. Log in with your superuser credentials
3. Navigate to "Collections"
4. Verify all 6 collections exist with correct schemas
5. Check that relation fields show actual collection IDs (not names)

## Rollback (If Needed)
If you need to recreate collections:
```bash
# Stop containers
docker compose down

# Remove all PocketBase data
rm -rf pocketbase/pb_data/*

# Restart
docker compose up
```

## Additional Resources
- Full testing guide: `scripts/TESTING_COLLECTIONS.md`
- Script documentation: `scripts/README.md`
- Environment setup: `.env.example`

## Compatibility
- PocketBase v0.23.0+
- Alpine Linux (used in Docker container)
- Bash 4.0+
- Optional: jq for improved JSON parsing (automatically detected)

## Security Notes
- No hardcoded credentials
- Admin credentials read from environment variables
- Debug mode disabled by default in production
- Token information only partially logged (first 20 chars)

## Support
If you encounter issues:
1. Check the troubleshooting section in `TESTING_COLLECTIONS.md`
2. Enable debug mode: `DEBUG=1 docker compose up`
3. Review logs: `docker compose logs pocketbase-init`
4. Ensure superuser credentials are correct in `.env`
5. Verify PocketBase is running: `curl http://localhost:8090/api/health`
