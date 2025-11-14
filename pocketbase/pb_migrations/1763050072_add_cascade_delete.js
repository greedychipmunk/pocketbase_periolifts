/// <reference path="../pb_data/types.d.ts" />
migrate(
  (app) => {
    // Add validation rule to prevent workouts without exercises
    const workouts = app.findCollectionByNameOrId("workouts");

    workouts.createRule = `
    @request.auth.id != "" && 
    @request.data.exercises != null &&
    @request.data.exercises != "[]"
  `;

    // Note: Cascade delete not needed for workout_exercises collection
    // as exercises are stored as JSON within the workout record itself
  },
  (app) => {
    // Rollback: Remove validation rule
    const workouts = app.findCollectionByNameOrId("workouts");
    workouts.createRule = `@request.auth.id != ""`;
  }
);
