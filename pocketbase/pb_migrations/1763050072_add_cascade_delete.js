/// <reference path="../pb_data/types.d.ts" />
migrate(
  (app) => {
    // add up queries...
    const workouts = app.findCollectionByNameOrId("workouts");

    // Add validation rule to prevent workouts without exercises
    workouts.createRule = `
    @request.auth.id != "" && 
    @request.data.exercises != null &&
    @request.data.exercises != "[]"
  `;

    // Add cascade delete for workout_exercises when workout is deleted
    workouts.afterDelete = `
    // Delete associated workout_exercises records
    const workoutExercises = $app.findRecordsByFilter(
      "workout_exercises", 
      \`workout = "\${record.id}"\`
    );
    workoutExercises.forEach(we => $app.deleteRecord(we));
  `;
  },
  (app) => {
    // add down queries...
  }
);
