#!/bin/bash
# build-briefcase.sh - Resilient Briefcase build script for Windows/Linux platforms
set -euo pipefail

# Function to handle errors with comprehensive logging
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo "❌ Error occurred in build-briefcase.sh at line $line_number"
    echo "Exit code: $exit_code"
    
    # Log comprehensive debug information
    echo "🔍 Debug Information:"
    echo "Working directory: $(pwd)"
    echo "Platform: ${PLATFORM:-unknown}"
    echo "Build method: ${BUILD_METHOD:-unknown}"
    echo "Python version: $(python --version 2>/dev/null || echo 'Python not found')"
    echo "Briefcase version: $(briefcase --version 2>/dev/null || echo 'Briefcase not found')"
    
    # Check disk space and memory
    if command -v df >/dev/null 2>&1; then
        echo "Available disk space: $(df -h . 2>/dev/null | tail -1 | awk '{print $4}' || echo 'Unknown')"
    fi
    
    # Log recent briefcase activities
    if [ -d "build" ]; then
        echo "📁 Build directory status:"
        find build -name "*.log" -type f 2>/dev/null | head -5 | while read -r logfile; do
            echo "Recent log: $logfile"
            tail -10 "$logfile" 2>/dev/null || echo "Could not read log file"
        done
    fi
    
    return $exit_code
}

trap 'handle_error $LINENO' ERR

# Function to retry commands with intelligent backoff
retry_command() {
    local cmd="$1"
    local max_attempts="${2:-3}"
    local base_delay="${3:-5}"
    local timeout_duration="${4:-300}"
    
    for attempt in $(seq 1 $max_attempts); do
        local delay=$((base_delay * attempt))
        echo "🔄 Attempt $attempt/$max_attempts: $cmd"
        
        # Use timeout to prevent hanging commands
        if timeout "$timeout_duration" bash -c "$cmd" 2>&1; then
            echo "✅ Command succeeded on attempt $attempt"
            return 0
        else
            local exit_code=$?
            echo "⚠️ Command failed with exit code $exit_code"
            
            if [ $attempt -lt $max_attempts ]; then
                echo "⏳ Waiting ${delay}s before retry..."
                sleep $delay
                
                # Platform-specific cleanup
                echo "🧹 Cleaning up partial build state..."
                case "${PLATFORM:-}" in
                    linux)
                        # Clean up any stale processes or files
                        pkill -f briefcase 2>/dev/null || true
                        rm -rf /tmp/briefcase-* 2>/dev/null || true
                        ;;
                    windows)
                        # Clean up Windows-specific temporary files
                        rm -rf /tmp/briefcase-* 2>/dev/null || true
                        rm -rf build/*/windows/app/src/app_packages 2>/dev/null || true
                        ;;
                esac
                
                # General cleanup
                rm -rf build/*/build 2>/dev/null || true
                rm -rf dist/temp* 2>/dev/null || true
            fi
        fi
    done
    
    echo "❌ Command failed after $max_attempts attempts: $cmd"
    return 1
}

# Function to setup briefcase environment with validation
setup_briefcase_environment() {
    echo "🔧 Setting up Briefcase environment for ${PLATFORM}..."
    
    # Verify briefcase installation
    if ! command -v briefcase >/dev/null 2>&1; then
        echo "📦 Installing Briefcase..."
        retry_command "pip install briefcase>=0.3.21" 3 10
    fi
    
    # Verify briefcase works
    echo "📋 Validating Briefcase installation..."
    if ! briefcase --version >/dev/null 2>&1; then
        echo "❌ Briefcase installation validation failed"
        return 1
    fi
    
    # Platform-specific setup
    case "${PLATFORM}" in
        linux)
            echo "🐧 Linux-specific setup..."
            # Install system dependencies that might be needed
            if command -v apt-get >/dev/null 2>&1; then
                # Update package list without interactive prompts
                sudo apt-get update -qq 2>/dev/null || echo "⚠️ Could not update package list"
            fi
            ;;
        windows)
            echo "🪟 Windows-specific setup..."
            # Set Windows-specific environment variables
            export PYTHONIOENCODING=utf-8
            export PYTHONUNBUFFERED=1
            ;;
    esac
    
    echo "✅ Briefcase environment ready"
}

# Function to validate project structure with detailed feedback
validate_project_structure() {
    echo "🔍 Validating project structure for Briefcase..."
    
    local validation_errors=()
    
    # Essential files check
    [ ! -f "pyproject.toml" ] && validation_errors+=("pyproject.toml missing")
    [ ! -d "server" ] && validation_errors+=("server/ directory missing")
    [ ! -f "server/main.py" ] && validation_errors+=("server/main.py missing")
    [ ! -d "r2midi_client" ] && validation_errors+=("r2midi_client/ directory missing")
    [ ! -f "r2midi_client/main.py" ] && validation_errors+=("r2midi_client/main.py missing")
    
    if [ ${#validation_errors[@]} -gt 0 ]; then
        echo "❌ Project validation failed:"
        printf '  - %s\n' "${validation_errors[@]}"
        return 1
    fi
    
    # Briefcase configuration validation
    echo "📋 Checking Briefcase configuration..."
    if ! python -c "
import tomllib
with open('pyproject.toml', 'rb') as f:
    config = tomllib.load(f)
assert 'tool' in config, 'No [tool] section'
assert 'briefcase' in config['tool'], 'No [tool.briefcase] section'
assert 'app' in config['tool']['briefcase'], 'No apps configured'
print('✅ Briefcase configuration valid')
" 2>/dev/null; then
        echo "❌ Invalid Briefcase configuration in pyproject.toml"
        return 1
    fi
    
    echo "✅ Project structure validation passed"
}

# Function to clean build environment safely
clean_build_environment() {
    echo "🧹 Cleaning build environment..."
    
    # Remove build artifacts with proper error handling
    local dirs_to_clean=(
        "build/*/logs"
        "build/*/temp*"
        "dist/temp*"
        ".briefcase-*"
    )
    
    for pattern in "${dirs_to_clean[@]}"; do
        if ls $pattern >/dev/null 2>&1; then
            rm -rf $pattern
        fi
    done
    
    # Platform-specific cleanup
    case "${PLATFORM:-}" in
        linux)
            # Clean up Linux-specific temporary files
            rm -rf ~/.cache/briefcase 2>/dev/null || true
            ;;
        windows)
            # Clean up Windows-specific files
            rm -rf ~/.cache/briefcase 2>/dev/null || true
            ;;
    esac
    
    echo "✅ Build environment cleaned"
}

# Function to build applications with enhanced monitoring
build_applications() {
    echo "🔨 Building applications with Briefcase for ${PLATFORM}..."
    
    # Setup and validation
    setup_briefcase_environment
    validate_project_structure
    clean_build_environment
    
    # Determine app format based on platform
    case "${PLATFORM}" in
        linux)
            APP_FORMAT="system"
            ;;
        windows)
            APP_FORMAT="app"
            ;;
        *)
            echo "❌ Unsupported platform: ${PLATFORM}"
            return 1
            ;;
    esac
    
    echo "📋 Build configuration:"
    echo "  Platform: ${PLATFORM}"
    echo "  Format: ${APP_FORMAT}"
    echo "  Version: ${APP_VERSION:-1.0.0}"
    echo "  Type: ${BUILD_TYPE:-development}"
    
    # Create applications with enhanced error handling
    echo "🏗️ Creating application structures..."
    
    # Create server app
    if retry_command "briefcase create ${PLATFORM} ${APP_FORMAT} -a server --no-input" 3 15; then
        echo "✅ Server app structure created"
    else
        echo "❌ Failed to create server app structure"
        return 1
    fi
    
    # Create client app
    if retry_command "briefcase create ${PLATFORM} ${APP_FORMAT} -a r2midi-client --no-input" 3 15; then
        echo "✅ Client app structure created"
    else
        echo "❌ Failed to create client app structure"
        return 1
    fi
    
    # Build applications with monitoring
    echo "⚙️ Building applications..."
    
    # Build server with enhanced monitoring
    echo "🔧 Building server application..."
    if retry_command "briefcase build ${PLATFORM} ${APP_FORMAT} -a server --no-input" 3 20 600; then
        echo "✅ Server application built successfully"
    else
        echo "❌ Server application build failed"
        
        # Try to get more information about the failure
        echo "📋 Server build diagnostics:"
        find build -path "*/server/*" -name "*.log" -type f 2>/dev/null | head -3 | while read -r logfile; do
            echo "=== $logfile ==="
            tail -20 "$logfile" 2>/dev/null || echo "Could not read log"
        done
        
        return 1
    fi
    
    # Build client with enhanced monitoring
    echo "🔧 Building client application..."
    if retry_command "briefcase build ${PLATFORM} ${APP_FORMAT} -a r2midi-client --no-input" 3 20 600; then
        echo "✅ Client application built successfully"
    else
        echo "❌ Client application build failed"
        
        # Try to get more information about the failure
        echo "📋 Client build diagnostics:"
        find build -path "*/r2midi-client/*" -name "*.log" -type f 2>/dev/null | head -3 | while read -r logfile; do
            echo "=== $logfile ==="
            tail -20 "$logfile" 2>/dev/null || echo "Could not read log"
        done
        
        return 1
    fi
    
    echo "✅ Briefcase build complete"
    
    # Locate built applications with proper error handling
    echo "🔍 Locating built applications..."
    
    # Platform-specific patterns for finding executables
    case "${PLATFORM}" in
        linux)
            SERVER_PATTERN="build/server/ubuntu/*/server-*/usr/bin/server*"
            CLIENT_PATTERN="build/r2midi-client/ubuntu/*/r2midi-client-*/usr/bin/r2midi-client*"
            ;;
        windows)
            SERVER_PATTERN="build/server/windows/app/src/server.exe"
            CLIENT_PATTERN="build/r2midi-client/windows/app/src/r2midi-client.exe"
            ;;
    esac
    
    # Find server app safely using null-terminated search to avoid broken pipe
    SERVER_APP_PATH=""
    while IFS= read -r -d '' app_path; do
        if [ -f "$app_path" ] && [ -x "$app_path" ]; then
            SERVER_APP_PATH="$(realpath "$app_path")"
            echo "✅ Server app found: $SERVER_APP_PATH"
            break
        fi
    done < <(find . -path "$SERVER_PATTERN" -type f -executable -print0 2>/dev/null)
    
    # Find client app safely using null-terminated search to avoid broken pipe
    CLIENT_APP_PATH=""
    while IFS= read -r -d '' app_path; do
        if [ -f "$app_path" ] && [ -x "$app_path" ]; then
            CLIENT_APP_PATH="$(realpath "$app_path")"
            echo "✅ Client app found: $CLIENT_APP_PATH"
            break
        fi
    done < <(find . -path "$CLIENT_PATTERN" -type f -executable -print0 2>/dev/null)
    
    # Fallback search if primary patterns didn't work
    if [ -z "$SERVER_APP_PATH" ]; then
        echo "🔍 Performing fallback search for server app..."
        while IFS= read -r -d '' app_path; do
            if [[ "$app_path" == *server* ]] && [ -x "$app_path" ]; then
                SERVER_APP_PATH="$(realpath "$app_path")"
                echo "✅ Server app found (fallback): $SERVER_APP_PATH"
                break
            fi
        done < <(find build -name "*server*" -type f -executable -print0 2>/dev/null)
    fi
    
    if [ -z "$CLIENT_APP_PATH" ]; then
        echo "🔍 Performing fallback search for client app..."
        while IFS= read -r -d '' app_path; do
            if [[ "$app_path" == *client* ]] && [ -x "$app_path" ]; then
                CLIENT_APP_PATH="$(realpath "$app_path")"
                echo "✅ Client app found (fallback): $CLIENT_APP_PATH"
                break
            fi
        done < <(find build -name "*client*" -type f -executable -print0 2>/dev/null)
    fi
    
    # Report findings
    if [ -z "$SERVER_APP_PATH" ]; then
        echo "⚠️ Server app not found"
        echo "📁 Available server files:"
        find build -path "*server*" -type f 2>/dev/null | head -10 || echo "No server files found"
    fi
    
    if [ -z "$CLIENT_APP_PATH" ]; then
        echo "⚠️ Client app not found"
        echo "📁 Available client files:"
        find build -path "*client*" -type f 2>/dev/null | head -10 || echo "No client files found"
    fi
    
    # Create artifacts directory and prepare outputs
    mkdir -p build/artifacts
    
    # Copy applications to artifacts if found (with error handling)
    if [ -n "$SERVER_APP_PATH" ] && [ -f "$SERVER_APP_PATH" ]; then
        cp "$SERVER_APP_PATH" build/artifacts/ 2>/dev/null && echo "✅ Server app copied to artifacts" || echo "⚠️ Could not copy server app"
    fi
    
    if [ -n "$CLIENT_APP_PATH" ] && [ -f "$CLIENT_APP_PATH" ]; then
        cp "$CLIENT_APP_PATH" build/artifacts/ 2>/dev/null && echo "✅ Client app copied to artifacts" || echo "⚠️ Could not copy client app"
    fi
    
    # Generate comprehensive build information
    cat > build/artifacts/build-info.txt << BUILD_INFO_EOF
R2MIDI Briefcase Build Information
==================================

Platform: ${PLATFORM}
Build Type: ${BUILD_TYPE:-development}
Version: ${APP_VERSION:-1.0.0}
Method: Briefcase
Format: ${APP_FORMAT}
Built: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Host: $(uname -a)
Python: $(python --version 2>/dev/null || echo "Unknown")
Briefcase: $(briefcase --version 2>/dev/null || echo "Unknown")

Build Results:
Server App: ${SERVER_APP_PATH:-Not found}
Client App: ${CLIENT_APP_PATH:-Not found}

Build Quality Checks:
- Project validation: ✅ Passed
- Environment setup: ✅ Completed
- Create phase: ✅ Successful
- Build phase: ✅ Completed
- App location: $([ -n "$SERVER_APP_PATH" ] && [ -n "$CLIENT_APP_PATH" ] && echo "✅ Both found" || echo "⚠️ Some missing")
- Error handling: ✅ Retry mechanism active
- Resource cleanup: ✅ Performed

Build Process Summary:
$([ -n "$SERVER_APP_PATH" ] && echo "✅ Server build successful" || echo "❌ Server build failed")
$([ -n "$CLIENT_APP_PATH" ] && echo "✅ Client build successful" || echo "❌ Client build failed")
BUILD_INFO_EOF
    
    echo "✅ Briefcase build process completed"
    
    # Final validation and return appropriate exit code
    local build_success=true
    if [ -z "$SERVER_APP_PATH" ]; then
        echo "⚠️ Server application not built successfully"
        build_success=false
    fi
    if [ -z "$CLIENT_APP_PATH" ]; then
        echo "⚠️ Client application not built successfully"
        build_success=false
    fi
    
    if [ "$build_success" = "false" ]; then
        echo "❌ Build completed with warnings - some applications may not be available"
        
        # Additional debug output for failed builds
        echo "📁 Build directory structure for debugging:"
        find build -type f -name "*" 2>/dev/null | head -20 | sed 's/^/  /'
        
        return 1
    fi
    
    echo "✅ All applications built successfully"
}

# Export variables for GitHub Actions
export SERVER_APP_PATH
export CLIENT_APP_PATH

echo "🔧 Enhanced Briefcase build script loaded for ${PLATFORM:-unknown}"
