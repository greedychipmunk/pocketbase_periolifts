/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  const collection = new Collection({
    "id": "",
    "name": "exercises",
    "type": "base",
    "system": false,
    "schema": [
      {
        "name": "name",
        "type": "text",
        "required": true,
        "options": {}
      },
      {
        "name": "category",
        "type": "text",
        "required": true,
        "options": {}
      },
      {
        "name": "description",
        "type": "text",
        "required": true,
        "options": {}
      },
      {
        "name": "muscle_groups",
        "type": "json",
        "required": true,
        "options": {}
      },
      {
        "name": "image_url",
        "type": "url",
        "required": false,
        "options": {}
      },
      {
        "name": "video_url",
        "type": "url",
        "required": false,
        "options": {}
      },
      {
        "name": "is_custom",
        "type": "bool",
        "required": true,
        "options": {}
      },
      {
        "name": "user_id",
        "type": "relation",
        "required": false,
        "options": {
          "collectionId": "",
          "cascadeDelete": false,
          "minSelect": null,
          "maxSelect": 1,
          "displayFields": ["id"]
        }
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
  // Down migration - remove exercises collection
  const collection = app.findCollectionByNameOrId("exercises")
  return app.delete(collection)
})