/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  const collection = new Collection({
    "id": "",
    "name": "workout_history",
    "type": "base",
    "system": false,
    "schema": [
      {
        "name": "user_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "users",
          "cascadeDelete": false,
          "minSelect": null,
          "maxSelect": 1,
          "displayFields": ["name"]
        }
      },
      {
        "name": "workout_session_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "workout_sessions",
          "cascadeDelete": false,
          "minSelect": null,
          "maxSelect": 1,
          "displayFields": []
        }
      },
      {
        "name": "workout_name",
        "type": "text",
        "required": true,
        "options": {}
      },
      {
        "name": "completed_at",
        "type": "date",
        "required": true,
        "options": {}
      },
      {
        "name": "duration",
        "type": "number",
        "required": false,
        "options": {}
      },
      {
        "name": "exercises_completed",
        "type": "number",
        "required": false,
        "options": {}
      },
      {
        "name": "total_sets",
        "type": "number",
        "required": false,
        "options": {}
      },
      {
        "name": "total_reps",
        "type": "number",
        "required": false,
        "options": {}
      },
      {
        "name": "total_weight",
        "type": "number",
        "required": false,
        "options": {}
      },
      {
        "name": "notes",
        "type": "text",
        "required": false,
        "options": {}
      },
      {
        "name": "performance_data",
        "type": "json",
        "required": false,
        "options": {}
      }
    ],
    "listRule": "",
    "viewRule": "",
    "createRule": "",
    "updateRule": "",
    "deleteRule": ""
  })

  return app.save(collection)
}, (app) => {
  // Down migration - remove workout_history collection
  const collection = app.findCollectionByNameOrId("workout_history")
  return app.delete(collection)
})