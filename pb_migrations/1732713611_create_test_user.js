/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  // Create test user from environment configuration
  const users = app.findCollectionByNameOrId("_pb_users_auth_")
  const record = new Record(users)
  
  // Get credentials from environment variables with fallback values
  const testEmail = $os.getenv('PB_TEST_EMAIL') || 'test@example.com'
  const testPassword = $os.getenv('PB_TEST_PASSWORD') || 'test_password_123'
  
  // Set user credentials
  record.set("email", testEmail)
  record.set("password", testPassword)
  
  app.save(record)
}, (app) => {
  // Down migration - remove the test user
  try {
    const testEmail = $os.getenv('PB_TEST_EMAIL') || 'test@example.com'
    const record = app.findAuthRecordByEmail("_pb_users_auth_", testEmail)
    app.delete(record)
  } catch (e) {
    // Silent errors (probably already deleted)
  }
})
