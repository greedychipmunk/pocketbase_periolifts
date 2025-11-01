@echo off
:: PocketBase User Email Verification Wrapper Script (Windows)
:: This script ensures environment variables are properly passed to the Dart script

setlocal enabledelayedexpansion

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

:: Change to scripts directory
cd /d "%SCRIPT_DIR%"

echo [INFO] 🚀 PocketBase User Email Verification
echo [INFO] =====================================

:: Check if email argument is provided
if "%~1"=="" (
    echo [ERROR] Email address is required
    echo.
    echo Usage: %0 ^<email^>
    echo.
    echo Environment variables required:
    echo   POCKETBASE_ADMIN_EMAIL     - Admin email for PocketBase
    echo   POCKETBASE_ADMIN_PASSWORD  - Admin password for PocketBase
    echo.
    echo Optional environment variables:
    echo   POCKETBASE_URL            - PocketBase URL ^(default: http://localhost:8090^)
    exit /b 1
)

set "EMAIL=%~1"

:: Check if required environment variables are set
if "%POCKETBASE_ADMIN_EMAIL%"=="" (
    echo [ERROR] POCKETBASE_ADMIN_EMAIL environment variable is not set
    echo [INFO] Please set it using: set POCKETBASE_ADMIN_EMAIL=your_admin_email
    exit /b 1
)

if "%POCKETBASE_ADMIN_PASSWORD%"=="" (
    echo [ERROR] POCKETBASE_ADMIN_PASSWORD environment variable is not set
    echo [INFO] Please set it using: set POCKETBASE_ADMIN_PASSWORD=your_admin_password
    exit /b 1
)

if "%POCKETBASE_URL%"=="" set "POCKETBASE_URL=http://localhost:8090"

echo [INFO] 📧 Target email: %EMAIL%
echo [INFO] 🔐 Admin email: %POCKETBASE_ADMIN_EMAIL%
echo [INFO] 🌐 PocketBase URL: %POCKETBASE_URL%
echo.

:: Ensure dependencies are installed
echo [INFO] 📦 Installing Dart dependencies...
dart pub get >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to install Dart dependencies
    echo [INFO] Make sure you're in the scripts directory and have a valid pubspec.yaml
    exit /b 1
)

echo [SUCCESS] ✅ Dependencies installed
echo.

:: Run the Dart script with explicit environment variable passing
echo [INFO] 🎯 Running email verification script...
dart verify_user_email.dart "%EMAIL%"
if errorlevel 1 (
    echo [ERROR] Email verification failed
    exit /b 1
)

echo [SUCCESS] 🎉 Email verification completed successfully!