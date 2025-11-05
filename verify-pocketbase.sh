#!/bin/bash

# PerioLifts PocketBase Verification Script
# This script verifies that PocketBase is running and accessible

set -e

echo "======================================"
echo "PocketBase Connection Verification"
echo "======================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi
echo "✅ Docker is running"

# Check if PocketBase container is running
if ! docker compose ps | grep -q "periolifts_pocketbase.*Up"; then
    echo "❌ PocketBase container is not running."
    echo ""
    echo "Start it with: docker compose up -d"
    exit 1
fi
echo "✅ PocketBase container is running"

# Check if PocketBase API is accessible
if ! curl -s -f http://localhost:8090/api/health > /dev/null; then
    echo "❌ PocketBase API is not accessible at http://localhost:8090"
    echo ""
    echo "Check logs with: docker compose logs pocketbase"
    exit 1
fi
echo "✅ PocketBase API is accessible"

# Get health check response
HEALTH_RESPONSE=$(curl -s http://localhost:8090/api/health)
echo "✅ Health check response: $HEALTH_RESPONSE"

echo ""
echo "======================================"
echo "All checks passed! 🎉"
echo "======================================"
echo ""
echo "PocketBase URLs:"
echo "  - Admin UI: http://localhost:8090/_/"
echo "  - REST API: http://localhost:8090/api/"
echo ""
echo "To view logs: docker compose logs -f pocketbase"
echo "To stop:      docker compose down"
echo ""
