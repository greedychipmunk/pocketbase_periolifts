# Collection Creation Fix - Summary

## Problem Solved
Fixed the collection creation error that occurred when running `docker compose up`:
```
Failed to create collection 'exercises': {"data":{"deleteRule":{"code":"validation_invalid_rule","message":"Invalid rule. Raw error: invalid left operand \"user_id\" - unknown field \"user_id\"."}
```

## Root Cause
PocketBase v0.23.0+ requires actual collection IDs (not names) when defining relation fields. The original script used `"collectionId": "users"` which worked in older versions but fails in v0.23.0+.

## Solution Implemented

### Technical Changes
1. **Dynamic Collection ID Fetching**
   - Added `get_collection_id()` function that queries the PocketBase API
   - Uses `jq` for JSON parsing if available, falls back to grep/sed
   - Extracts collection IDs reliably from API responses

2. **Dependency-Ordered Creation**
   - Collections are created in the correct order:
     1. users (no dependencies)
     2. exercises, workouts, workout_plans (depend on users)
     3. workout_sessions (depends on workouts and users)
     4. workout_history (depends on users and workout_sessions)
   - After creating each collection, its ID is fetched and stored
   - IDs are validated before creating dependent collections

3. **ID Substitution in Relations**
   - Collection functions now accept collection IDs as parameters
   - Bash variable substitution injects actual IDs into JSON templates
   - Example: `"collectionId": "$users_id"` becomes `"collectionId": "abc123xyz"`

4. **Conditional Debug Logging**
   - Debug mode controlled by `DEBUG=1` environment variable
   - Helps troubleshoot issues without cluttering normal output
   - Logs API responses, token info, and collection IDs

### Files Modified
- `scripts/init-collections-curl.sh` - Main fix implementation
- `scripts/TESTING_COLLECTIONS.md` - Comprehensive testing guide
- `scripts/README.md` - Updated documentation

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
📄 Creating collection: exercises
✅ Collection 'exercises' created successfully
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
