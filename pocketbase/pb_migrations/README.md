# PocketBase Migrations

This directory contains PocketBase migration files for database schema management.

## Migration File Naming Convention

Migration files use Unix timestamp prefixes for ordering:
```
<timestamp>_<description>.js
```

Example: `1762913620_normalize_relationships.js`

## Common Migration Patterns

### 1. Adding a New Field

```javascript
/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  const collection = app.findCollectionByNameOrId("your_collection");
  
  // Use collection.schema.push() to add a new field
  collection.schema.push({
    "name": "new_field",
    "type": "text",
    "required": false,
    "options": {
      "min": null,
      "max": null,
      "pattern": ""
    }
  });
  
  return app.save(collection);
}, (app) => {
  // Rollback: Remove the field
  const collection = app.findCollectionByNameOrId("your_collection");
  collection.schema = collection.schema.filter(f => f.name !== "new_field");
  return app.save(collection);
});
```

### 2. Adding a Relation Field

```javascript
migrate((app) => {
  const collection = app.findCollectionByNameOrId("your_collection");
  const relatedCollection = app.findCollectionByNameOrId("related_collection");
  
  // Use collection.schema.push() to add a relation field
  collection.schema.push({
    "name": "relation_field",
    "type": "relation",
    "required": false,
    "options": {
      "collectionId": relatedCollection.id, // Use actual collection ID
      "cascadeDelete": false,
      "minSelect": null,
      "maxSelect": 1,
      "displayFields": ["name"]
    }
  });
  
  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("your_collection");
  collection.schema = collection.schema.filter(f => f.name !== "relation_field");
  return app.save(collection);
});
```

### 3. Modifying an Existing Field

```javascript
migrate((app) => {
  const collection = app.findCollectionByNameOrId("your_collection");
  
  // Find and modify the field
  const field = collection.schema.find(f => f.name === "existing_field");
  if (field) {
    field.required = true;
    field.options.min = 1;
  }
  
  return app.save(collection);
}, (app) => {
  // Rollback: Restore original values
  const collection = app.findCollectionByNameOrId("your_collection");
  const field = collection.schema.find(f => f.name === "existing_field");
  if (field) {
    field.required = false;
    field.options.min = null;
  }
  return app.save(collection);
});
```

### 4. Creating a New Collection

```javascript
migrate((app) => {
  const collection = new Collection({
    "name": "new_collection",
    "type": "base",
    "schema": [
      {
        "name": "name",
        "type": "text",
        "required": true,
        "options": {
          "min": null,
          "max": null,
          "pattern": ""
        }
      }
    ],
    "listRule": "@request.auth.id != ''",
    "viewRule": "@request.auth.id != ''",
    "createRule": "@request.auth.id != ''",
    "updateRule": "@request.auth.id != ''",
    "deleteRule": "@request.auth.id != ''"
  });
  
  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("new_collection");
  return app.delete(collection);
});
```

## Common Errors and Solutions

### Error: "Object has no member 'addField'"

**Problem**: Using incorrect API method. The method `addField()` doesn't exist.

**Solution**: Use `collection.schema.push()` instead:

```javascript
// ❌ WRONG - addField() doesn't exist
collection.addField({ ... });
collection.schema.addField({ ... });

// ✅ CORRECT - Use schema.push()
collection.schema.push({ ... });
```

### Error: "Invalid relation collectionId"

**Problem**: Using collection name instead of collection ID.

**Solution**: Get the actual collection ID:

```javascript
// ❌ WRONG
options: {
  "collectionId": "users"  // Using name
}

// ✅ CORRECT
const users = app.findCollectionByNameOrId("users");
options: {
  "collectionId": users.id  // Using actual ID
}
```

### Error: "Migration already applied"

**Problem**: PocketBase tracks applied migrations and won't re-run them.

**Solution**: 
- Create a new migration file with a new timestamp
- Or reset the database (development only):
  ```bash
  docker compose down -v
  sudo rm -rf pocketbase/pb_data/*
  docker compose up
  ```

## Field Types Reference

Common field types in PocketBase:

- `text` - Text field
- `number` - Numeric field
- `bool` - Boolean field
- `email` - Email field with validation
- `url` - URL field with validation
- `date` - Date field
- `select` - Single select dropdown
- `relation` - Relationship to another collection
- `file` - File upload field
- `json` - JSON field

## Best Practices

1. **Never modify existing migration files** - Create new migrations instead
2. **Always provide rollback logic** - The second function in `migrate()`
3. **Test migrations locally first** - Use `docker compose restart pocketbase`
4. **Use descriptive migration names** - Makes it easier to understand what changed
5. **Document complex migrations** - Add comments explaining the "why"
6. **Keep migrations focused** - One logical change per migration
7. **Use collection IDs, not names** - For relation fields

## Testing Migrations

### Local Testing

```bash
# Restart PocketBase to apply migrations
docker compose restart pocketbase

# Check logs for errors
docker compose logs pocketbase

# Verify in admin UI
open http://localhost:8090/_/
```

### Reset Database (Development Only)

```bash
# Stop and remove all data
docker compose down -v
sudo rm -rf pocketbase/pb_data/*

# Start fresh - migrations run automatically
docker compose up
```

## Troubleshooting

### Check Migration Status

1. Open PocketBase Admin UI: http://localhost:8090/_/
2. Go to **Settings** → **Migrations**
3. View list of applied migrations

### View Migration Errors

```bash
docker compose logs pocketbase | grep -i migration
```

### Manual Migration Rollback

If you need to undo a migration:

1. Create a new migration that reverses the changes
2. Or use the PocketBase admin UI to manually modify collections

## Resources

- [PocketBase JavaScript Migrations Docs](https://pocketbase.io/docs/js-migrations/)
- [PocketBase Collections API](https://pocketbase.io/docs/api-collections/)
- Project Migration Guide: `../MIGRATION_GUIDE.md`

## Current Migrations

Document your migrations here for team reference:

| Timestamp | Description | Status |
|-----------|-------------|--------|
| 1762913620 | Normalize relationships | ✅ Fixed |

