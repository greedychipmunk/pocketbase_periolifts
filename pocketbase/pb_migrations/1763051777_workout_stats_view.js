/// <reference path="../pb_data/types.d.ts" />

// Skip this migration - depends on workout_history table that doesn't exist yet
migrate((app) => {
  console.log("Skipping workout_stats_view migration - depends on missing tables")
  return null
}, (app) => {
  return null  
})
