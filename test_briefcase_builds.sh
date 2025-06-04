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

# Function to test an app
test_app() {
    local app_name=$1
    echo ""
    echo "Testing $app_name..."
    echo "-------------------"
    
    # Create
    echo "Creating $app_name..."
    if briefcase create $app_name; then
        echo "✅ Create successful"
    else
        echo "❌ Create failed for $app_name"
        return 1
    fi
    
    # Build
    echo "Building $app_name..."
    if briefcase build $app_name; then
        echo "✅ Build successful"
    else
        echo "❌ Build failed for $app_name"
        return 1
    fi
    
    # Run (optional - comment out if you don't want to launch)
    echo "Would you like to run $app_name? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        briefcase run $app_name
    fi
    
    return 0
}

# Main execution
echo ""
echo "Starting Briefcase tests..."

# Test server app
if test_app "r2midi"; then
    echo "✅ Server app (r2midi) passed all tests"
else
    echo "❌ Server app (r2midi) failed"
    exit 1
fi

# Test client app
if test_app "r2midic"; then
    echo "✅ Client app (r2midic) passed all tests"
else
    echo "❌ Client app (r2midic) failed"
    exit 1
fi

# Package apps (without signing for local test)
echo ""
echo "Would you like to package the apps? (y/n)"
read -r response
if [[ "$response" == "y" ]]; then
    echo "Packaging r2midi..."
    briefcase package r2midi --no-sign
    
    echo "Packaging r2midic..."
    briefcase package r2midic --no-sign
    
    echo ""
    echo "Packages created! Check the build directory for output files."
    
    # Show what was created
    echo ""
    echo "Build outputs:"
    echo "--------------"
    
    # Find and display package files
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        find build -name "*.dmg" -o -name "*.app" | grep -E "(dmg|app)$"
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
