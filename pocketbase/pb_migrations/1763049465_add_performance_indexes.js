/// <reference path="../pb_data/types.d.ts" />
migrate(
  (app) => {
    // add up queries...
    // User-based filtering indexes
    const collections = [
      "workouts",
      "workout_plans",
      "workout_sessions",
      "workout_history",
    ];

    collections.forEach((collectionName) => {
      const collection = app.findCollectionByNameOrId(collectionName);

      // Add index on user field for fast user filtering
      collection.addIndex({
        name: `idx_${collectionName}_user`,
        fields: ["user"],
        unique: false,
      });

      // Add index on created date for chronological queries
      collection.addIndex({
        name: `idx_${collectionName}_created`,
        fields: ["created"],
        unique: false,
      });
    });

    // Exercise-specific indexes
    const exercises = app.findCollectionByNameOrId("exercises");
    exercises.addIndex({
      name: "idx_exercises_category",
      fields: ["category"],
      unique: false,
    });

    exercises.addIndex({
      name: "idx_exercises_name_search",
      fields: ["name"],
      unique: false,
    });
  },
  (app) => {
    // add down queries...
  }
);
