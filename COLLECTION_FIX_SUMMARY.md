# Collection Creation Fix - Summary

## Problem Solved
Fixed the collection creation error that occurred when running `docker compose up`:
```
Failed to update rules for 'exercises': {"data":{"deleteRule":{"code":"validation_invalid_rule","message":"Invalid rule. Raw error: invalid left operand \"user_id\" - unknown field \"user_id\"."},"listRule":{"code":"validation_invalid_rule","message":"Invalid rule. Raw error: invalid left operand \"is_custom\" - unknown field \"is_custom\"."},"updateRule":{"code":"validation_invalid_rule","message":"Invalid rule. Raw error: invalid left operand \"user_id\" - unknown field \"user_id\"."},"viewRule":{"code":"validation_invalid_rule","message":"Invalid rule. Raw error: invalid left operand \"is_custom\" - unknown field \"is_custom\"."}},"message":"Failed to update collection.","status":400}
```

## Root Cause

There were TWO separate issues that both needed to be fixed:

### Issue 1: Rule Validation Timing (Previously Fixed in Shell Script)
PocketBase validates API rules (listRule, viewRule, createRule, updateRule, deleteRule) against the collection schema **during** the collection creation API call. However, this validation occurs **before** the schema fields are actually created, causing a chicken-and-egg problem where rules reference fields that don't exist yet during the validation phase.

**Solution**: Separate collection creation into two steps - first create the schema, then update with rules.

### Issue 2: Collection Names vs Collection IDs (Fixed in this update)
The Dart initialization script (`scripts/init_collections.dart`) was using collection **names** (e.g., `'users'`, `'workouts'`) instead of collection **IDs** (UUIDs) when defining relation fields. PocketBase requires actual collection IDs for relation field validation.

When relation fields are defined with collection names instead of IDs:
- The relation field is not properly created in the schema
- When rules are applied in step 2, PocketBase doesn't recognize the field (e.g., `user_id`) as valid
- This causes errors like "invalid left operand 'user_id' - unknown field 'user_id'"

**Example of the problem**:
```dart
// INCORRECT - Using collection name
FieldSchema(
  name: 'user_id',
  type: 'relation',
  options: {'collectionId': 'users'},  // ❌ Should be UUID, not name
),
```

**Example of the fix**:
```dart
// CORRECT - Using actual collection ID
FieldSchema(
  name: 'user_id',
  type: 'relation',
  options: {'collectionId': usersId},  // ✅ usersId is the actual UUID
),
```

**Note**: The shell script (`scripts/init-collections-curl.sh`) was already correctly handling this by fetching collection IDs and using them. However, the Dart script had hardcoded collection names and needed to be updated to match the shell script's approach.

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

**Previous State** (from earlier fix):
1. Modified `CollectionSchema.toJson()` Method
   - Added optional parameter `includeRules` (default: true for backward compatibility)
   - When `includeRules = false`, returns schema without validation rules
   - When `includeRules = true`, returns complete schema with rules

2. New Method: `CollectionSchema.toRulesJson()`
   - Returns only the validation rules
   - Used for the update step

3. Updated `createCollection()` Method
   - Step 1: Create collection with `toJson(includeRules: false)`
   - Step 2: Update collection with `toRulesJson()`
   - Both steps include proper logging

**New Changes** (this fix):
1. **Converted Static Collection Definitions to Factory Functions**
   - Changed from: `final collections = <String, CollectionSchema>{...}`
   - Changed to: Individual factory functions that accept collection IDs as parameters
   - Functions: `createUsersCollection()`, `createExercisesCollection(String usersId)`, etc.
   - This allows dynamic resolution of collection IDs instead of hardcoded names

2. **Updated `createCollection()` Method to Return Collection ID**
   - Changed return type from `Future<bool>` to `Future<String?>`
   - Now returns the created collection's ID for use in dependent collections
   - Returns `null` on failure

3. **Refactored `initializeCollections()` Method**
   - Added `collectionIds` map to track created collection IDs
   - Created helper function `ensureCollection()` to handle creation or ID retrieval
   - Implements dependency-ordered creation:
     1. Users (no dependencies)
     2. Exercises, Workouts, Workout Plans (depend on Users)
     3. Workout Sessions (depend on Workouts and Users)
     4. Workout History (depend on Users and Workout Sessions)
   - Each collection receives the actual IDs of its dependencies
   - Handles existing collections by retrieving their IDs from the API

4. **Fixed Relation Field Definitions**
   - Before: `options: {'collectionId': 'users'}` (hardcoded name ❌)
   - After: `options: {'collectionId': usersId}` (dynamic ID ✅)
   - Applied to all relation fields across all collections

2. **New Method: `CollectionSchema.toRulesJson()`**
   - Returns only the validation rules
   - Used for the update step

3. **Updated `createCollection()` Method**
   - Step 1: Create collection with `toJson(includeRules: false)`
   - Step 2: Update collection with `toRulesJson()`
   - Both steps include proper logging

### Files Modified
- `scripts/init-collections-curl.sh` - Shell script implementation (already fixed)
- `scripts/init_collections.dart` - **Dart script implementation (fixed in this update)**
- `COLLECTION_FIX_SUMMARY.md` - Updated documentation

### Key Benefits
1. **Eliminates validation errors** - Rules are only validated after fields exist
2. **Proper relation fields** - Uses actual collection IDs instead of names
3. **Works with all PocketBase versions** - Compatible with v0.23.0+
4. **Maintains backward compatibility** - Existing collections are not affected
5. **Clear separation of concerns** - Schema and rules are independent
6. **Dependency-ordered creation** - Collections created in the correct order
7. **Better error messages** - Separate steps make debugging easier

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
