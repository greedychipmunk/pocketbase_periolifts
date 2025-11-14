/// <reference path="../pb_data/types.d.ts" />
migrate(
  (app) => {
    // add up queries...
    const workouts = app.findCollectionByNameOrId("workouts");

    workouts.beforeCreate = `
    // Validate that all exercise IDs exist
    const exerciseData = JSON.parse($request.data.exercises || "[]");
    for (const exercise of exerciseData) {
      if (!$app.findRecordById("exercises", exercise.exercise_id)) {
        throw new ValidationError("exercises", "Invalid exercise ID: " + exercise.exercise_id);
      }
    }
  `;
  },
  (app) => {
    // add down queries...
  }
);
