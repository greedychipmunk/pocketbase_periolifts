#!/bin/sh
set -e

# Docker entrypoint script for PocketBase
# Runs migrations and creates initial superuser

EMAIL="${POCKETBASE_ADMIN_EMAIL:-admin@example.com}"
PASSWORD="${POCKETBASE_ADMIN_PASSWORD:-admin1234567890}"

# Find pocketbase binary
POCKETBASE="$(which pocketbase || echo '/usr/local/bin/pocketbase')"

echo "Starting PocketBase with migrations..."

# Start PocketBase in the background with migrations
"$POCKETBASE" serve --http=0.0.0.0:8090 --migrationsDir=/pb_migrations &
PB_PID=$!

# Wait for PocketBase to be ready
sleep 5

# Create superuser if it doesn't exist
echo "Creating superuser: $EMAIL"
"$POCKETBASE" superuser upsert "$EMAIL" "$PASSWORD" || echo "Superuser may already exist"

# Keep PocketBase running in foreground
wait $PB_PID
