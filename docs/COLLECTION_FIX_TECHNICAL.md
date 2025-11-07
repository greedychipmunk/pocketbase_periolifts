# Collection Creation Fix - Technical Details

## The Problem Visualized

### Before the Fix (Single API Call)

```
┌─────────────────────────────────────────────────────┐
│ POST /api/collections                               │
├─────────────────────────────────────────────────────┤
│ {                                                   │
│   "name": "exercises",                              │
│   "type": "base",                                   │
│   "schema": [                                       │
│     {"name": "is_custom", "type": "bool"},          │
│     {"name": "user_id", "type": "relation"}         │
│   ],                                                │
│   "listRule": "is_custom = false || user_id = ..." │  ← Rules reference fields
│ }                                                   │
└─────────────────────────────────────────────────────┘
                    ↓
            [PocketBase Processing]
                    ↓
┌─────────────────────────────────────────────────────┐
│ Step 1: Validate Rules                              │
│   ❌ Error: Field "is_custom" not found            │
│   ❌ Error: Field "user_id" not found              │
│                                                     │
│ (Rules are validated before schema is created)     │
└─────────────────────────────────────────────────────┘
```

### After the Fix (Two API Calls)

```
┌─────────────────────────────────────────────────────┐
│ STEP 1: POST /api/collections                       │
├─────────────────────────────────────────────────────┤
│ {                                                   │
│   "name": "exercises",                              │
│   "type": "base",                                   │
│   "schema": [                                       │
│     {"name": "is_custom", "type": "bool"},          │
│     {"name": "user_id", "type": "relation"}         │
│   ]                                                 │
│   // NO RULES                                       │
│ }                                                   │
└─────────────────────────────────────────────────────┘
                    ↓
            [PocketBase Processing]
                    ↓
┌─────────────────────────────────────────────────────┐
│ ✅ Collection created with fields:                 │
│   - is_custom (bool)                                │
│   - user_id (relation)                              │
│                                                     │
│ Returns: { "id": "abc123xyz", ... }                 │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ STEP 2: PATCH /api/collections/abc123xyz            │
├─────────────────────────────────────────────────────┤
│ {                                                   │
│   "listRule": "is_custom = false || user_id = ...", │
│   "viewRule": "is_custom = false || user_id = ...", │
│   "createRule": "@request.auth.id != \"\"",         │
│   "updateRule": "user_id = @request.auth.id",       │
│   "deleteRule": "user_id = @request.auth.id"        │
│ }                                                   │
└─────────────────────────────────────────────────────┘
                    ↓
            [PocketBase Processing]
                    ↓
┌─────────────────────────────────────────────────────┐
│ ✅ Rules validated successfully                    │
│   (Fields is_custom and user_id exist)              │
│                                                     │
│ ✅ Collection updated with rules                   │
└─────────────────────────────────────────────────────┘
```

## Code Changes Summary

### Shell Script Changes

```bash
# Before: Single function for collection
create_exercises_collection() {
    cat << EOF
{
  "name": "exercises",
  "schema": [...],
  "listRule": "...",
  "viewRule": "..."
}
EOF
}

# After: Separate functions for schema and rules
create_exercises_collection_schema() {
    cat << EOF
{
  "name": "exercises",
  "schema": [...]
  # NO RULES
}
EOF
}

create_exercises_collection_rules() {
    cat << EOF
{
  "listRule": "...",
  "viewRule": "..."
  # NO SCHEMA
}
EOF
}
```

### Dart Script Changes

```dart
// Before: Single method call
await pb.collections.create(
  body: collectionConfig.toJson(), // Includes schema AND rules
);

// After: Two method calls
// Step 1: Create with schema only
final collection = await pb.collections.create(
  body: collectionConfig.toJson(includeRules: false),
);

// Step 2: Update with rules
await pb.collections.update(
  collection.id,
  body: collectionConfig.toRulesJson(),
);
```

## Benefits

1. **Eliminates Validation Errors**: Rules are only validated after fields exist
2. **Works with PocketBase v0.23.0+**: Compatible with latest version
3. **Backward Compatible**: Existing collections are not affected
4. **Clear Separation**: Schema and rules are independent
5. **Better Debugging**: Separate steps make errors easier to diagnose

## Testing

All 35 tests passed:
- ✅ Script syntax validation
- ✅ Function definitions
- ✅ Two-step creation pattern
- ✅ JSON structure validation (schema has no rules, rules have no schema)
- ✅ Collection ID substitution
- ✅ Dependency ordering

## Files Changed

1. `scripts/init-collections-curl.sh` - Shell script implementation
2. `scripts/init_collections.dart` - Dart script implementation
3. `COLLECTION_FIX_SUMMARY.md` - User-facing documentation
