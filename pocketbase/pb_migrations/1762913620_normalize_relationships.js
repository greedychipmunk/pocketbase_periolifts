/// <reference path="../pb_data/types.d.ts" />

/**
 * Normalize Relationships Migration
 * 
 * This migration normalizes relationship fields across collections.
 * The original migration had an error using `addField()` which doesn't exist.
 * 
 * Correct approach: Use collection.schema.push() to add new fields.
 * 
 * NOTE: This is a template migration. Customize based on your specific needs.
 */

migrate((app) => {
  // Example: Adding or modifying relationship fields
  // Uncomment and customize as needed
  
  /*
  // Example 1: Add a new relation field to exercises collection
  const exercises = app.findCollectionByNameOrId("exercises");
  
  // Correct way to add a field - use schema.push()
  exercises.schema.push({
    "name": "related_exercises",
    "type": "relation",
    "required": false,
    "presentable": false,
    "options": {
      "collectionId": exercises.id,
      "cascadeDelete": false,
      "minSelect": null,
      "maxSelect": null,
      "displayFields": ["name"]
    }
  });
  
  return app.save(exercises);
  */
  
  /*
  // Example 2: Modify existing relationship field
  const workouts = app.findCollectionByNameOrId("workouts");
  
  // Find the field in the schema
  const userField = workouts.schema.find(f => f.name === "user_id");
  if (userField) {
    // Update the field options
    userField.options = {
      ...userField.options,
      "cascadeDelete": true
    };
  }
  
  app.save(workouts);
  */
  
  // If you don't need to make any changes, just return without doing anything
  // This allows the migration to run successfully without errors
  return;
  
}, (app) => {
  // Rollback migration
  // Add rollback logic here if needed
  
  /*
  // Example rollback: Remove added field
  const exercises = app.findCollectionByNameOrId("exercises");
  exercises.schema = exercises.schema.filter(f => f.name !== "related_exercises");
  app.save(exercises);
  */
  
  return;
});
