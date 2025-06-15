#!/bin/bash
set -euo pipefail

# Quick test script to validate the fixed validation script
echo "🧪 Testing the fixed validation script..."

cd /Users/tirane/Desktop/r2midi

# Test the version extraction fix
echo "📋 Testing version extraction..."

# Extract versions using the new method
pyproject_version=$(grep '^version = ' pyproject.toml | head -1 | cut -d'"' -f2 | tr -d '\n\r')
server_version=$(grep '__version__ = ' server/version.py | head -1 | cut -d'"' -f2 | tr -d '\n\r')

echo "Extracted versions:"
echo "  pyproject.toml: '$pyproject_version'"
echo "  server/version.py: '$server_version'"

if [ "$pyproject_version" = "$server_version" ]; then
    echo "✅ Version extraction works correctly!"
else
    echo "❌ Version extraction still has issues"
fi

echo ""
echo "🔧 Making scripts executable..."
chmod +x .github/scripts/*.sh

echo ""
echo "🏃‍♂️ Running the fixed validation script..."
./.github/scripts/validate-project-structure.sh