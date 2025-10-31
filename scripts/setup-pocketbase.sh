#!/bin/bash

# PerioLifts PocketBase Setup Script
# This script downloads, configures, and runs PocketBase locally for development

set -e  # Exit on any error

# Configuration
POCKETBASE_VERSION="0.23.0"
POCKETBASE_DIR="./pocketbase"
POCKETBASE_BINARY="$POCKETBASE_DIR/pocketbase"
POCKETBASE_DATA_DIR="$POCKETBASE_DIR/pb_data"
POCKETBASE_URL="http://localhost:8090"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS and architecture
detect_platform() {
    OS=""
    ARCH=""
    
    case "$(uname -s)" in
        Darwin)
            OS="darwin"
            ;;
        Linux)
            OS="linux"
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            OS="windows"
            ;;
        *)
            log_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
    
    case "$(uname -m)" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        *)
            log_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
    
    log_info "Detected platform: $OS-$ARCH"
}

# Download PocketBase
download_pocketbase() {
    local download_url="https://github.com/pocketbase/pocketbase/releases/download/v${POCKETBASE_VERSION}/pocketbase_${POCKETBASE_VERSION}_${OS}_${ARCH}.zip"
    local zip_file="$POCKETBASE_DIR/pocketbase.zip"
    
    log_info "Downloading PocketBase v${POCKETBASE_VERSION} for ${OS}-${ARCH}..."
    
    # Create pocketbase directory
    mkdir -p "$POCKETBASE_DIR"
    
    # Download the zip file
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$zip_file" "$download_url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$zip_file" "$download_url"
    else
        log_error "Neither curl nor wget is available. Please install one of them."
        exit 1
    fi
    
    # Extract the zip file
    log_info "Extracting PocketBase..."
    if command -v unzip >/dev/null 2>&1; then
        unzip -o "$zip_file" -d "$POCKETBASE_DIR"
    else
        log_error "unzip is not available. Please install it or extract manually."
        exit 1
    fi
    
    # Make the binary executable
    chmod +x "$POCKETBASE_BINARY"
    
    # Clean up
    rm "$zip_file"
    
    log_success "PocketBase downloaded and extracted successfully!"
}

# Check if PocketBase is already installed
check_existing_installation() {
    if [ -f "$POCKETBASE_BINARY" ]; then
        log_info "PocketBase binary found at $POCKETBASE_BINARY"
        
        # Check version
        local current_version
        current_version=$("$POCKETBASE_BINARY" --version 2>/dev/null | grep -o "v[0-9]\+\.[0-9]\+\.[0-9]\+" | sed 's/v//')
        
        if [ "$current_version" = "$POCKETBASE_VERSION" ]; then
            log_success "PocketBase v$POCKETBASE_VERSION is already installed!"
            return 0
        else
            log_warning "Found PocketBase v$current_version, but expected v$POCKETBASE_VERSION"
            log_info "Re-downloading the correct version..."
            return 1
        fi
    else
        log_info "PocketBase not found. Downloading..."
        return 1
    fi
}

# Create collections and sample data
setup_collections() {
    log_info "Setting up PocketBase collections..."
    
    # Wait for PocketBase to start
    log_info "Waiting for PocketBase to start..."
    sleep 3
    
    # Check if PocketBase is running
    if ! curl -s "$POCKETBASE_URL/_/" >/dev/null 2>&1; then
        log_warning "PocketBase doesn't seem to be running. Please start it manually and run the setup again."
        return 1
    fi
    
    log_info "PocketBase is running at $POCKETBASE_URL"
    log_info "Please visit $POCKETBASE_URL/_/ to complete the admin setup and configure collections."
    log_info "Collection schemas will be provided in future releases."
}

# Start PocketBase server
start_pocketbase() {
    log_info "Starting PocketBase server..."
    log_info "Server will be available at: $POCKETBASE_URL"
    log_info "Admin UI will be available at: $POCKETBASE_URL/_/"
    log_info ""
    log_info "Press Ctrl+C to stop the server"
    log_info ""
    
    # Start PocketBase with custom settings
    "$POCKETBASE_BINARY" serve \
        --dir="$POCKETBASE_DATA_DIR" \
        --http="0.0.0.0:8090" \
        --dev
}

# Main function
main() {
    echo "========================================="
    echo "     PerioLifts PocketBase Setup"
    echo "========================================="
    echo ""
    
    # Parse command line arguments
    case "${1:-}" in
        "start")
            if [ ! -f "$POCKETBASE_BINARY" ]; then
                log_error "PocketBase is not installed. Run without arguments to install first."
                exit 1
            fi
            start_pocketbase
            exit 0
            ;;
        "clean")
            log_info "Cleaning PocketBase installation..."
            rm -rf "$POCKETBASE_DIR"
            log_success "PocketBase installation removed!"
            exit 0
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  (no args)  Install and start PocketBase"
            echo "  start      Start PocketBase server (if already installed)"
            echo "  clean      Remove PocketBase installation"
            echo "  help       Show this help message"
            echo ""
            exit 0
            ;;
    esac
    
    # Detect platform
    detect_platform
    
    # Check for existing installation
    if ! check_existing_installation; then
        download_pocketbase
    fi
    
    # Start the server
    log_info ""
    log_info "Setup complete! Starting PocketBase server..."
    log_info ""
    
    start_pocketbase
}

# Run main function with all arguments
main "$@"