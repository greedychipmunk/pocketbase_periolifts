/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  const collection = new Collection({
    "id": "",
    "name": "user_preferences",
    "type": "base",
    "system": false,
    "fields": [
      {
        "autogeneratePattern": "[a-z0-9]{15}",
        "hidden": false,
        "id": "text3208210256",
        "max": 15,
        "min": 15,
        "name": "id",
        "pattern": "^[a-z0-9]+$",
        "presentable": false,
        "primaryKey": true,
        "required": true,
        "system": true,
        "type": "text"
      },
      {
        "cascadeDelete": true,
        "collectionId": "_pb_users_auth_",
        "displayFields": ["name", "email"],
        "hidden": false,
        "id": "relation1579384326",
        "maxSelect": 1,
        "minSelect": null,
        "name": "user_id",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "relation"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text1579384327",
        "max": 255,
        "min": 0,
        "name": "username",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      },
      {
        "exceptDomains": null,
        "hidden": false,
        "id": "url1579384328",
        "name": "avatar_url",
        "onlyDomains": null,
        "presentable": false,
        "required": false,
        "system": false,
        "type": "url"
      },
      {
        "hidden": false,
        "id": "select1579384329",
        "maxSelect": 1,
        "name": "preferred_units",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "select",
        "values": ["metric", "imperial"]
      },
      {
        "hidden": false,
        "id": "select1579384330",
        "maxSelect": 1,
        "name": "preferred_theme",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "select",
        "values": ["light", "dark", "system"]
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text1579384331",
        "max": 255,
        "min": 0,
        "name": "timezone",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      },
      {
        "hidden": false,
        "id": "bool1579384332",
        "name": "onboarding_completed",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "bool"
      },
      {
        "hidden": false,
        "id": "json1579384333",
        "maxSize": 2000000,
        "name": "fitness_goals",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "json"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text1579384334",
        "max": 255,
        "min": 0,
        "name": "current_cycle_phase",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      },
      {
        "hidden": false,
        "id": "number1579384335",
        "max": null,
        "min": null,
        "name": "average_cycle_length",
        "noDecimal": false,
        "presentable": false,
        "required": false,
        "system": false,
        "type": "number"
      },
      {
        "hidden": false,
        "id": "date1579384336",
        "max": "",
        "min": "",
        "name": "birth_date",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "date"
      },
      {
        "hidden": false,
        "id": "number1579384337",
        "max": null,
        "min": null,
        "name": "height",
        "noDecimal": false,
        "presentable": false,
        "required": false,
        "system": false,
        "type": "number"
      },
      {
        "hidden": false,
        "id": "number1579384338",
        "max": null,
        "min": null,
        "name": "weight",
        "noDecimal": false,
        "presentable": false,
        "required": false,
        "system": false,
        "type": "number"
      },
      {
        "hidden": false,
        "id": "select1579384339",
        "maxSelect": 1,
        "name": "activity_level",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "select",
        "values": ["sedentary", "lightly_active", "moderately_active", "very_active", "extremely_active"]
      },
      {
        "hidden": false,
        "id": "bool1579384340",
        "name": "notifications_enabled",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "bool"
      },
      {
        "hidden": false,
        "id": "bool1579384341",
        "name": "workout_reminders_enabled",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "bool"
      },
      {
        "hidden": false,
        "id": "bool1579384342",
        "name": "period_reminders_enabled",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "bool"
      },
      {
        "hidden": false,
        "id": "select1579384343",
        "maxSelect": 1,
        "name": "subscription_status",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "select",
        "values": ["free", "premium"]
      },
      {
        "hidden": false,
        "id": "date1579384344",
        "max": "",
        "min": "",
        "name": "subscription_expires_at",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "date"
      },
      {
        "hidden": false,
        "id": "select1579384345",
        "maxSelect": 1,
        "name": "role",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "select",
        "values": ["user", "admin"]
      },
      {
        "hidden": false,
        "id": "bool1579384346",
        "name": "is_active",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "bool"
      },
      {
        "hidden": false,
        "id": "date1579384347",
        "max": "",
        "min": "",
        "name": "last_active_at",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "date"
      },
      {
        "hidden": false,
        "id": "autodate2990389176",
        "name": "created",
        "onCreate": true,
        "onUpdate": false,
        "presentable": false,
        "system": false,
        "type": "autodate"
      },
      {
        "hidden": false,
        "id": "autodate3332085495",
        "name": "updated",
        "onCreate": true,
        "onUpdate": true,
        "presentable": false,
        "system": false,
        "type": "autodate"
      }
    ],
    "listRule": "user_id = @request.auth.id",
    "viewRule": "user_id = @request.auth.id",
    "createRule": "@request.auth.id != \"\"",
    "updateRule": "user_id = @request.auth.id",
    "deleteRule": "user_id = @request.auth.id"
  })

  return app.save(collection)
}, (app) => {
  // Down migration - remove user_preferences collection
  const collection = app.findCollectionByNameOrId("user_preferences")
  return app.delete(collection)
})