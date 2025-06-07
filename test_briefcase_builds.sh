#!/bin/bash
# Test Briefcase builds locally before pushing to GitHub

echo "R2MIDI Briefcase Build Test Script"
echo "=================================="

# Check if briefcase is installed
if ! command -v briefcase &> /dev/null; then
    echo "❌ Briefcase is not installed!"
    echo "Please install with: pip install briefcase"
    exit 1
fi

echo "✅ Briefcase is installed"

# Clean build directory if it exists
if [ -d "build" ]; then
    echo "Cleaning build directory..."
    find build -mindepth 1 -delete
    echo "✅ Build directory cleaned"
else
    echo "⚠️ Build directory not found, will be created during build"
fi

# Function to test an app
test_app() {
    local app_name=$1
    local platform=$2
    echo ""
    echo "Testing $app_name on $platform..."
    echo "-------------------"

    # Create
    echo "Creating $app_name..."
    if briefcase create $platform app -a $app_name; then
        echo "✅ Create successful"
    else
        echo "❌ Create failed for $app_name"
        return 1
    fi

    # Build
    echo "Building $app_name..."
    if [[ "$platform" == "linux" ]]; then
        # For Linux, use the system target
        if briefcase build $platform app -a $app_name --target system; then
            echo "✅ Build successful"
        else
            echo "❌ Build failed for $app_name"
            return 1
        fi
    else
        # For other platforms
        if briefcase build $platform app -a $app_name; then
            echo "✅ Build successful"
        else
            echo "❌ Build failed for $app_name"
            return 1
        fi
    fi

    # Run (optional - comment out if you don't want to launch)
    echo "Would you like to run $app_name? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        briefcase run $platform app -a $app_name
    fi

    return 0
}

# Detect platform or use command line argument
if [[ $# -gt 0 ]]; then
    PLATFORM="$1"
    echo "Using platform from command line: $PLATFORM"
else
    if [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macOS"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        PLATFORM="windows"
    else
        PLATFORM="linux"
    fi
    echo "Detected platform: $PLATFORM"
fi

# Main execution
echo ""
echo "Starting Briefcase tests..."

# Test server app
if test_app "server" "$PLATFORM"; then
    echo "✅ Server app (server) passed all tests"
else
    echo "❌ Server app (server) failed"
    exit 1
fi

# Test client app
if test_app "r2midi-client" "$PLATFORM"; then
    echo "✅ Client app (r2midi-client) passed all tests"
else
    echo "❌ Client app (r2midi-client) failed"
    exit 1
fi

# Package apps (without signing for local test)
echo ""
echo "Would you like to package the apps? (y/n)"
read -r response
if [[ "$response" == "y" ]]; then
    echo "Packaging server..."
    if [[ "$PLATFORM" == "linux" ]]; then
        # For Linux, don't use --no-sign as we're using system target
        briefcase package $PLATFORM app -a server
    elif [[ "$PLATFORM" == "windows" ]]; then
        # For Windows, don't use --no-sign as it's configured in pyproject.toml
        briefcase package $PLATFORM app -a server
    else
        # For other platforms (macOS)
        briefcase package $PLATFORM app -a server --no-sign
    fi

    echo "Packaging r2midi-client..."
    if [[ "$PLATFORM" == "linux" ]]; then
        # For Linux, don't use --no-sign as we're using system target
        briefcase package $PLATFORM app -a r2midi-client
    elif [[ "$PLATFORM" == "windows" ]]; then
        # For Windows, don't use --no-sign as it's configured in pyproject.toml
        briefcase package $PLATFORM app -a r2midi-client
    else
        # For other platforms (macOS)
        briefcase package $PLATFORM app -a r2midi-client --no-sign
    fi

    echo ""
    echo "Packages created! Check the build directory for output files."

    # Show what was created
    echo ""
    echo "Build outputs:"
    echo "--------------"

    # Find and display package files
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        find build -name "*.dmg" -o -name "*.app" -o -name "*.pkg" | grep -E "(dmg|app|pkg)$"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows
        find build -name "*.msi" -o -name "*.exe" | grep -E "(msi|exe)$"
    else
        # Linux
        find build -name "*.AppImage" -o -name "*.deb" -o -name "*.tar.gz" | grep -E "(AppImage|deb|tar.gz)$"
    fi
fi

echo ""
echo "✅ All tests completed!"
echo ""
echo "Next steps:"
echo "1. Fix any issues found during testing"
echo "2. Create proper icons (run: bash setup_icons.sh)"
echo "3. Update .github/workflows/python-package.yml with the improved version"
echo "4. Commit and push to trigger the build"
