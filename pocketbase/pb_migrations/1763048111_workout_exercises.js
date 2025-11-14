/// <reference path="../pb_data/types.d.ts" />

// Skip this migration - problematic relation references
migrate((app) => {
  console.log("Skipping workout_exercises migration - will be recreated later")
  return null
}, (app) => {
  return null  
})