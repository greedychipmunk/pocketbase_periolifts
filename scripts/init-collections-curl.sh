#!/bin/bash

# PocketBase Collection Initialization Script (using cURL)
# 
# This script initializes PocketBase collections when the container starts up.
# It uses cURL to make HTTP API calls instead of requiring Dart SDK.

set -e

# Enable debug mode by setting DEBUG=1 environment variable
DEBUG=${DEBUG:-0}

# Debug logging function
debug_log() {
    if [ "$DEBUG" = "1" ]; then
        echo "Debug: $*" >&2
    fi
}

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

# Function to check if superuser exists
check_superuser_exists() {
    echo "👤 Checking if superuser exists..."
    
    # Try to authenticate - if successful, superuser exists
    local auth_response
    auth_response=$(curl -s -X POST "${BASE_URL}/api/collections/_superusers/auth-with-password" \
        -H "Content-Type: application/json" \
        -d "{\"identity\":\"$POCKETBASE_ADMIN_EMAIL\",\"password\":\"$POCKETBASE_ADMIN_PASSWORD\"}" \
        2>/dev/null)
    
    if echo "$auth_response" | grep -q '"token"'; then
        echo "✅ Superuser exists and credentials are correct"
        return 0
    else
        echo "⚠️  Superuser check failed"
        debug_log "Auth response: $auth_response"
        return 1
    fi
}

# Function to authenticate as admin
authenticate_admin() {
    echo "🔐 Authenticating as superuser..." >&2
    
    # In PocketBase v0.23.0+, admins are _superusers auth collection records
    local auth_response
    local endpoint="/api/collections/_superusers/auth-with-password"
    
    debug_log "Using endpoint: $endpoint"
    auth_response=$(curl -s -X POST "${BASE_URL}${endpoint}" \
        -H "Content-Type: application/json" \
        -d "{\"identity\":\"$POCKETBASE_ADMIN_EMAIL\",\"password\":\"$POCKETBASE_ADMIN_PASSWORD\"}" \
        2>/dev/null)
    
    debug_log "Response from $endpoint: $auth_response"
    
    if echo "$auth_response" | grep -q '"token"'; then
        echo "✅ Authentication successful" >&2
        # Extract token more reliably using multiple methods
        token=$(echo "$auth_response" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
        if [ -z "$token" ]; then
            # Fallback method using grep and cut
            token=$(echo "$auth_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        fi
        debug_log "Extracted token: '${token:0:20}...'"
        echo "$token"
    else
        debug_log "No token found in response"
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

# Function to get collection ID by name
get_collection_id() {
    local token="$1"
    local collection_name="$2"
    
    local response
    response=$(curl -s -X GET "${BASE_URL}/api/collections" \
        -H "Authorization: Bearer $token" \
        2>/dev/null)
    
    # Try using jq first if available (most reliable)
    if command -v jq >/dev/null 2>&1; then
        echo "$response" | jq -r ".items[] | select(.name == \"$collection_name\") | .id" 2>/dev/null
    else
        # Fallback to grep/sed parsing
        # Note: Assumes flat JSON structure without nested objects in collection items
        # If PocketBase API changes significantly, consider installing jq
        echo "$response" | grep -o "{[^}]*\"name\":\"$collection_name\"[^}]*}" | grep -o "\"id\":\"[^\"]*\"" | cut -d'"' -f4 | head -1
    fi
}

# Function to create a collection
create_collection() {
    local token="$1"
    local collection_data="$2"
    local collection_name="$3"
    
    echo "📄 Creating collection: $collection_name"
    debug_log "Using token: ${token:0:20}..."
    
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
    local users_id="$1"
    cat << EOF
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
    {"name": "user_id", "type": "relation", "options": {"collectionId": "$users_id"}, "required": false}
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
    local users_id="$1"
    cat << EOF
{
  "name": "workouts",
  "type": "base",
  "schema": [
    {"name": "name", "type": "text", "required": true},
    {"name": "description", "type": "text", "required": false},
    {"name": "estimated_duration", "type": "number", "required": false},
    {"name": "exercises", "type": "json", "required": true},
    {"name": "user_id", "type": "relation", "options": {"collectionId": "$users_id"}, "required": true},
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
    local users_id="$1"
    cat << EOF
{
  "name": "workout_plans",
  "type": "base",
  "schema": [
    {"name": "name", "type": "text", "required": true},
    {"name": "description", "type": "text", "required": true},
    {"name": "start_date", "type": "date", "required": true},
    {"name": "schedule", "type": "json", "required": true},
    {"name": "is_active", "type": "bool", "required": false},
    {"name": "user_id", "type": "relation", "options": {"collectionId": "$users_id"}, "required": true}
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
    local workouts_id="$1"
    local users_id="$2"
    cat << EOF
{
  "name": "workout_sessions",
  "type": "base",
  "schema": [
    {"name": "workout_id", "type": "relation", "options": {"collectionId": "$workouts_id"}, "required": true},
    {"name": "user_id", "type": "relation", "options": {"collectionId": "$users_id"}, "required": true},
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
    local users_id="$1"
    local workout_sessions_id="$2"
    cat << EOF
{
  "name": "workout_history",
  "type": "base",
  "schema": [
    {"name": "user_id", "type": "relation", "options": {"collectionId": "$users_id"}, "required": true},
    {"name": "workout_session_id", "type": "relation", "options": {"collectionId": "$workout_sessions_id"}, "required": true},
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

    # Check if superuser exists with provided credentials
    if ! check_superuser_exists; then
        echo ""
        echo "❌ Superuser authentication failed"
        echo ""
        echo "PocketBase v0.23.0+ requires manual superuser setup."
        echo ""
        echo "📋 Setup Instructions:"
        echo "  1. Visit http://localhost:${POCKETBASE_PORT}/_/ in your browser"
        echo "  2. Create a superuser account (this is a one-time setup)"
        echo "  3. Update your .env file with the superuser credentials:"
        echo "     POCKETBASE_ADMIN_EMAIL=your-superuser-email"
        echo "     POCKETBASE_ADMIN_PASSWORD=your-superuser-password"
        echo "  4. Restart the containers: docker compose down && docker compose up"
        echo ""
        echo "Note: In PocketBase v0.23.0+, admins are now called 'superusers'"
        echo "      and must be created through the web UI on first run."
        exit 1
    fi
    
    # Authenticate as admin
    local auth_token
    auth_token=$(authenticate_admin)
    
    if [ -z "$auth_token" ]; then
        echo "❌ Superuser authentication failed during token extraction"
        echo "Please check your credentials in the .env file"
        exit 1
    fi
    
    echo "✅ Superuser authentication successful"
    debug_log "Token length: ${#auth_token}"
    debug_log "Token preview: ${auth_token:0:20}..."

    # Get existing collections
    echo "📋 Checking existing collections..."
    local existing_collections
    existing_collections=$(get_existing_collections "$auth_token")
    
    echo "📋 Existing collections: $(echo "$existing_collections" | tr '\n' ' ')"

    # Create missing collections
    local created=0
    local skipped=0
    
    # Store collection IDs as we create them
    local users_id=""
    local exercises_id=""
    local workouts_id=""
    local workout_plans_id=""
    local workout_sessions_id=""
    local workout_history_id=""
    
    # Create users collection first (it has no dependencies)
    if echo "$existing_collections" | grep -q "^users$"; then
        echo "⏭️  Collection 'users' already exists, skipping"
        skipped=$((skipped + 1))
        # Get existing users collection ID
        users_id=$(get_collection_id "$auth_token" "users")
        debug_log "users collection ID: $users_id"
    else
        local collection_data="$(create_users_collection)"
        if create_collection "$auth_token" "$collection_data" "users"; then
            created=$((created + 1))
            sleep 1
            # Fetch the newly created collection ID
            users_id=$(get_collection_id "$auth_token" "users")
            debug_log "Created users collection with ID: $users_id"
        fi
    fi
    
    # Verify we have users_id before proceeding
    if [ -z "$users_id" ]; then
        echo "❌ Failed to get users collection ID. Cannot create dependent collections."
        echo ""
        echo "Possible causes:"
        echo "  - Users collection was not created successfully"
        echo "  - API response format changed"
        echo "  - Network or authentication issues"
        echo ""
        echo "Debugging steps:"
        echo "  1. Enable debug mode: DEBUG=1 $0"
        echo "  2. Check PocketBase logs: docker compose logs pocketbase"
        echo "  3. Verify API access: curl http://\${POCKETBASE_HOST}:\${POCKETBASE_PORT}/api/collections"
        exit 1
    fi
    
    # Create exercises collection (depends on users)
    if echo "$existing_collections" | grep -q "^exercises$"; then
        echo "⏭️  Collection 'exercises' already exists, skipping"
        skipped=$((skipped + 1))
        exercises_id=$(get_collection_id "$auth_token" "exercises")
    else
        local collection_data="$(create_exercises_collection "$users_id")"
        if create_collection "$auth_token" "$collection_data" "exercises"; then
            created=$((created + 1))
            sleep 0.5
            exercises_id=$(get_collection_id "$auth_token" "exercises")
        fi
    fi
    
    # Create workouts collection (depends on users)
    if echo "$existing_collections" | grep -q "^workouts$"; then
        echo "⏭️  Collection 'workouts' already exists, skipping"
        skipped=$((skipped + 1))
        workouts_id=$(get_collection_id "$auth_token" "workouts")
    else
        local collection_data="$(create_workouts_collection "$users_id")"
        if create_collection "$auth_token" "$collection_data" "workouts"; then
            created=$((created + 1))
            sleep 0.5
            workouts_id=$(get_collection_id "$auth_token" "workouts")
        fi
    fi
    
    # Verify we have workouts_id before creating workout_sessions
    if [ -z "$workouts_id" ]; then
        echo "❌ Failed to get workouts collection ID. Cannot create workout_sessions."
        echo ""
        echo "Possible causes:"
        echo "  - Workouts collection was not created successfully"
        echo "  - API response format changed"
        echo ""
        echo "Debugging steps:"
        echo "  1. Enable debug mode: DEBUG=1 $0"
        echo "  2. Check if workouts collection exists in PocketBase admin UI"
        exit 1
    fi
    
    # Create workout_plans collection (depends on users)
    if echo "$existing_collections" | grep -q "^workout_plans$"; then
        echo "⏭️  Collection 'workout_plans' already exists, skipping"
        skipped=$((skipped + 1))
        workout_plans_id=$(get_collection_id "$auth_token" "workout_plans")
    else
        local collection_data="$(create_workout_plans_collection "$users_id")"
        if create_collection "$auth_token" "$collection_data" "workout_plans"; then
            created=$((created + 1))
            sleep 0.5
            workout_plans_id=$(get_collection_id "$auth_token" "workout_plans")
        fi
    fi
    
    # Create workout_sessions collection (depends on workouts and users)
    if echo "$existing_collections" | grep -q "^workout_sessions$"; then
        echo "⏭️  Collection 'workout_sessions' already exists, skipping"
        skipped=$((skipped + 1))
        workout_sessions_id=$(get_collection_id "$auth_token" "workout_sessions")
    else
        local collection_data="$(create_workout_sessions_collection "$workouts_id" "$users_id")"
        if create_collection "$auth_token" "$collection_data" "workout_sessions"; then
            created=$((created + 1))
            sleep 0.5
            workout_sessions_id=$(get_collection_id "$auth_token" "workout_sessions")
        fi
    fi
    
    # Verify we have workout_sessions_id before creating workout_history
    if [ -z "$workout_sessions_id" ]; then
        echo "❌ Failed to get workout_sessions collection ID. Cannot create workout_history."
        echo ""
        echo "Possible causes:"
        echo "  - Workout_sessions collection was not created successfully"
        echo "  - API response format changed"
        echo ""
        echo "Debugging steps:"
        echo "  1. Enable debug mode: DEBUG=1 $0"
        echo "  2. Check if workout_sessions collection exists in PocketBase admin UI"
        exit 1
    fi
    
    # Create workout_history collection (depends on users and workout_sessions)
    if echo "$existing_collections" | grep -q "^workout_history$"; then
        echo "⏭️  Collection 'workout_history' already exists, skipping"
        skipped=$((skipped + 1))
        workout_history_id=$(get_collection_id "$auth_token" "workout_history")
    else
        local collection_data="$(create_workout_history_collection "$users_id" "$workout_sessions_id")"
        if create_collection "$auth_token" "$collection_data" "workout_history"; then
            created=$((created + 1))
            workout_history_id=$(get_collection_id "$auth_token" "workout_history")
        fi
    fi

    echo "🎉 Collection initialization complete!"
    echo "📊 Summary: $created created, $skipped skipped"
}

# Run main function
main "$@"