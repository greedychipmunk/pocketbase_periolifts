/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  const collection = app.findCollectionByNameOrId("exercises")
  
  // Default exercises data
  const defaultExercises = [
    {
      "name": "Push-ups",
      "category": "strength",
      "description": "A bodyweight exercise that targets chest, shoulders, and triceps",
      "muscle_groups": ["chest", "triceps", "shoulders"],
      "is_custom": false,
      "user_id": null
    },
    {
      "name": "Squats",
      "category": "strength", 
      "description": "A compound exercise that targets quadriceps, glutes, and hamstrings",
      "muscle_groups": ["quadriceps", "glutes", "hamstrings"],
      "is_custom": false,
      "user_id": null
    },
    {
      "name": "Plank",
      "category": "core",
      "description": "An isometric core strengthening exercise",
      "muscle_groups": ["core", "shoulders"],
      "is_custom": false,
      "user_id": null
    },
    {
      "name": "Lunges",
      "category": "strength",
      "description": "A unilateral leg exercise targeting quadriceps, glutes, and stabilizers",
      "muscle_groups": ["quadriceps", "glutes", "hamstrings", "calves"],
      "is_custom": false,
      "user_id": null
    },
    {
      "name": "Burpees",
      "category": "cardio",
      "description": "A full-body exercise combining squat, push-up, and jump",
      "muscle_groups": ["full_body"],
      "is_custom": false,
      "user_id": null
    },
    {
      "name": "Mountain Climbers",
      "category": "cardio",
      "description": "A dynamic exercise that combines cardio and core strengthening",
      "muscle_groups": ["core", "shoulders", "legs"],
      "is_custom": false,
      "user_id": null
    },
    {
      "name": "Jumping Jacks",
      "category": "cardio",
      "description": "A simple cardiovascular exercise",
      "muscle_groups": ["full_body"],
      "is_custom": false,
      "user_id": null
    },
    {
      "name": "Bicycle Crunches",
      "category": "core",
      "description": "A core exercise targeting the obliques and rectus abdominis",
      "muscle_groups": ["core", "obliques"],
      "is_custom": false,
      "user_id": null
    },
    {
      "name": "Wall Sit",
      "category": "strength",
      "description": "An isometric exercise targeting quadriceps and glutes",
      "muscle_groups": ["quadriceps", "glutes"],
      "is_custom": false,
      "user_id": null
    },
    {
      "name": "High Knees",
      "category": "cardio",
      "description": "A cardio exercise that improves coordination and leg strength",
      "muscle_groups": ["legs", "core"],
      "is_custom": false,
      "user_id": null
    }
  ]

  // Create records for each default exercise
  defaultExercises.forEach(exerciseData => {
    const record = new Record(collection, exerciseData)
    app.save(record)
  })

  return null
}, (app) => {
  // Down migration - remove default exercises
  const collection = app.findCollectionByNameOrId("exercises")
  const records = app.findRecordsByFilter(collection.id, "is_custom = false && user_id = null")
  
  records.forEach(record => {
    app.delete(record)
  })
  
  return null
})