/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  // Set test user's verified column to true
  try {
    const testEmail = $os.getenv('PB_TEST_EMAIL') || 'test@example.com'
    const record = app.findAuthRecordByEmail("_pb_users_auth_", testEmail)
    
    // Set verified to true
    record.set("verified", true)
    
    app.save(record)
  } catch (e) {
    // Log error but don't fail migration if user doesn't exist
    console.error("Failed to verify test user:", e.message)
  }
}, (app) => {
  // Down migration - set verified back to false
  try {
    const testEmail = $os.getenv('PB_TEST_EMAIL') || 'test@example.com'
    const record = app.findAuthRecordByEmail("_pb_users_auth_", testEmail)
    
    // Set verified back to false
    record.set("verified", false)
    
    app.save(record)
  } catch (e) {
    // Silent errors (probably already deleted)
  }
})
