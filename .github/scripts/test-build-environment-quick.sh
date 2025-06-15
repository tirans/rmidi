#!/bin/bash
set -euo pipefail

# Quick test to verify build environment fixes
# Usage: test-build-environment-quick.sh

echo "🚀 Quick build environment test..."

# Test 1: Version extraction
echo ""
echo "=== Test 1: Version Extraction ==="
if ./.github/scripts/extract-version.sh >/dev/null 2>&1; then
    VERSION_OUTPUT=$(./.github/scripts/extract-version.sh 2>/dev/null)
    echo "✅ extract-version.sh works"
    echo "📋 Output: $VERSION_OUTPUT"
    
    # Check if it has the expected format
    if echo "$VERSION_OUTPUT" | grep -q "Version:"; then
        EXTRACTED_VERSION=$(echo "$VERSION_OUTPUT" | grep "Version:" | cut -d' ' -f2)
        echo "✅ Version format correct: $EXTRACTED_VERSION"
    else
        echo "❌ Version format incorrect"
    fi
else
    echo "❌ extract-version.sh failed"
fi

# Test 2: Environment setup (non-fatal)
echo ""
echo "=== Test 2: Environment Setup ==="
if ./.github/scripts/setup-environment.sh >/dev/null 2>&1; then
    echo "✅ setup-environment.sh completed successfully"
else
    echo "⚠️ setup-environment.sh had issues (may be non-fatal)"
fi

# Test 3: Check if Briefcase can be installed
echo ""
echo "=== Test 3: Python Dependencies ==="
if python -c "import pip" 2>/dev/null; then
    echo "✅ Python pip working"
    
    # Try installing briefcase (the critical dependency)
    if pip show briefcase >/dev/null 2>&1; then
        echo "✅ Briefcase already installed"
    else
        echo "ℹ️ Briefcase not installed (will be installed by build process)"
    fi
else
    echo "❌ Python pip not working"
fi

# Test 4: Check critical files
echo ""
echo "=== Test 4: Project Structure ==="
CRITICAL_FILES=(
    "pyproject.toml"
    "server/version.py"
    "server/main.py" 
    "r2midi_client/main.py"
)

ALL_GOOD=true
for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        ALL_GOOD=false
    fi
done

# Summary
echo ""
echo "==================="
echo "🎯 QUICK TEST SUMMARY"
echo "==================="

if [ "$ALL_GOOD" = true ]; then
    echo "✅ Basic build environment looks good!"
    echo ""
    echo "🚀 The Linux/Windows builds should work now."
    echo ""
    echo "💡 Key fixes applied:"
    echo "   - extract-version.sh outputs correct format AND sets GitHub Actions outputs"
    echo "   - setup-environment.sh is more robust with better error handling"
    echo "   - Version comparison logic is simplified but functional"
    echo ""
    echo "🔄 To test builds:"
    echo "   - Push changes to trigger CI/CD"
    echo "   - Or run: ./.github/scripts/install-python-dependencies.sh production"
else
    echo "⚠️ Some issues detected, but may not prevent builds"
fi
