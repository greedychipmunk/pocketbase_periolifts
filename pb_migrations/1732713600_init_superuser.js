/// <reference path="../pb_data/types.d.ts" />

// Initial superuser/admin setup migration
// Based on: https://pocketbase.io/docs/js-migrations/#creating-initial-superuser
//
// NOTE: This migration documents the admin credentials that should be used.
// Admin creation in PocketBase v0.23+ should be done via:
//   1. The admin panel UI on first access (http://localhost:8090/_/)
//   2. The PocketBase CLI: `pocketbase superuser upsert <email> <password>`
//   3. A pb_hooks script (not a migration)
//
// Credentials are read from environment variables:
//   - POCKETBASE_ADMIN_EMAIL (default: admin@example.com)
//   - POCKETBASE_ADMIN_PASSWORD (default: admin1234567890)

migrate((app) => {
  const email = $os.getenv("POCKETBASE_ADMIN_EMAIL") || "admin@example.com"
  const password = $os.getenv("POCKETBASE_ADMIN_PASSWORD") || "admin1234567890"

  console.log("=" .repeat(70))
  console.log("INITIAL ADMIN SETUP REQUIRED")
  console.log("=" .repeat(70))
  console.log("Email:", email)
  console.log("")
  console.log("To create the admin account, use one of these methods:")
  console.log("  1. Access http://localhost:8090/_/ and create via UI")
  console.log("  2. Run: docker exec <pocketbase_container> ./pocketbase superuser \\")
  console.log("         upsert", email, password)
  console.log("=" .repeat(70))

  // Migration completes successfully
  // Actual admin creation must be done outside of JS migrations
  return null
}, (app) => {
  // Down migration - for safety, we don't provide admin deletion
  return null
})
