#!/bin/bash

# PocketBase Collection Initialization Shell Script
# 
# This script initializes PocketBase collections when the container starts up.
# It waits for PocketBase to be ready and then creates missing collections.

set -e

echo "🚀 Starting PocketBase collection initialization..."

# Set default values if environment variables are not set
POCKETBASE_HOST=${POCKETBASE_HOST:-"pocketbase"}
POCKETBASE_PORT=${POCKETBASE_PORT:-"8090"}
POCKETBASE_ADMIN_EMAIL=${POCKETBASE_ADMIN_EMAIL:-"admin@example.com"}
POCKETBASE_ADMIN_PASSWORD=${POCKETBASE_ADMIN_PASSWORD:-"password"}

# Export variables for Dart script
export POCKETBASE_HOST
export POCKETBASE_PORT
export POCKETBASE_ADMIN_EMAIL
export POCKETBASE_ADMIN_PASSWORD

echo "📋 Configuration:"
echo "  - Host: $POCKETBASE_HOST"
echo "  - Port: $POCKETBASE_PORT"
echo "  - Admin Email: $POCKETBASE_ADMIN_EMAIL"

# Change to scripts directory and get dependencies
cd /scripts
dart pub get

# Run the Dart initialization script
dart run init_collections.dart

echo "✅ Collection initialization completed!"