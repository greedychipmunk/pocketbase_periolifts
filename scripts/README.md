# PerioLifts Administrative Scripts

This directory contains administrative scripts for managing the PerioLifts PocketBase backend.

## Available Scripts

- **Collection Initialization** (`init_collections.dart`, `init-collections.sh`) - Automatically creates missing PocketBase collections using Dart SDK
- **User Email Verification** (`verify_user_email.dart`) - Marks user emails as verified

## Prerequisites

- Dart SDK 3.0+ (for all scripts)
- PocketBase server running
- Admin credentials for PocketBase

## Setup

Install script dependencies:

```bash
cd scripts
dart pub get
```

Or from the project root:

```bash
npm run scripts:install
```

## Scripts

### Collection Initialization (Auto-run with Docker)

The `init_collections.dart` script automatically creates missing PocketBase collections when you run `docker compose up`.

**Collections Created:**

1. **users** (auth) - User profiles and authentication
2. **exercises** (base) - Exercise definitions and custom exercises  
3. **workouts** (base) - Workout templates and instances
4. **workout_plans** (base) - Structured workout programs
5. **workout_sessions** (base) - Active workout tracking
6. **workout_history** (base) - Completed workout records

**Usage with Docker (Recommended):**

```bash
# Collections are created automatically
docker compose up
```

**Manual Usage:**

```bash
# Set environment variables
export POCKETBASE_HOST=localhost
export POCKETBASE_PORT=8090
export POCKETBASE_ADMIN_EMAIL=your-admin@example.com
export POCKETBASE_ADMIN_PASSWORD=your-password

# From scripts directory - install dependencies first
cd scripts
dart pub get

# Run the script
dart run init_collections.dart

# Or use the shell wrapper
./init-collections.sh
```

**Configuration:**

The script reads from your `.env` file:
- `POCKETBASE_HOST` - PocketBase hostname (default: localhost)
- `POCKETBASE_PORT` - PocketBase port (default: 8090) 
- `POCKETBASE_ADMIN_EMAIL` - Admin email for authentication
- `POCKETBASE_ADMIN_PASSWORD` - Admin password for authentication

### User Email Verification

Marks a user's email as verified in the PocketBase users collection.

**Usage Options:**

1. **Auto-loading from .env file (Recommended):**
```bash
# From project root (automatically loads .env file)
npm run user:verify:auto user@example.com
```

2. **Manual environment variables:**
```bash
# From project root
POCKETBASE_ADMIN_EMAIL="admin@example.com" POCKETBASE_ADMIN_PASSWORD="your_password" npm run user:verify user@example.com

# Windows (from project root)
npm run user:verify:win user@example.com
```

3. **Direct script execution:**
```bash
# From scripts directory
POCKETBASE_ADMIN_EMAIL="admin@example.com" POCKETBASE_ADMIN_PASSWORD="your_password" dart verify_user_email.dart user@example.com
```

**Environment Variables:**

- `POCKETBASE_ADMIN_EMAIL` (required) - Admin email for PocketBase authentication
- `POCKETBASE_ADMIN_PASSWORD` (required) - Admin password for PocketBase authentication  
- `POCKETBASE_URL` (optional) - PocketBase server URL (default: http://localhost:8090)

**Setup .env file (Recommended):**

Copy `.env.example` to `.env` and update the admin credentials:

```bash
cp .env.example .env
# Edit .env file with your admin credentials
```

**Example:**

```bash
# Using auto-loading (reads from .env file)
npm run user:verify:auto john.doe@example.com

# Using manual environment variables
export POCKETBASE_ADMIN_EMAIL="admin@periolifts.com"
export POCKETBASE_ADMIN_PASSWORD="secure_admin_password"
npm run user:verify john.doe@example.com
```

**Output:**
```
[INFO] 🚀 PocketBase User Email Verification Script
[INFO] ===========================================
[INFO] 🎯 Target email: john.doe@example.com
[INFO] 🌐 PocketBase URL: http://localhost:8090

[INFO] 🔐 Authenticating as admin...
[SUCCESS] ✅ Admin authentication successful
[INFO] 🔍 Looking for user with email: john.doe@example.com
[INFO] 👤 Found user: johndoe (ID: abc123def456)
[INFO] 📧 Updating user verification status...
[SUCCESS] ✅ User email verified successfully!
[INFO] 📊 User details:
[INFO]    - Email: john.doe@example.com
[INFO]    - Username: johndoe
[INFO]    - ID: abc123def456
[INFO]    - Verified: true
```

## Security Notes

- Never commit admin credentials to version control
- Use environment variables or a secure credential management system
- Ensure PocketBase admin panel is secured in production
- Consider using service accounts with limited permissions for automation

## Development

When developing new scripts:

1. Follow the existing pattern of error handling and logging
2. Use environment variables for configuration
3. Include help text and usage examples
4. Test scripts against a development PocketBase instance first
5. Document any new environment variables or dependencies