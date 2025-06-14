#!/bin/bash
set -euo pipefail

# Setup script for clean R2MIDI GitHub Actions workflows
# This script ensures the correct modular setup is in place

echo "🔧 Setting up clean R2MIDI GitHub Actions workflows..."

# Make all scripts executable
echo "📝 Making shell scripts executable..."
if [ -d ".github/scripts" ]; then
    find .github/scripts -name "*.sh" -exec chmod +x {} \;
    echo "✅ Made all shell scripts executable"
else
    echo "❌ Error: .github/scripts directory not found"
    exit 1
fi

# Validate the clean setup
echo "🔍 Validating clean workflow setup..."

# Check for required workflows (my solution)
required_workflows=(
    ".github/workflows/release.yml"
    ".github/workflows/ci.yml"
    ".github/workflows/build-windows.yml"
    ".github/workflows/build-linux.yml"
    ".github/workflows/build-macos.yml"
)

missing_workflows=()
for workflow in "${required_workflows[@]}"; do
    if [ ! -f "$workflow" ]; then
        missing_workflows+=("$workflow")
    fi
done

if [ ${#missing_workflows[@]} -gt 0 ]; then
    echo "❌ Missing required workflows:"
    printf '  - %s\n' "${missing_workflows[@]}"
    exit 1
else
    echo "✅ All required workflows present"
fi

# Check for required scripts (my solution)
required_scripts=(
    ".github/scripts/build-briefcase-apps.sh"
    ".github/scripts/sign-and-notarize-macos.sh"
    ".github/scripts/package-windows-apps.sh"
    ".github/scripts/package-linux-apps.sh"
    ".github/scripts/package-macos-apps.sh"
    ".github/scripts/update-version.sh"
    ".github/scripts/validate-build-environment.sh"
    ".github/scripts/validate-project-structure.sh"
    ".github/scripts/build-python-package.sh"
    ".github/scripts/prepare-release-artifacts.sh"
)

missing_scripts=()
for script in "${required_scripts[@]}"; do
    if [ ! -f "$script" ]; then
        missing_scripts+=("$script")
    elif [ ! -x "$script" ]; then
        echo "⚠️ Warning: $script is not executable"
    fi
done

if [ ${#missing_scripts[@]} -gt 0 ]; then
    echo "❌ Missing required scripts:"
    printf '  - %s\n' "${missing_scripts[@]}"
    exit 1
else
    echo "✅ All required scripts present and executable"
fi

# Verify that conflicting files have been moved
conflicting_files=(
    ".github/workflows/reusable-build.yml"
    ".github/workflows/reusable-test.yml"
    ".github/workflows/macos-native.yml"
    ".github/workflows/app-store.yml"
    ".github/scripts/build-briefcase.sh"
    ".github/scripts/build-macos.sh"
    ".github/actions"
)

echo "🧹 Checking that conflicting files have been cleaned up..."
for file in "${conflicting_files[@]}"; do
    if [ -e "$file" ]; then
        echo "⚠️ Warning: Conflicting file still exists: $file"
        echo "   This may cause issues with the clean workflow setup"
    fi
done

# Validate project structure if validation script exists
if [ -x ".github/scripts/validate-project-structure.sh" ]; then
    echo "🔍 Running project structure validation..."
    ./.github/scripts/validate-project-structure.sh || {
        echo "⚠️ Project structure validation completed with issues"
        echo "   Review the output above and fix any critical errors"
    }
fi

echo ""
echo "✅ Clean GitHub Actions workflow setup complete!"
echo ""
echo "📋 What's configured:"
echo "   🔄 Separated, modular workflows with external scripts"
echo "   🪟 Windows builds: Unsigned with Briefcase" 
echo "   🐧 Linux builds: Unsigned with Briefcase"
echo "   🍎 macOS builds: Signed & notarized PKG installers"
echo "   🐍 Python package: PyPI publishing with OIDC"
echo "   ✅ No inline code: All logic in external shell scripts"
echo ""
echo "📋 Next steps:"
echo "1. Configure GitHub secrets for macOS signing:"
echo "   - APPLE_CERTIFICATE_P12 (base64 encoded .p12 file)"
echo "   - APPLE_CERTIFICATE_PASSWORD"
echo "   - APPLE_ID (your Apple ID email)"
echo "   - APPLE_ID_PASSWORD (app-specific password)"
echo "   - APPLE_TEAM_ID (your Apple Developer Team ID)"
echo ""
echo "2. Test the workflows:"
echo "   - Push to master branch to trigger release workflow"
echo "   - Create pull request to trigger CI workflow"
echo ""
echo "🚀 Your R2MIDI project is ready for clean, automated builds!"