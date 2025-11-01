# PerioLifts Administrative Scripts

This directory contains administrative scripts for managing the PerioLifts PocketBase backend.

## Prerequisites

- Dart SDK 3.0+ installed
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