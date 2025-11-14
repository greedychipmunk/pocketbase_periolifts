/// <reference path="../pb_data/types.d.ts" />
migrate(
  (app) => {
    // add up queries...
    const workoutHistory = app.findCollectionByNameOrId("workout_history");

    // User + completion date for history views
    workoutHistory.addIndex({
      name: "idx_history_user_completed",
      fields: ["user", "completed_at"],
      unique: false,
    });

    const workoutSessions = app.findCollectionByNameOrId("workout_sessions");

    // User + status for active session queries
    workoutSessions.addIndex({
      name: "idx_sessions_user_status",
      fields: ["user", "is_completed"],
      unique: false,
    });
  },
  (app) => {
    // add down queries...
  }
);
