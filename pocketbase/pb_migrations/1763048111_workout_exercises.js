/// <reference path="../pb_data/types.d.ts" />

// No-op migration - workout exercises are stored as JSON in the workouts collection
// This collection is not needed as exercises are embedded in workout records
migrate((app) => {
  // No changes needed - exercises are stored as JSON fields in workouts
}, (app) => {
  // No rollback needed
})