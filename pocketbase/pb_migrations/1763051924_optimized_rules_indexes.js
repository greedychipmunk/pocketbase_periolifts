/// <reference path="../pb_data/types.d.ts" />
migrate(
  (app) => {
    // add up queries...
    // Optimized rules using indexes
    migrate((app) => {
      const workouts = app.findCollectionByNameOrId("workouts");

      // Use indexed field for better performance
      workouts.listRule = "user = @request.auth.id";
      workouts.viewRule = "user = @request.auth.id";
      workouts.updateRule = "user = @request.auth.id";
      workouts.deleteRule = "user = @request.auth.id";

      // Add compound rule for shared workouts (future feature)
      workouts.listRule = `
    user = @request.auth.id || 
    (@request.auth.collectionName = "users" && is_public = true)
  `;
    });
  },
  (app) => {
    // add down queries...
  }
);
