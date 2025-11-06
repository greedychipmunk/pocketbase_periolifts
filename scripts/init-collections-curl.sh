#!/bin/bash

# PocketBase Collection Initialization Script (using cURL)
# 
# This script initializes PocketBase collections when the container starts up.
# It uses cURL to make HTTP API calls instead of requiring Dart SDK.

set -e

echo "🚀 Starting PocketBase collection initialization..."

# Set default values if environment variables are not set
POCKETBASE_HOST=${POCKETBASE_HOST:-"pocketbase"}
POCKETBASE_PORT=${POCKETBASE_PORT:-"8090"}
POCKETBASE_ADMIN_EMAIL=${POCKETBASE_ADMIN_EMAIL:-"admin@example.com"}
POCKETBASE_ADMIN_PASSWORD=${POCKETBASE_ADMIN_PASSWORD:-"password"}
BASE_URL="http://${POCKETBASE_HOST}:${POCKETBASE_PORT}"

echo "📋 Configuration:"
echo "  - Host: $POCKETBASE_HOST"
echo "  - Port: $POCKETBASE_PORT"
echo "  - Admin Email: $POCKETBASE_ADMIN_EMAIL"
echo "  - Base URL: $BASE_URL"

# Function to wait for PocketBase to be ready
wait_for_pocketbase() {
    echo "🔍 Waiting for PocketBase to be ready..."
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        if curl -s "${BASE_URL}/api/health" > /dev/null 2>&1; then
            echo "✅ PocketBase is ready!"
            return 0
        fi
        
        attempts=$((attempts + 1))
        echo "⏳ Attempt $attempts/$max_attempts - PocketBase not ready yet..."
        sleep 2
    done
    
    echo "❌ PocketBase failed to start within expected time"
    return 1
}

# Function to create admin user if it doesn't exist
create_admin_user() {
    echo "👤 Creating admin user via API..."
    
    local create_response
    create_response=$(curl -s -X POST "${BASE_URL}/api/admins" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$POCKETBASE_ADMIN_EMAIL\",\"password\":\"$POCKETBASE_ADMIN_PASSWORD\",\"passwordConfirm\":\"$POCKETBASE_ADMIN_PASSWORD\"}" \
        2>/dev/null)
    
    echo "Debug: Create admin API response: $create_response" >&2
    
    if echo "$create_response" | grep -q '"id"'; then
        echo "✅ Admin user created via API"
        return 0
    else
        # Check if it's just that the user already exists
        if echo "$create_response" | grep -q "email already exists" || echo "$create_response" | grep -q "already exists"; then
            echo "ℹ️  Admin user already exists via API"
            return 0
        else
            echo "⚠️  API admin creation failed: $create_response" >&2
            echo "ℹ️  Admin may have been created by setup container"
            return 0
        fi
    fi
}

# Function to authenticate as admin
authenticate_admin() {
    echo "🔐 Authenticating as admin..." >&2
    
    # Try different authentication endpoints based on PocketBase version/setup
    local auth_response
    local endpoint
    
    # List of endpoints to try (POSIX shell compatible)
    for endpoint in \
        "/api/collections/users/auth-with-password" \
        "/api/collections/_superusers/auth-with-password" \
        "/api/admins/auth-with-password"; do
        
        echo "🔄 Trying endpoint: $endpoint" >&2
        auth_response=$(curl -s -X POST "${BASE_URL}${endpoint}" \
            -H "Content-Type: application/json" \
            -d "{\"identity\":\"$POCKETBASE_ADMIN_EMAIL\",\"password\":\"$POCKETBASE_ADMIN_PASSWORD\"}" \
            2>/dev/null)
        
        echo "Debug: Response from $endpoint: $auth_response" >&2
        
        if echo "$auth_response" | grep -q "token"; then
            echo "✅ Authentication successful with $endpoint" >&2
            break
        fi
    done
    
    if echo "$auth_response" | grep -q "token"; then
        # Extract token more reliably using multiple methods
        token=$(echo "$auth_response" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
        if [ -z "$token" ]; then
            # Fallback method using grep and cut
            token=$(echo "$auth_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        fi
        echo "Debug: Extracted token: '$token'" >&2
        echo "$token"
    else
        echo "Debug: No token found in any response" >&2
        echo ""
    fi
}

# Function to get existing collections
get_existing_collections() {
    local token="$1"
    
    curl -s -X GET "${BASE_URL}/api/collections" \
        -H "Authorization: Bearer $token" \
        2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | sort
}

# Function to create a collection
create_collection() {
    local token="$1"
    local collection_data="$2"
    local collection_name="$3"
    
    echo "📄 Creating collection: $collection_name"
    echo "Debug: Using token: ${token:0:20}..." >&2
    
    local response
    response=$(curl -s -X POST "${BASE_URL}/api/collections" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -d "$collection_data" \
        2>/dev/null)
    
    if echo "$response" | grep -q '"id"'; then
        echo "✅ Collection '$collection_name' created successfully"
        return 0
    else
        echo "❌ Failed to create collection '$collection_name': $response"
        return 1
    fi
}

# Collection definitions (JSON format)
create_users_collection() {
    cat << 'EOF'
{
  "name": "users",
  "type": "auth",
  "schema": [
    {"name": "name", "type": "text", "required": true},
    {"name": "username", "type": "text", "required": true},
    {"name": "avatar_url", "type": "url", "required": false},
    {"name": "preferred_units", "type": "select", "options": {"values": ["metric", "imperial"]}, "required": false},
    {"name": "preferred_theme", "type": "select", "options": {"values": ["light", "dark", "system"]}, "required": false},
    {"name": "timezone", "type": "text", "required": false},
    {"name": "onboarding_completed", "type": "bool", "required": false},
    {"name": "fitness_goals", "type": "json", "required": false},
    {"name": "current_cycle_phase", "type": "text", "required": false},
    {"name": "average_cycle_length", "type": "number", "required": false},
    {"name": "birth_date", "type": "date", "required": false},
    {"name": "height", "type": "number", "required": false},
    {"name": "weight", "type": "number", "required": false},
    {"name": "activity_level", "type": "select", "options": {"values": ["sedentary", "lightly_active", "moderately_active", "very_active", "extremely_active"]}, "required": false},
    {"name": "notifications_enabled", "type": "bool", "required": false},
    {"name": "workout_reminders_enabled", "type": "bool", "required": false},
    {"name": "period_reminders_enabled", "type": "bool", "required": false},
    {"name": "subscription_status", "type": "select", "options": {"values": ["free", "premium"]}, "required": false},
    {"name": "subscription_expires_at", "type": "date", "required": false},
    {"name": "role", "type": "select", "options": {"values": ["user", "admin"]}, "required": false},
    {"name": "is_active", "type": "bool", "required": false},
    {"name": "last_active_at", "type": "date", "required": false}
  ],
  "listRule": "id = @request.auth.id",
  "viewRule": "id = @request.auth.id",
  "createRule": "",
  "updateRule": "id = @request.auth.id",
  "deleteRule": "id = @request.auth.id"
}
EOF
}

create_exercises_collection() {
    cat << 'EOF'
{
  "name": "exercises",
  "type": "base",
  "schema": [
    {"name": "name", "type": "text", "required": true},
    {"name": "category", "type": "text", "required": true},
    {"name": "description", "type": "text", "required": true},
    {"name": "muscle_groups", "type": "json", "required": true},
    {"name": "image_url", "type": "url", "required": false},
    {"name": "video_url", "type": "url", "required": false},
    {"name": "is_custom", "type": "bool", "required": true},
    {"name": "user_id", "type": "relation", "options": {"collectionId": "users"}, "required": false}
  ],
  "listRule": "is_custom = false || user_id = @request.auth.id",
  "viewRule": "is_custom = false || user_id = @request.auth.id",
  "createRule": "@request.auth.id != \"\"",
  "updateRule": "user_id = @request.auth.id",
  "deleteRule": "user_id = @request.auth.id"
}
EOF
}

create_workouts_collection() {
    cat << 'EOF'
{
  "name": "workouts",
  "type": "base",
  "schema": [
    {"name": "name", "type": "text", "required": true},
    {"name": "description", "type": "text", "required": false},
    {"name": "estimated_duration", "type": "number", "required": false},
    {"name": "exercises", "type": "json", "required": true},
    {"name": "user_id", "type": "relation", "options": {"collectionId": "users"}, "required": true},
    {"name": "scheduled_date", "type": "date", "required": false},
    {"name": "is_completed", "type": "bool", "required": false},
    {"name": "completed_date", "type": "date", "required": false},
    {"name": "is_in_progress", "type": "bool", "required": false},
    {"name": "progress", "type": "json", "required": false}
  ],
  "listRule": "user_id = @request.auth.id",
  "viewRule": "user_id = @request.auth.id",
  "createRule": "@request.auth.id != \"\"",
  "updateRule": "user_id = @request.auth.id",
  "deleteRule": "user_id = @request.auth.id"
}
EOF
}

create_workout_plans_collection() {
    cat << 'EOF'
{
  "name": "workout_plans",
  "type": "base",
  "schema": [
    {"name": "name", "type": "text", "required": true},
    {"name": "description", "type": "text", "required": true},
    {"name": "start_date", "type": "date", "required": true},
    {"name": "schedule", "type": "json", "required": true},
    {"name": "is_active", "type": "bool", "required": false},
    {"name": "user_id", "type": "relation", "options": {"collectionId": "users"}, "required": true}
  ],
  "listRule": "user_id = @request.auth.id",
  "viewRule": "user_id = @request.auth.id",
  "createRule": "@request.auth.id != \"\"",
  "updateRule": "user_id = @request.auth.id",
  "deleteRule": "user_id = @request.auth.id"
}
EOF
}

create_workout_sessions_collection() {
    cat << 'EOF'
{
  "name": "workout_sessions",
  "type": "base",
  "schema": [
    {"name": "workout_id", "type": "relation", "options": {"collectionId": "workouts"}, "required": true},
    {"name": "user_id", "type": "relation", "options": {"collectionId": "users"}, "required": true},
    {"name": "started_at", "type": "date", "required": true},
    {"name": "completed_at", "type": "date", "required": false},
    {"name": "is_completed", "type": "bool", "required": false},
    {"name": "notes", "type": "text", "required": false},
    {"name": "exercise_data", "type": "json", "required": true},
    {"name": "total_duration", "type": "number", "required": false},
    {"name": "calories_burned", "type": "number", "required": false}
  ],
  "listRule": "user_id = @request.auth.id",
  "viewRule": "user_id = @request.auth.id",
  "createRule": "@request.auth.id != \"\"",
  "updateRule": "user_id = @request.auth.id",
  "deleteRule": "user_id = @request.auth.id"
}
EOF
}

create_workout_history_collection() {
    cat << 'EOF'
{
  "name": "workout_history",
  "type": "base",
  "schema": [
    {"name": "user_id", "type": "relation", "options": {"collectionId": "users"}, "required": true},
    {"name": "workout_session_id", "type": "relation", "options": {"collectionId": "workout_sessions"}, "required": true},
    {"name": "workout_name", "type": "text", "required": true},
    {"name": "completed_at", "type": "date", "required": true},
    {"name": "duration", "type": "number", "required": false},
    {"name": "exercises_completed", "type": "number", "required": false},
    {"name": "total_sets", "type": "number", "required": false},
    {"name": "total_reps", "type": "number", "required": false},
    {"name": "total_weight", "type": "number", "required": false},
    {"name": "notes", "type": "text", "required": false},
    {"name": "performance_data", "type": "json", "required": false}
  ],
  "listRule": "user_id = @request.auth.id",
  "viewRule": "user_id = @request.auth.id",
  "createRule": "@request.auth.id != \"\"",
  "updateRule": "user_id = @request.auth.id",
  "deleteRule": "user_id = @request.auth.id"
}
EOF
}

# Main execution
main() {
    # Wait for PocketBase to be ready
    if ! wait_for_pocketbase; then
        exit 1
    fi

    # Try to create admin user via API if needed
    create_admin_user
    
    # Wait a bit for superuser to be available for authentication
    echo "⏳ Waiting for superuser to be available for authentication..."
    sleep 3
    
    # Authenticate as admin (user should exist either from setup container or API)
    local auth_token
    auth_token=$(authenticate_admin)
    
    if [ -z "$auth_token" ] || [ "$auth_token" = "🔐 Authenticating ..." ]; then
        echo "❌ Admin authentication failed"
        echo "This might be because:"
        echo "  1. PocketBase is in setup mode (visit http://localhost:8090/_ to set up)"
        echo "  2. Admin credentials in .env are incorrect" 
        echo "  3. PocketBase database is corrupted"
        echo "  4. Superuser creation failed or needs more time"
        echo ""
        echo "Debug: Actual auth token received: '$auth_token'"
        exit 1
    fi
    
    echo "✅ Admin authentication successful"
    echo "Debug: Token length: ${#auth_token}" >&2
    echo "Debug: Token preview: ${auth_token:0:20}..." >&2

    # Get existing collections
    echo "📋 Checking existing collections..."
    local existing_collections
    existing_collections=$(get_existing_collections "$auth_token")
    
    echo "📋 Existing collections: $(echo $existing_collections | tr '\n' ' ')"

    # Create missing collections
    local created=0
    local skipped=0
    
    # Create collections one by one
    local collections="users exercises workouts workout_plans workout_sessions workout_history"
    
    for collection_name in $collections; do
        if echo "$existing_collections" | grep -q "^$collection_name$"; then
            echo "⏭️  Collection '$collection_name' already exists, skipping"
            skipped=$((skipped + 1))
        else
            local collection_data=""
            case $collection_name in
                "users")
                    collection_data="$(create_users_collection)"
                    ;;
                "exercises") 
                    collection_data="$(create_exercises_collection)"
                    ;;
                "workouts")
                    collection_data="$(create_workouts_collection)"
                    ;;
                "workout_plans")
                    collection_data="$(create_workout_plans_collection)"
                    ;;
                "workout_sessions")
                    collection_data="$(create_workout_sessions_collection)"
                    ;;
                "workout_history")
                    collection_data="$(create_workout_history_collection)"
                    ;;
            esac
            
            if [ -n "$collection_data" ]; then
                if create_collection "$auth_token" "$collection_data" "$collection_name"; then
                    created=$((created + 1))
                fi
            fi
            # Small delay between requests
            sleep 0.5
        fi
    done

    echo "🎉 Collection initialization complete!"
    echo "📊 Summary: $created created, $skipped skipped"
}

# Run main function
main "$@"