/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  // Get the test user
  const testEmail = $os.getenv('PB_TEST_EMAIL') || 'test@example.com'
  let testUser
  try {
    testUser = app.findAuthRecordByEmail("_pb_users_auth_", testEmail)
  } catch (e) {
    console.error("Test user not found. Please ensure test user is created first.")
    return null
  }

  // Get collections
  const workoutsCollection = app.findCollectionByNameOrId("workouts")
  const exercisesCollection = app.findCollectionByNameOrId("exercises")

  // Get exercise IDs by name for reference
  const getExerciseId = (name) => {
    try {
      const records = app.findRecordsByFilter(exercisesCollection.id, `name = "${name}"`, "-created", 1)
      return records.length > 0 ? records[0].id : null
    } catch (e) {
      return null
    }
  }

  // Get exercise IDs
  const pushUpsId = getExerciseId("Push-ups")
  const squatsId = getExerciseId("Squats")
  const plankId = getExerciseId("Plank")
  const lungesId = getExerciseId("Lunges")
  const jumpingJacksId = getExerciseId("Jumping Jacks")

  // Verify exercises exist
  if (!pushUpsId || !squatsId || !plankId || !lungesId || !jumpingJacksId) {
    console.error("Some test exercises not found. Please ensure exercises are seeded first.")
    return null
  }

  // Create test workouts
  const workouts = [
    {
      name: "Full Body Strength",
      description: "A comprehensive strength workout targeting all major muscle groups",
      estimated_duration: 45,
      exercises: [
        {
          exercise_id: pushUpsId,
          exercise_name: "Push-ups",
          sets: [
            { reps: 10, weight: 0, rest_time: 60 },
            { reps: 10, weight: 0, rest_time: 60 },
            { reps: 8, weight: 0, rest_time: 90 }
          ]
        },
        {
          exercise_id: squatsId,
          exercise_name: "Squats",
          sets: [
            { reps: 15, weight: 0, rest_time: 60 },
            { reps: 15, weight: 0, rest_time: 60 },
            { reps: 12, weight: 0, rest_time: 90 }
          ]
        },
        {
          exercise_id: lungesId,
          exercise_name: "Lunges",
          sets: [
            { reps: 12, weight: 0, rest_time: 60 },
            { reps: 12, weight: 0, rest_time: 60 },
            { reps: 10, weight: 0, rest_time: 90 }
          ]
        },
        {
          exercise_id: plankId,
          exercise_name: "Plank",
          sets: [
            { reps: 30, weight: 0, rest_time: 60, notes: "Hold for 30 seconds" },
            { reps: 30, weight: 0, rest_time: 60, notes: "Hold for 30 seconds" },
            { reps: 45, weight: 0, rest_time: 90, notes: "Hold for 45 seconds" }
          ]
        }
      ],
      user_id: testUser.id,
      is_completed: false,
      is_in_progress: false
    },
    {
      name: "Quick Cardio Blast",
      description: "High-intensity cardio workout to get your heart pumping",
      estimated_duration: 20,
      exercises: [
        {
          exercise_id: jumpingJacksId,
          exercise_name: "Jumping Jacks",
          sets: [
            { reps: 30, weight: 0, rest_time: 30 },
            { reps: 30, weight: 0, rest_time: 30 },
            { reps: 40, weight: 0, rest_time: 60 }
          ]
        },
        {
          exercise_id: pushUpsId,
          exercise_name: "Push-ups",
          sets: [
            { reps: 15, weight: 0, rest_time: 45 },
            { reps: 12, weight: 0, rest_time: 45 },
            { reps: 10, weight: 0, rest_time: 60 }
          ]
        },
        {
          exercise_id: squatsId,
          exercise_name: "Squats",
          sets: [
            { reps: 20, weight: 0, rest_time: 30 },
            { reps: 20, weight: 0, rest_time: 30 },
            { reps: 15, weight: 0, rest_time: 60 }
          ]
        }
      ],
      user_id: testUser.id,
      is_completed: false,
      is_in_progress: false
    },
    {
      name: "Core Focus",
      description: "Strengthen your core with this focused workout",
      estimated_duration: 30,
      exercises: [
        {
          exercise_id: plankId,
          exercise_name: "Plank",
          sets: [
            { reps: 45, weight: 0, rest_time: 60, notes: "Hold for 45 seconds" },
            { reps: 60, weight: 0, rest_time: 60, notes: "Hold for 60 seconds" },
            { reps: 45, weight: 0, rest_time: 60, notes: "Hold for 45 seconds" },
            { reps: 30, weight: 0, rest_time: 90, notes: "Hold for 30 seconds" }
          ]
        },
        {
          exercise_id: pushUpsId,
          exercise_name: "Push-ups",
          sets: [
            { reps: 12, weight: 0, rest_time: 60 },
            { reps: 10, weight: 0, rest_time: 60 },
            { reps: 8, weight: 0, rest_time: 60 }
          ]
        },
        {
          exercise_id: lungesId,
          exercise_name: "Lunges",
          sets: [
            { reps: 10, weight: 0, rest_time: 45 },
            { reps: 10, weight: 0, rest_time: 45 }
          ]
        }
      ],
      user_id: testUser.id,
      is_completed: false,
      is_in_progress: false
    },
    {
      name: "Beginner Friendly",
      description: "Perfect for those just starting their fitness journey",
      estimated_duration: 25,
      exercises: [
        {
          exercise_id: squatsId,
          exercise_name: "Squats",
          sets: [
            { reps: 10, weight: 0, rest_time: 60 },
            { reps: 10, weight: 0, rest_time: 60 }
          ]
        },
        {
          exercise_id: pushUpsId,
          exercise_name: "Push-ups",
          sets: [
            { reps: 5, weight: 0, rest_time: 90, notes: "Modified push-ups if needed" },
            { reps: 5, weight: 0, rest_time: 90, notes: "Modified push-ups if needed" },
            { reps: 5, weight: 0, rest_time: 90, notes: "Modified push-ups if needed" }
          ]
        },
        {
          exercise_id: plankId,
          exercise_name: "Plank",
          sets: [
            { reps: 20, weight: 0, rest_time: 90, notes: "Hold for 20 seconds" },
            { reps: 20, weight: 0, rest_time: 90, notes: "Hold for 20 seconds" }
          ]
        }
      ],
      user_id: testUser.id,
      is_completed: false,
      is_in_progress: false
    },
    {
      name: "Lower Body Power",
      description: "Build strength and power in your legs and glutes",
      estimated_duration: 40,
      exercises: [
        {
          exercise_id: squatsId,
          exercise_name: "Squats",
          sets: [
            { reps: 15, weight: 0, rest_time: 60 },
            { reps: 15, weight: 0, rest_time: 60 },
            { reps: 12, weight: 0, rest_time: 60 },
            { reps: 10, weight: 0, rest_time: 90 }
          ]
        },
        {
          exercise_id: lungesId,
          exercise_name: "Lunges",
          sets: [
            { reps: 12, weight: 0, rest_time: 60 },
            { reps: 12, weight: 0, rest_time: 60 },
            { reps: 10, weight: 0, rest_time: 60 },
            { reps: 10, weight: 0, rest_time: 90 }
          ]
        },
        {
          exercise_id: jumpingJacksId,
          exercise_name: "Jumping Jacks",
          sets: [
            { reps: 25, weight: 0, rest_time: 45 },
            { reps: 25, weight: 0, rest_time: 45 }
          ],
          notes: "Active recovery between strength exercises"
        }
      ],
      user_id: testUser.id,
      is_completed: false,
      is_in_progress: false
    }
  ]

  // Create workout records
  workouts.forEach(workoutData => {
    const workout = new Record(workoutsCollection)
    workout.set("name", workoutData.name)
    workout.set("description", workoutData.description)
    workout.set("estimated_duration", workoutData.estimated_duration)
    workout.set("exercises", workoutData.exercises)
    workout.set("user_id", workoutData.user_id)
    workout.set("is_completed", workoutData.is_completed)
    workout.set("is_in_progress", workoutData.is_in_progress)
    app.save(workout)
  })

  return null
}, (app) => {
  // Down migration - remove test workouts
  try {
    const testEmail = $os.getenv('PB_TEST_EMAIL') || 'test@example.com'
    const testUser = app.findAuthRecordByEmail("_pb_users_auth_", testEmail)
    const workoutsCollection = app.findCollectionByNameOrId("workouts")
    
    // Delete all workouts created for test user
    const workoutNames = [
      "Full Body Strength",
      "Quick Cardio Blast", 
      "Core Focus",
      "Beginner Friendly",
      "Lower Body Power"
    ]
    
    workoutNames.forEach(name => {
      try {
        const records = app.findRecordsByFilter(
          workoutsCollection.id, 
          `name = "${name}" && user_id = "${testUser.id}"`
        )
        records.forEach(record => app.delete(record))
      } catch (e) {
        // Skip if not found
      }
    })
  } catch (e) {
    // Ignore errors in down migration
    console.error("Error in down migration:", e.message)
  }
  
  return null
})
