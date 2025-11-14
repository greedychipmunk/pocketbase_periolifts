/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  // Create initial superuser from environment configuration
  const superusers = app.findCollectionByNameOrId("_superusers")
  const record = new Record(superusers)
  
  // Set credentials from .env file
  record.set("email", "dcblackhouse@gmail.com")
  record.set("password", "5eMeW0KD051JqtpUxtgKYKiVmo6")
  
  app.save(record)
}, (app) => {
  // Down migration - remove the initial superuser
  try {
    const record = app.findAuthRecordByEmail("_superusers", "dcblackhouse@gmail.com")
    app.delete(record)
  } catch (e) {
    // Silent errors (probably already deleted)
  }
})