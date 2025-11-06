# Verifying the Collection Creation Fix

This guide helps you verify that the collection creation fix is working correctly.

## Prerequisites

1. Docker and Docker Compose installed
2. `.env` file configured (copy from `.env.example`)
3. PocketBase superuser credentials set in `.env`

## Quick Verification

### 1. Clean Start (Recommended for Testing)

```bash
# Stop any running containers
docker compose down -v

# Remove PocketBase data (this will delete all data!)
rm -rf pocketbase/pb_data/*

# Start fresh
docker compose up
```

### 2. Watch for Success Messages

Look for these messages in the console output:

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

... (continues for all collections)

🎉 Collection initialization complete!
📊 Summary: 6 created, 0 skipped
```

### 3. Key Success Indicators

✅ **Each collection should show TWO success messages:**
   - One for creation (schema)
   - One for rules update

✅ **No error messages about "unknown field"**

❌ **Old behavior (if fix isn't working):**
   - Only ONE message per collection
   - Error messages like "invalid left operand 'user_id' - unknown field 'user_id'"

## Detailed Verification

### Verify in PocketBase Admin UI

1. Open browser to `http://localhost:8090/_/`
2. Log in with your superuser credentials
3. Click "Collections" in the left sidebar
4. Verify all 6 collections exist:
   - ✅ users
   - ✅ exercises
   - ✅ workouts
   - ✅ workout_plans
   - ✅ workout_sessions
   - ✅ workout_history

### Check Collection Schemas

For each collection, click on it and verify:

#### Exercises Collection
- ✅ Schema has fields: `name`, `category`, `description`, `muscle_groups`, `image_url`, `video_url`, `is_custom`, `user_id`
- ✅ Rules are set:
  - List rule: `is_custom = false || user_id = @request.auth.id`
  - View rule: `is_custom = false || user_id = @request.auth.id`
  - Create rule: `@request.auth.id != ""`
  - Update rule: `user_id = @request.auth.id`
  - Delete rule: `user_id = @request.auth.id`

#### Users Collection
- ✅ Type: "Auth" collection
- ✅ Has all user fields (name, username, avatar_url, etc.)
- ✅ Rules are set for user access control

### Test with Debug Mode

For more detailed logging:

```bash
DEBUG=1 docker compose up
```

This will show:
- Token information (first 20 characters)
- Collection IDs as they're created
- API response details
- Function execution flow

## Troubleshooting

### Error: "Superuser authentication failed"

**Solution:**
1. Visit `http://localhost:8090/_/` in your browser
2. Create a superuser account (one-time setup)
3. Update `.env` with the credentials:
   ```
   POCKETBASE_ADMIN_EMAIL=your-email@example.com
   POCKETBASE_ADMIN_PASSWORD=your-password
   ```
4. Restart: `docker compose down && docker compose up`

### Error: "Failed to create collection"

**Check:**
1. Is PocketBase running? `curl http://localhost:8090/api/health`
2. Are credentials correct in `.env`?
3. Enable debug mode: `DEBUG=1 docker compose up`

### Collections Already Exist

If collections already exist, the script will skip them:

```
⏭️  Collection 'users' already exists, skipping
⏭️  Collection 'exercises' already exists, skipping
```

**To recreate:**
```bash
docker compose down
rm -rf pocketbase/pb_data/*
docker compose up
```

### Verify Script Changes

Check that the fix is applied:

```bash
# Should show separate schema and rules functions
grep -c "collection_schema()" scripts/init-collections-curl.sh
# Expected output: 6 (one for each collection)

grep -c "collection_rules()" scripts/init-collections-curl.sh
# Expected output: 6 (one for each collection)

grep -c "update_collection_rules" scripts/init-collections-curl.sh
# Expected output: Multiple (function definition + calls)
```

## Manual API Testing

You can also test the fix manually using curl:

```bash
# 1. Get auth token
TOKEN=$(curl -s -X POST http://localhost:8090/api/collections/_superusers/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{"identity":"admin@example.com","password":"password"}' \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# 2. Create collection with schema only (no rules)
curl -X POST http://localhost:8090/api/collections \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "test_collection",
    "type": "base",
    "schema": [
      {"name": "test_field", "type": "text", "required": true}
    ]
  }'

# 3. Get collection ID
COLLECTION_ID=$(curl -s -X GET http://localhost:8090/api/collections \
  -H "Authorization: Bearer $TOKEN" \
  | grep -o '"id":"[^"]*","name":"test_collection"' | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

# 4. Update with rules
curl -X PATCH http://localhost:8090/api/collections/$COLLECTION_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "listRule": "test_field != \"\"",
    "viewRule": "test_field != \"\""
  }'
```

If steps 2 and 4 both succeed, the fix is working!

## Expected Behavior Summary

| Aspect | Expected Result |
|--------|----------------|
| Collection creation | ✅ Two-step process (create → update) |
| Error messages | ✅ No "unknown field" errors |
| Console output | ✅ Shows both creation and rules update |
| All 6 collections | ✅ Created successfully |
| Collection schemas | ✅ All fields present |
| Collection rules | ✅ All rules applied |
| Debug logs | ✅ Show collection IDs and tokens |

## Success Criteria

- ✅ No error messages during initialization
- ✅ All 6 collections created
- ✅ Each collection shows 2 success messages (create + update rules)
- ✅ PocketBase admin UI shows all collections with correct schemas
- ✅ Rules are properly set on all collections
- ✅ Script completes with "🎉 Collection initialization complete!"
