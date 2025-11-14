/// <reference path="../pb_data/types.d.ts" />
migrate(
  (app) => {
    // add up queries...
    // Add full-text search indexes for exercises
    migrate((app) => {
      const exercises = app.findCollectionByNameOrId("exercises");

      exercises.addIndex({
        name: "idx_exercises_fulltext",
        fields: ["name", "description"],
        type: "fulltext",
      });
    });
  },
  (app) => {
    // add down queries...
  }
);
