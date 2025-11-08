/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  // Create test exercises only - start simple
  const exercisesCollection = app.findCollectionByNameOrId("exercises")
  
  const exercises = [
    {
      name: "Push-ups",
      category: "strength",
      description: "A bodyweight exercise that targets chest, shoulders, and triceps",
      muscle_groups: ["chest", "triceps", "shoulders"]
    },
    {
      name: "Squats",
      category: "strength", 
      description: "A compound exercise that targets quadriceps, glutes, and hamstrings",
      muscle_groups: ["quadriceps", "glutes", "hamstrings"]
    },
    {
      name: "Plank",
      category: "core",
      description: "An isometric core strengthening exercise",
      muscle_groups: ["core", "shoulders"]
    },
    {
      name: "Lunges",
      category: "strength",
      description: "A unilateral leg exercise targeting quadriceps, glutes, and stabilizers",
      muscle_groups: ["quadriceps", "glutes", "hamstrings", "calves"]
    },
    {
      name: "Jumping Jacks",
      category: "cardio",
      description: "A simple cardiovascular exercise",
      muscle_groups: ["full_body"]
    }
  ]

  exercises.forEach(exerciseData => {
    const exercise = new Record(exercisesCollection)
    exercise.set("name", exerciseData.name)
    exercise.set("category", exerciseData.category)
    exercise.set("description", exerciseData.description)
    exercise.set("muscle_groups", exerciseData.muscle_groups)
    // Don't set is_custom since it's now optional and will default
    app.save(exercise)
  })

  return null
}, (app) => {
  // Down migration - remove test exercises
  try {
    const exercisesCollection = app.findCollectionByNameOrId("exercises")
    const exercises = ["Push-ups", "Squats", "Plank", "Lunges", "Jumping Jacks"]
    exercises.forEach(name => {
      try {
        const records = app.findRecordsByFilter(exercisesCollection.id, `name = "${name}"`)
        records.forEach(record => app.delete(record))
      } catch (e) {
        // Skip if not found
      }
    })
  } catch (e) {
    // Ignore errors in down migration
  }
  
  return null
})