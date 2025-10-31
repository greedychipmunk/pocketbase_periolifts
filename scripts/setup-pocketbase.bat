@echo off
setlocal enabledelayedexpansion

REM PerioLifts PocketBase Setup Script for Windows
REM This script downloads, configures, and runs PocketBase locally for development

set POCKETBASE_VERSION=0.23.0
set POCKETBASE_DIR=.\pocketbase
set POCKETBASE_BINARY=%POCKETBASE_DIR%\pocketbase.exe
set POCKETBASE_DATA_DIR=%POCKETBASE_DIR%\pb_data
set POCKETBASE_URL=http://localhost:8090

echo =========================================
echo      PerioLifts PocketBase Setup
echo =========================================
echo.

REM Parse command line arguments
if "%1"=="start" goto :start_server
if "%1"=="clean" goto :clean_installation
if "%1"=="help" goto :show_help
if "%1"=="-h" goto :show_help
if "%1"=="--help" goto :show_help

REM Main installation flow
call :log_info "Detecting system architecture..."
call :detect_platform

call :log_info "Checking for existing PocketBase installation..."
if exist "%POCKETBASE_BINARY%" (
    call :log_info "PocketBase binary found. Checking version..."
    goto :check_version
) else (
    call :log_info "PocketBase not found. Downloading..."
    goto :download_pocketbase
)

:check_version
REM Simple version check - if binary exists, assume it's correct for now
call :log_success "PocketBase found!"
goto :start_server_after_setup

:download_pocketbase
call :log_info "Downloading PocketBase v%POCKETBASE_VERSION% for Windows..."

REM Create pocketbase directory
if not exist "%POCKETBASE_DIR%" mkdir "%POCKETBASE_DIR%"

REM Download URL for Windows
set DOWNLOAD_URL=https://github.com/pocketbase/pocketbase/releases/download/v%POCKETBASE_VERSION%/pocketbase_%POCKETBASE_VERSION%_windows_amd64.zip
set ZIP_FILE=%POCKETBASE_DIR%\pocketbase.zip

REM Download using PowerShell (available on Windows 7+)
call :log_info "Downloading from: %DOWNLOAD_URL%"
powershell -Command "& {Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'}" 2>nul
if !errorlevel! neq 0 (
    call :log_error "Failed to download PocketBase. Please check your internet connection."
    exit /b 1
)

REM Extract using PowerShell
call :log_info "Extracting PocketBase..."
powershell -Command "& {Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%POCKETBASE_DIR%' -Force}" 2>nul
if !errorlevel! neq 0 (
    call :log_error "Failed to extract PocketBase."
    exit /b 1
)

REM Clean up
del "%ZIP_FILE%" 2>nul

call :log_success "PocketBase downloaded and extracted successfully!"
goto :start_server_after_setup

:start_server
if not exist "%POCKETBASE_BINARY%" (
    call :log_error "PocketBase is not installed. Run without arguments to install first."
    exit /b 1
)
goto :start_pocketbase

:start_server_after_setup
call :log_info ""
call :log_info "Setup complete! Starting PocketBase server..."
call :log_info ""

:start_pocketbase
call :log_info "Starting PocketBase server..."
call :log_info "Server will be available at: %POCKETBASE_URL%"
call :log_info "Admin UI will be available at: %POCKETBASE_URL%/_/"
call :log_info ""
call :log_info "Press Ctrl+C to stop the server"
call :log_info ""

REM Start PocketBase with custom settings
"%POCKETBASE_BINARY%" serve --dir="%POCKETBASE_DATA_DIR%" --http="0.0.0.0:8090" --dev
goto :eof

:clean_installation
call :log_info "Cleaning PocketBase installation..."
if exist "%POCKETBASE_DIR%" (
    rmdir /s /q "%POCKETBASE_DIR%" 2>nul
    call :log_success "PocketBase installation removed!"
) else (
    call :log_info "No PocketBase installation found."
)
exit /b 0

:show_help
echo Usage: %0 [command]
echo.
echo Commands:
echo   (no args)  Install and start PocketBase
echo   start      Start PocketBase server (if already installed)
echo   clean      Remove PocketBase installation
echo   help       Show this help message
echo.
exit /b 0

:detect_platform
REM For Windows, we'll assume amd64 architecture
REM Modern Windows systems are primarily x64
set ARCH=amd64
call :log_info "Detected platform: Windows-%ARCH%"
goto :eof

REM Logging functions
:log_info
echo [INFO] %~1
goto :eof

:log_success
echo [SUCCESS] %~1
goto :eof

:log_warning
echo [WARNING] %~1
goto :eof

:log_error
echo [ERROR] %~1
goto :eof