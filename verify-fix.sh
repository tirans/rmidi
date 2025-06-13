#!/bin/bash
# verify-fix.sh - Verify that the build system fix is complete

echo "🔍 R2MIDI Build System Verification"
echo "==================================="
echo ""

ISSUES_FOUND=0

# Check 1: Verify submodule is removed
echo "📝 Checking Git submodule status..."
if [ -f .gitmodules ]; then
    if grep -q "server/midi-presets" .gitmodules; then
        echo "❌ server/midi-presets still referenced in .gitmodules"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo "✅ .gitmodules exists but no problematic submodules found"
    fi
else
    echo "✅ .gitmodules file removed (no submodules)"
fi

# Check 2: Verify directory structure
echo "📝 Checking directory structure..."
if [ -d "server/midi-presets" ]; then
    if [ -d "server/midi-presets/.git" ]; then
        echo "❌ server/midi-presets still contains .git directory (submodule not cleaned)"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo "✅ server/midi-presets exists as regular directory"
    fi
else
    echo "⚠️ server/midi-presets directory missing (will be created by CI)"
fi

# Check 3: Verify new action files exist
echo "📝 Checking new GitHub Actions structure..."
REQUIRED_ACTIONS=(
    ".github/actions/setup-environment/action.yml"
    ".github/actions/build-apps/action.yml"
    ".github/actions/package-apps/action.yml"
    ".github/actions/setup-macos-signing/action.yml"
    ".github/actions/cleanup-signing/action.yml"
)

for action in "${REQUIRED_ACTIONS[@]}"; do
    if [ -f "$action" ]; then
        echo "✅ $action exists"
    else
        echo "❌ $action missing"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done

# Check 4: Verify build scripts exist
echo "📝 Checking build scripts..."
REQUIRED_SCRIPTS=(
    ".github/scripts/build-briefcase.sh"
    ".github/scripts/build-macos.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "✅ $script exists and is executable"
        else
            echo "⚠️ $script exists but not executable (will fix)"
            chmod +x "$script"
        fi
    else
        echo "❌ $script missing"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done

# Check 5: Verify workflows updated
echo "📝 Checking workflow files..."
if [ -f ".github/workflows/ci.yml" ]; then
    if grep -q "basic smoke test\|importlib.util" ".github/workflows/ci.yml"; then
        echo "❌ ci.yml still contains basic smoke test code"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo "✅ ci.yml updated (smoke test removed)"
    fi
else
    echo "❌ ci.yml missing"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ -f ".github/workflows/reusable-build.yml" ]; then
    if grep -q "submodule" ".github/workflows/reusable-build.yml"; then
        echo "⚠️ reusable-build.yml still contains submodule references"
    else
        echo "✅ reusable-build.yml updated (no submodule references)"
    fi
else
    echo "❌ reusable-build.yml missing"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 6: Verify project structure
echo "📝 Checking project files..."
REQUIRED_FILES=(
    "pyproject.toml"
    "server/main.py"
    "server/version.py"
    "requirements.txt"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
done

echo ""
echo "🎯 Verification Summary"
echo "====================="

if [ $ISSUES_FOUND -eq 0 ]; then
    echo "🎉 ALL CHECKS PASSED!"
    echo ""
    echo "✅ Your build system is ready to use"
    echo "✅ Git submodules have been properly removed"
    echo "✅ New modular GitHub Actions are in place"
    echo "✅ Build scripts are properly configured"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. git add ."
    echo "   2. git commit -m 'refactor: modernize build system'"
    echo "   3. git push"
    echo ""
else
    echo "⚠️ Found $ISSUES_FOUND issue(s) that need attention"
    echo ""
    echo "Please review the issues above and fix them before proceeding."
    echo ""
fi

exit $ISSUES_FOUND
