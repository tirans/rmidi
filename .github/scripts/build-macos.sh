#!/bin/bash
# build-macos.sh - Native macOS build script using py2app
set -euo pipefail

# Function to handle errors
handle_error() {
    local exit_code=$?
    echo "❌ Error occurred in build-macos.sh at line $1"
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

# Function to create setup.py for py2app
create_setup_py() {
    local app_type="$1"  # server or client
    local app_dir="$2"   # target directory
    
    echo "📝 Creating setup.py for $app_type..."
    
    local app_name
    local bundle_id
    local main_script
    local includes
    local packages
    
    if [ "$app_type" = "server" ]; then
        app_name="R2MIDI Server"
        bundle_id="com.r2midi.server"
        main_script="main.py"
        includes="server.main,server.api,server.midi,server.presets,server.version,server.config"
        packages="fastapi,uvicorn,pydantic,rtmidi,mido,httpx,dotenv,psutil,asyncio,json,urllib,ssl,socket,threading"
    else
        app_name="R2MIDI Client"
        bundle_id="com.r2midi.client"
        main_script="main.py"
        includes="r2midi_client.main,r2midi_client.ui,r2midi_client.api,r2midi_client.config"
        packages="PyQt6,httpx,dotenv,pydantic,psutil,json,urllib,ssl,socket,threading"
    fi
    
    cat > "$app_dir/setup.py" << EOF
#!/usr/bin/env python3
"""
Setup script for $app_name
"""
from setuptools import setup
import sys
import os
import json

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

APP = ['$main_script']
DATA_FILES = []

# Find and add data files
if os.path.exists('midi-presets'):
    DATA_FILES.append(('midi-presets', ['midi-presets']))

if os.path.exists('resources'):
    for root, dirs, files in os.walk('resources'):
        for file in files:
            rel_path = os.path.relpath(os.path.join(root, file), 'resources')
            DATA_FILES.append((os.path.dirname(rel_path), [os.path.join(root, file)]))

# Icon file
ICON_FILE = '../resources/r2midi.icns' if os.path.exists('../resources/r2midi.icns') else None

OPTIONS = {
    'argv_emulation': False,
    'plist': {
        'CFBundleName': '$app_name',
        'CFBundleDisplayName': '$app_name',
        'CFBundleIdentifier': '$bundle_id',
        'CFBundleVersion': '$APP_VERSION',
        'CFBundleShortVersionString': '$APP_VERSION',
        'CFBundleSignature': '$(echo $bundle_id | cut -c-4 | tr '[:lower:]' '[:upper:]')',
        'LSMinimumSystemVersion': '10.15.0',
        'LSBackgroundOnly': False,
        'NSHighResolutionCapable': True,
        'NSRequiresAquaSystemAppearance': False,
        'LSApplicationCategoryType': 'public.app-category.utilities',
        'NSHumanReadableCopyright': 'Copyright © 2024 R2MIDI Team',
    },
    'packages': [$(echo $packages | sed "s/,/', '/g" | sed "s/^/'/" | sed "s/$/'/")],
    'includes': [$(echo $includes | sed "s/,/', '/g" | sed "s/^/'/" | sed "s/$/'/")],
    'excludes': ['tkinter'],
    'resources': [],
    'iconfile': ICON_FILE,
    'strip': True,
    'optimize': 2,
    'compressed': True,
}

if __name__ == '__main__':
    setup(
        app=APP,
        data_files=DATA_FILES,
        options={'py2app': OPTIONS},
        setup_requires=['py2app'],
    )
EOF
    
    echo "✅ Setup script created for $app_type"
}

# Function to build applications with py2app
build_applications() {
    echo "🔨 Building macOS applications with native tools..."
    
    # Install py2app if not available
    if ! python -c "import py2app" 2>/dev/null; then
        echo "📦 Installing py2app..."
        retry_command "pip install py2app setuptools wheel" 3 10
    fi
    
    # Install project dependencies
    echo "📦 Installing project dependencies..."
    retry_command "pip install -r requirements.txt" 3 10
    
    if [ -f "r2midi_client/requirements.txt" ]; then
        retry_command "pip install -r r2midi_client/requirements.txt" 3 10
    fi
    
    # Prepare build environment
    echo "🔧 Preparing build environment..."
    mkdir -p build/{server,client,resources}
    mkdir -p dist/{server,client}
    
    # Copy source files
    echo "📁 Copying source files..."
    if [ -d "server" ]; then
        cp -r server/ build/server/
    fi
    if [ -d "r2midi_client" ]; then
        cp -r r2midi_client/ build/client/
    fi
    
    # Copy resources
    if [ -d "resources" ]; then
        cp -r resources/* build/resources/ 2>/dev/null || true
    fi
    
    # Ensure icon exists
    if [ -f "r2midi.icns" ] && [ ! -f "build/resources/r2midi.icns" ]; then
        cp r2midi.icns build/resources/r2midi.icns
    fi
    
    # Create setup scripts
    create_setup_py "server" "build/server"
    create_setup_py "client" "build/client"
    
    # Build server application
    echo "🏗️ Building server application..."
    cd build/server
    if retry_command "python setup.py py2app --dist-dir ../../dist/server" 3 20; then
        echo "✅ Server build successful"
    else
        echo "❌ Server build failed"
        echo "📋 Build log:"
        cat build/py2app.log 2>/dev/null || echo "No log file found"
        cd ../..
        return 1
    fi
    cd ../..
    
    # Build client application
    echo "🏗️ Building client application..."
    cd build/client
    if retry_command "python setup.py py2app --dist-dir ../../dist/client" 3 20; then
        echo "✅ Client build successful"
    else
        echo "❌ Client build failed"
        echo "📋 Build log:"
        cat build/py2app.log 2>/dev/null || echo "No log file found"
        cd ../..
        return 1
    fi
    cd ../..
    
    # Find built applications
    echo "🔍 Locating built applications..."
    
    # Find server app
    SERVER_APPS=($(find dist/server -name "*.app" -type d 2>/dev/null || true))
    if [ ${#SERVER_APPS[@]} -gt 0 ]; then
        SERVER_APP_PATH="$(realpath "${SERVER_APPS[0]}")"
        echo "✅ Server app: $SERVER_APP_PATH"
        
        # Verify executable exists
        SERVER_EXEC=$(find "$SERVER_APP_PATH/Contents/MacOS" -type f -perm +111 2>/dev/null | head -1)
        if [ -n "$SERVER_EXEC" ]; then
            echo "✅ Server executable: $SERVER_EXEC"
        else
            echo "⚠️ Server executable not found"
        fi
    else
        echo "❌ Server app not found in dist/server"
        ls -la dist/server/ 2>/dev/null || echo "dist/server directory not found"
    fi
    
    # Find client app
    CLIENT_APPS=($(find dist/client -name "*.app" -type d 2>/dev/null || true))
    if [ ${#CLIENT_APPS[@]} -gt 0 ]; then
        CLIENT_APP_PATH="$(realpath "${CLIENT_APPS[0]}")"
        echo "✅ Client app: $CLIENT_APP_PATH"
        
        # Verify executable exists
        CLIENT_EXEC=$(find "$CLIENT_APP_PATH/Contents/MacOS" -type f -perm +111 2>/dev/null | head -1)
        if [ -n "$CLIENT_EXEC" ]; then
            echo "✅ Client executable: $CLIENT_EXEC"
        else
            echo "⚠️ Client executable not found"
        fi
    else
        echo "❌ Client app not found in dist/client"
        ls -la dist/client/ 2>/dev/null || echo "dist/client directory not found"
    fi
    
    # Create artifacts directory structure
    mkdir -p build/artifacts
    
    # Generate build info
    cat > build/artifacts/build-info.txt << EOF
R2MIDI Native macOS Build Information
=====================================

Platform: macOS
Build Type: $BUILD_TYPE
Version: $APP_VERSION
Method: py2app (native)
Built: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Host: $(uname -a)
Xcode: $(xcode-select --print-path 2>/dev/null || echo "Not available")

Server App: ${SERVER_APP_PATH:-Not found}
Client App: ${CLIENT_APP_PATH:-Not found}
EOF
    
    echo "✅ Native macOS build complete"
    
    # Debug output
    echo "📁 Dist directory contents:"
    find dist -type d -name "*.app" 2>/dev/null || echo "No .app bundles found"
}

# Export variables for use by the action
export SERVER_APP_PATH
export CLIENT_APP_PATH

echo "🔧 macOS native build script loaded"
