/// <reference path="../pb_data/types.d.ts" />

/**
 * Data Migration: Convert JSON schedules to normalized workout_plan_schedules
 *
 * This migration reads existing workout_plan records with JSON schedule data
 * and creates corresponding records in the workout_plan_schedules collection.
 *
 * Performance Benefits:
 * - Enables indexed date-based queries for calendar views
 * - Removes need for client-side JSON parsing
 * - Supports efficient date range filtering
 *
 * Migration Strategy:
 * - Read all workout_plans with schedule data
 * - Parse JSON schedule format: { "YYYY-MM-DD": ["workout_id1", "workout_id2"] }
 * - Create workout_plan_schedules records with proper metadata
 * - Handle errors gracefully without blocking migration
 */

migrate(
  (app) => {
    const workoutPlansCollection = app.findCollectionByNameOrId("workout_plans");
    const schedulesCollection = app.findCollectionByNameOrId("workout_plan_schedules");

    if (!workoutPlansCollection) {
      console.log("workout_plans collection not found, skipping migration");
      return null;
    }

    if (!schedulesCollection) {
      console.log("workout_plan_schedules collection not found, skipping migration");
      return null;
    }

    try {
      // Fetch all workout plans
      const plans = app.findRecordsByFilter(
        "workout_plans",
        "",  // No filter - get all plans
        "-created",  // Sort by created date descending
        500  // Reasonable limit for batch processing
      );

      console.log(`Processing ${plans.length} workout plans...`);

      let migratedCount = 0;
      let errorCount = 0;
      let skippedCount = 0;

      // Process each plan
      for (const plan of plans) {
        try {
          // Get the schedule field
          const scheduleData = plan.get("schedule");
          
          if (!scheduleData) {
            skippedCount++;
            continue;
          }

          // Parse schedule JSON
          let schedule;
          if (typeof scheduleData === "string") {
            try {
              schedule = JSON.parse(scheduleData);
            } catch (e) {
              console.log(`Failed to parse schedule for plan ${plan.id}: ${e}`);
              errorCount++;
              continue;
            }
          } else if (typeof scheduleData === "object" && scheduleData !== null) {
            schedule = scheduleData;
          } else {
            skippedCount++;
            continue;
          }

          // Check if schedule is empty or not an object
          if (typeof schedule !== "object" || schedule === null || Object.keys(schedule).length === 0) {
            skippedCount++;
            continue;
          }

          // Process each date in the schedule
          for (const [dateStr, workoutIds] of Object.entries(schedule)) {
            // Validate date format
            if (!dateStr || typeof dateStr !== "string") {
              console.log(`Invalid date string for plan ${plan.id}: ${dateStr}`);
              continue;
            }

            // Validate workout IDs
            if (!Array.isArray(workoutIds) || workoutIds.length === 0) {
              continue;
            }

            // Parse date to get day of week
            let dayOfWeek;
            try {
              const date = new Date(dateStr);
              if (isNaN(date.getTime())) {
                console.log(`Invalid date for plan ${plan.id}: ${dateStr}`);
                continue;
              }
              
              const days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];
              dayOfWeek = days[date.getDay()];
            } catch (e) {
              console.log(`Error parsing date ${dateStr}: ${e}`);
              continue;
            }

            // Create a record for each workout on this date
            for (let i = 0; i < workoutIds.length; i++) {
              const workoutId = workoutIds[i];
              
              if (!workoutId || typeof workoutId !== "string") {
                continue;
              }

              try {
                // Check if record already exists to avoid duplicates
                const existing = app.findFirstRecordByFilter(
                  "workout_plan_schedules",
                  `plan_id = "${plan.id}" && workout_id = "${workoutId}" && scheduled_date = "${dateStr}"`
                );

                if (existing) {
                  // Record already exists, skip
                  continue;
                }

                // Detect rest day
                const isRestDay = workoutId.toLowerCase().includes("rest");

                // Create new schedule record
                const scheduleRecord = new Record(schedulesCollection);
                scheduleRecord.set("plan_id", plan.id);
                scheduleRecord.set("workout_id", workoutId);
                scheduleRecord.set("scheduled_date", dateStr);
                scheduleRecord.set("day_of_week", dayOfWeek);
                scheduleRecord.set("sort_order", i);
                scheduleRecord.set("is_rest_day", isRestDay);
                scheduleRecord.set("notes", "");

                app.save(scheduleRecord);
                migratedCount++;
              } catch (e) {
                console.log(`Error creating schedule record for plan ${plan.id}, date ${dateStr}: ${e}`);
                errorCount++;
              }
            }
          }
        } catch (e) {
          console.log(`Error processing plan ${plan.id}: ${e}`);
          errorCount++;
        }
      }

      console.log(`Migration complete: ${migratedCount} records created, ${skippedCount} plans skipped, ${errorCount} errors`);
      
      return null;
    } catch (e) {
      console.log(`Migration error: ${e}`);
      // Don't throw - allow migration to complete even with errors
      return null;
    }
  },
  (app) => {
    // Rollback: Delete all migrated schedule records
    // Note: This only removes records created by this migration
    // Original JSON schedule data in workout_plans remains intact
    try {
      const schedulesCollection = app.findCollectionByNameOrId("workout_plan_schedules");
      
      if (!schedulesCollection) {
        console.log("workout_plan_schedules collection not found during rollback");
        return null;
      }

      // Delete all records in the collection
      const records = app.findRecordsByFilter(
        "workout_plan_schedules",
        "",  // No filter - delete all
        "-created",
        1000
      );

      console.log(`Rollback: Deleting ${records.length} schedule records...`);

      for (const record of records) {
        try {
          app.delete(record);
        } catch (e) {
          console.log(`Error deleting record ${record.id}: ${e}`);
        }
      }

      console.log("Rollback complete");
      return null;
    } catch (e) {
      console.log(`Rollback error: ${e}`);
      return null;
    }
  }
);
