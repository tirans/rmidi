#!/bin/bash
set -euo pipefail

# CI-only version comparison between version.py and pyproject.toml
# This script should only be called from GitHub Actions CI

# Check if we're in CI environment
if [ -z "${GITHUB_ACTIONS:-}" ]; then
    echo "⚠️ This script should only run in CI environment"
    exit 0
fi

echo "🔍 Comparing versions between version.py and pyproject.toml..."

# Extract version from server/version.py
VERSION_PY=""
if [ -f "server/version.py" ]; then
    VERSION_PY=$(grep -o '__version__ = "[^"]*"' server/version.py | head -1 | cut -d'"' -f2 | tr -d '\n\r' | xargs)
fi

# Extract version from pyproject.toml
VERSION_TOML=""
if [ -f "pyproject.toml" ]; then
    VERSION_TOML=$(grep '^version = ' pyproject.toml | head -1 | cut -d'"' -f2 | tr -d '\n\r' | xargs)
fi

# Validate we found both versions
if [ -z "$VERSION_PY" ]; then
    echo "❌ Error: Could not extract version from server/version.py"
    exit 1
fi

if [ -z "$VERSION_TOML" ]; then
    echo "❌ Error: Could not extract version from pyproject.toml"
    exit 1
fi

echo "📋 Found versions:"
echo "   server/version.py: $VERSION_PY"
echo "   pyproject.toml:    $VERSION_TOML"

# Compare versions
if [ "$VERSION_PY" = "$VERSION_TOML" ]; then
    echo "✅ Versions match: $VERSION_PY"
    
    # Set GitHub outputs
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        echo "version=$VERSION_PY" >> "$GITHUB_OUTPUT"
        echo "versions_match=true" >> "$GITHUB_OUTPUT"
    fi
    
    exit 0
else
    echo "❌ Version mismatch detected!"
    echo "   server/version.py has: $VERSION_PY"
    echo "   pyproject.toml has:    $VERSION_TOML"
    echo ""
    echo "💡 To fix this, update one of the files to match the other:"
    echo "   1. Update server/version.py to: __version__ = \"$VERSION_TOML\""
    echo "   2. Or update pyproject.toml version to: \"$VERSION_PY\""
    
    # Set GitHub outputs
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        echo "version_py=$VERSION_PY" >> "$GITHUB_OUTPUT"
        echo "version_toml=$VERSION_TOML" >> "$GITHUB_OUTPUT"
        echo "versions_match=false" >> "$GITHUB_OUTPUT"
    fi
    
    exit 1
fi
