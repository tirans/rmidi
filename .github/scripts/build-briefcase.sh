#!/bin/bash
# build-briefcase.sh - Briefcase build script for Windows/Linux platforms
set -euo pipefail

# Function to handle errors
handle_error() {
    local exit_code=$?
    echo "❌ Error occurred in build-briefcase.sh at line $1"
    echo "Exit code: $exit_code"
    return $exit_code
}

trap 'handle_error $LINENO' ERR

# Function to retry commands
retry_command() {
    local cmd="$1"
    local max_attempts="${2:-3}"
    local delay="${3:-5}"
    
    for attempt in $(seq 1 $max_attempts); do
        echo "🔄 Attempt $attempt/$max_attempts: $cmd"
        if eval "$cmd"; then
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                echo "⏳ Waiting ${delay}s before retry..."
                sleep $delay
            fi
        fi
    done
    
    echo "❌ Command failed after $max_attempts attempts: $cmd"
    return 1
}

# Function to build applications with Briefcase
build_applications() {
    echo "🔨 Building applications with Briefcase for $PLATFORM..."
    
    # Verify Briefcase is installed
    if ! command -v briefcase >/dev/null 2>&1; then
        echo "❌ Briefcase not found. Installing..."
        pip install briefcase
    fi
    
    # Validate pyproject.toml exists
    if [ ! -f "pyproject.toml" ]; then
        echo "❌ pyproject.toml not found in current directory"
        echo "Current directory: $(pwd)"
        echo "Contents:"
        ls -la
        exit 1
    fi
    
    echo "📋 Briefcase configuration check..."
    briefcase -V
    
    # Create applications
    echo "🏗️ Creating application structures..."
    retry_command "briefcase create $PLATFORM $APP_FORMAT -a server" 3 10
    retry_command "briefcase create $PLATFORM $APP_FORMAT -a r2midi-client" 3 10
    
    # Build applications
    echo "⚙️ Building applications..."
    retry_command "briefcase build $PLATFORM $APP_FORMAT -a server" 3 15
    retry_command "briefcase build $PLATFORM $APP_FORMAT -a r2midi-client" 3 15
    
    # Find built applications
    echo "🔍 Locating built applications..."
    
    # Look for server application
    if [ "$PLATFORM" = "linux" ]; then
        SERVER_PATTERN="build/server/linux/system/*/usr/bin/*"
        CLIENT_PATTERN="build/r2midi-client/linux/system/*/usr/bin/*"
    else
        # Windows
        SERVER_PATTERN="build/server/windows/app/*/*.exe"
        CLIENT_PATTERN="build/r2midi-client/windows/app/*/*.exe"
    fi
    
    # Find server app
    SERVER_APPS=($(find . -path "$SERVER_PATTERN" -type f 2>/dev/null || true))
    if [ ${#SERVER_APPS[@]} -gt 0 ]; then
        SERVER_APP_PATH="$(realpath "${SERVER_APPS[0]}")"
        echo "✅ Server app found: $SERVER_APP_PATH"
    else
        echo "⚠️ Server app not found with pattern: $SERVER_PATTERN"
        echo "Available build files:"
        find build -type f -name "*server*" 2>/dev/null || echo "No server files found"
    fi
    
    # Find client app
    CLIENT_APPS=($(find . -path "$CLIENT_PATTERN" -type f 2>/dev/null || true))
    if [ ${#CLIENT_APPS[@]} -gt 0 ]; then
        CLIENT_APP_PATH="$(realpath "${CLIENT_APPS[0]}")"
        echo "✅ Client app found: $CLIENT_APP_PATH"
    else
        echo "⚠️ Client app not found with pattern: $CLIENT_PATTERN"
        echo "Available build files:"
        find build -type f -name "*client*" 2>/dev/null || echo "No client files found"
    fi
    
    # Create artifacts directory structure
    mkdir -p build/artifacts
    
    # Copy applications to artifacts if found
    if [ -n "${SERVER_APP_PATH:-}" ]; then
        cp "$SERVER_APP_PATH" "build/artifacts/" 2>/dev/null || echo "⚠️ Could not copy server app to artifacts"
    fi
    
    if [ -n "${CLIENT_APP_PATH:-}" ]; then
        cp "$CLIENT_APP_PATH" "build/artifacts/" 2>/dev/null || echo "⚠️ Could not copy client app to artifacts"
    fi
    
    # Generate build info
    cat > build/artifacts/build-info.txt << EOF
R2MIDI Briefcase Build Information
==================================

Platform: $PLATFORM
Build Type: $BUILD_TYPE
Version: $APP_VERSION
Method: Briefcase
Format: $APP_FORMAT
Built: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Host: $(uname -a)

Server App: ${SERVER_APP_PATH:-Not found}
Client App: ${CLIENT_APP_PATH:-Not found}
EOF
    
    echo "✅ Briefcase build complete"
    
    # Debug output
    echo "📁 Build directory contents:"
    find build -type f | head -20
}

# Export variables for use by the action
export SERVER_APP_PATH
export CLIENT_APP_PATH

echo "🔧 Briefcase build script loaded"
