#!/bin/bash
# fix-permissions.sh - Make all scripts executable and fix line endings

echo "🔧 Fixing script permissions and line endings..."

# Find and make all shell scripts executable
find .github/scripts -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

# Convert Windows line endings to Unix if dos2unix is available
if command -v dos2unix >/dev/null 2>&1; then
    echo "🔄 Converting line endings..."
    find .github/scripts -name "*.sh" -type f -exec dos2unix {} \; 2>/dev/null || true
fi

# Verify permissions
echo "📋 Script permissions:"
find .github/scripts -name "*.sh" -type f -exec ls -la {} \;

echo "✅ Script permissions fixed"
