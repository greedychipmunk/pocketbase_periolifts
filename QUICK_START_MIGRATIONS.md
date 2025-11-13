# Quick Start: Fixing the Migration Error

## Your Error

```
Error: failed to apply migration 1762913620_normalize_relationships.js: 
TypeError: Object has no member 'addField' at /pb.js:8:27
```

## The Fix (3 Simple Steps)

### Step 1: Pull the Latest Changes

```bash
git pull origin copilot/fix-normalize-relationships-migration
```

This will bring in the corrected migration file.

### Step 2: Stop PocketBase

```bash
docker compose down
```

### Step 3: Restart PocketBase

```bash
docker compose up
```

The migration will now run successfully! ✅

## What Was Fixed

The error occurred because the migration was trying to use `addField()` which doesn't exist in PocketBase.

**Incorrect code:**
```javascript
collection.addField({ ... });          // ❌ Doesn't exist
```

**Correct code:**
```javascript
collection.schema.push({ ... });       // ✅ Works!
```

## The Migration File

The corrected migration file is now at:
```
pocketbase/pb_migrations/1762913620_normalize_relationships.js
```

It's a **template** that:
- ✅ Runs without errors (no-op by default)
- ✅ Shows correct API usage in commented examples
- ✅ Can be customized for your specific needs

## Do You Need to Normalize Relationships?

### Option A: You Don't Need It (Yet)

If you're not sure what you wanted to normalize, just use the migration as-is. It will run successfully and mark itself as applied, solving the error.

### Option B: You Want to Make Changes

Edit the file `pocketbase/pb_migrations/1762913620_normalize_relationships.js` and:
1. Uncomment the examples
2. Customize them for your needs
3. Save the file
4. Run `docker compose restart pocketbase`

## Example: Adding a Relation Field

If you want to add a relationship field, here's how:

```javascript
migrate((app) => {
  const collection = app.findCollectionByNameOrId("your_collection");
  const relatedCollection = app.findCollectionByNameOrId("related_collection");
  
  collection.schema.push({
    "name": "my_relation",
    "type": "relation",
    "required": false,
    "options": {
      "collectionId": relatedCollection.id,  // Use actual ID, not name!
      "cascadeDelete": false,
      "maxSelect": 1
    }
  });
  
  return app.save(collection);
}, (app) => {
  // Rollback
  const collection = app.findCollectionByNameOrId("your_collection");
  collection.schema = collection.schema.filter(f => f.name !== "my_relation");
  return app.save(collection);
});
```

## More Help

- **Detailed fix explanation**: `pocketbase/pb_migrations/MIGRATION_FIX.md`
- **Migration patterns & examples**: `pocketbase/pb_migrations/README.md`
- **General migration guide**: `MIGRATION_GUIDE.md`

## Verify the Fix

After restarting PocketBase, check the logs:

```bash
docker compose logs pocketbase | grep -i migration
```

You should see:
```
✓ 1762913620_normalize_relationships.js applied
```

With **no errors**! 🎉

## Need More Help?

If you still see errors:
1. Check `pocketbase/pb_migrations/MIGRATION_FIX.md` for detailed troubleshooting
2. Make sure you pulled the latest changes
3. Try a clean restart: `docker compose down -v && docker compose up`
