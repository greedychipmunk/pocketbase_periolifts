#!/bin/bash

# PocketBase User Email Verification Script
# Automatically loads environment variables from .env file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_info "🚀 PocketBase User Email Verification"
print_info "====================================="

# Check if email argument is provided
if [ $# -eq 0 ]; then
    print_error "Email address is required"
    echo ""
    echo "Usage: $0 <email>"
    echo ""
    echo "Environment variables required (will be loaded from .env file):"
    echo "  POCKETBASE_ADMIN_EMAIL     - Admin email for PocketBase"
    echo "  POCKETBASE_ADMIN_PASSWORD  - Admin password for PocketBase"
    echo ""
    echo "Optional environment variables:"
    echo "  POCKETBASE_URL            - PocketBase URL (default: http://localhost:8090)"
    exit 1
fi

EMAIL="$1"

# Load environment variables from .env file if it exists
ENV_FILE="$PROJECT_ROOT/.env"
if [ -f "$ENV_FILE" ]; then
    print_info "📁 Loading environment variables from .env file..."
    set -a
    source "$ENV_FILE"
    set +a
    print_success "✅ Environment variables loaded"
else
    print_warning "⚠️  No .env file found at $ENV_FILE"
    print_info "💡 Create a .env file from .env.example or set environment variables manually"
fi

# Check if required environment variables are set
if [ -z "$POCKETBASE_ADMIN_EMAIL" ]; then
    print_error "POCKETBASE_ADMIN_EMAIL environment variable is not set"
    print_info "Please add it to your .env file or set it using: export POCKETBASE_ADMIN_EMAIL=your_admin_email"
    exit 1
fi

if [ -z "$POCKETBASE_ADMIN_PASSWORD" ]; then
    print_error "POCKETBASE_ADMIN_PASSWORD environment variable is not set"
    print_info "Please add it to your .env file or set it using: export POCKETBASE_ADMIN_PASSWORD=your_admin_password"
    exit 1
fi

print_info "📧 Target email: $EMAIL"
print_info "🔐 Admin email: $POCKETBASE_ADMIN_EMAIL"
print_info "🌐 PocketBase URL: ${POCKETBASE_URL:-http://localhost:8090}"
echo ""

# Change to scripts directory
cd "$SCRIPT_DIR"

# Ensure dependencies are installed
print_info "📦 Installing Dart dependencies..."
if ! dart pub get > /dev/null 2>&1; then
    print_error "Failed to install Dart dependencies"
    print_info "Make sure you're in the scripts directory and have a valid pubspec.yaml"
    exit 1
fi

print_success "✅ Dependencies installed"
echo ""

# Run the Dart script with explicit environment variable passing
print_info "🎯 Running email verification script..."
if ! POCKETBASE_URL="$POCKETBASE_URL" \
     POCKETBASE_ADMIN_EMAIL="$POCKETBASE_ADMIN_EMAIL" \
     POCKETBASE_ADMIN_PASSWORD="$POCKETBASE_ADMIN_PASSWORD" \
     dart verify_user_email.dart "$EMAIL"; then
    print_error "Email verification failed"
    exit 1
fi

print_success "🎉 Email verification completed successfully!"