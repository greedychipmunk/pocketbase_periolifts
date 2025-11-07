#!/bin/sh

# Script to initialize PocketBase admin/superuser
# This script is called after PocketBase migrations have run
# It creates an admin account if one doesn't exist

EMAIL="${POCKETBASE_ADMIN_EMAIL:-admin@example.com}"
PASSWORD="${POCKETBASE_ADMIN_PASSWORD:-admin1234567890}"

echo "Initializing PocketBase admin account..."
echo "Email: $EMAIL"

# Use the superuser upsert command to create or update the admin
# This command is idempotent - it won't fail if the admin already exists
./pocketbase superuser upsert "$EMAIL" "$PASSWORD" || {
    echo "Note: Admin may already exist or PocketBase is not ready yet"
    echo "You can manually create the admin by accessing http://localhost:8090/_/"
}

echo "Admin initialization complete"
