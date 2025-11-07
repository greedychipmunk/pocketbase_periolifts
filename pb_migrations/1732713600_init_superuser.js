/// <reference path="../pb_data/types.d.ts" />

// Initial superuser/admin setup migration
// Based on: https://pocketbase.io/docs/js-migrations/#creating-initial-superuser
//
// This migration marks that superuser initialization is configured.
// The actual superuser creation happens automatically via the docker-entrypoint.sh script
// which runs after migrations complete, using credentials from environment variables:
//   - POCKETBASE_ADMIN_EMAIL (default: admin@example.com)
//   - POCKETBASE_ADMIN_PASSWORD (default: admin1234567890)

migrate((app) => {
  const email = $os.getenv("POCKETBASE_ADMIN_EMAIL") || "admin@example.com"
  
  console.log("Initial superuser configuration enabled")
  console.log("Email:", email)
  console.log("Superuser will be created automatically after migrations complete")
  
  return null
}, (app) => {
  // Down migration - for safety, we don't delete the initial admin
  return null
})
