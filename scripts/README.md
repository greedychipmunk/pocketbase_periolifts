# PerioLifts Administrative Scripts

This directory contains administrative scripts for managing the PerioLifts PocketBase backend.

## Available Scripts

- **Collection Initialization** (`init-collections-curl.sh`, `init_collections.dart`, `init-collections.sh`) - Automatically creates missing PocketBase collections
  - `init-collections-curl.sh` - Bash script using cURL (used by Docker, no Dart SDK required)
  - `init_collections.dart` - Dart-based script (requires Dart SDK)
  - `init-collections.sh` - Shell wrapper for Dart script
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

The collection initialization scripts automatically create missing PocketBase collections when you run `docker compose up`.

**Important:** As of PocketBase v0.23.0+, collections with relation fields require actual collection IDs (not names). The scripts handle this by:
1. Creating collections in dependency order
2. Fetching collection IDs after creation
3. Using actual IDs when defining relation fields

**Collections Created:**

1. **users** (auth) - User profiles and authentication
2. **exercises** (base) - Exercise definitions and custom exercises (relates to users)
3. **workouts** (base) - Workout templates and instances (relates to users)
4. **workout_plans** (base) - Structured workout programs (relates to users)
5. **workout_sessions** (base) - Active workout tracking (relates to workouts and users)
6. **workout_history** (base) - Completed workout records (relates to users and workout_sessions)

**Usage with Docker (Recommended):**

```bash
# Collections are created automatically using init-collections-curl.sh
docker compose up
```

The Docker setup uses `init-collections-curl.sh` which requires only cURL (no Dart SDK needed in the container).

**Manual Usage (cURL-based script):**

```bash
# Set environment variables
export POCKETBASE_HOST=localhost
export POCKETBASE_PORT=8090
export POCKETBASE_ADMIN_EMAIL=your-admin@example.com
export POCKETBASE_ADMIN_PASSWORD=your-password

# Run the script
./scripts/init-collections-curl.sh
```

**Manual Usage (Dart-based script):**

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

The scripts read from your `.env` file or environment variables:
- `POCKETBASE_HOST` - PocketBase hostname (default: localhost)
- `POCKETBASE_PORT` - PocketBase port (default: 8090) 
- `POCKETBASE_ADMIN_EMAIL` - Admin email for authentication
- `POCKETBASE_ADMIN_PASSWORD` - Admin password for authentication

**First-Time Setup (PocketBase v0.23.0+):**

PocketBase v0.23.0+ requires manual superuser creation on first run:

1. Start PocketBase: `docker compose up`
2. Visit http://localhost:8090/_/ in your browser
3. Create a superuser account (one-time setup)
4. Update `.env` with your superuser credentials
5. Restart: `docker compose down && docker compose up`

**Troubleshooting:**

For detailed testing and troubleshooting information, see [TESTING_COLLECTIONS.md](./TESTING_COLLECTIONS.md).

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