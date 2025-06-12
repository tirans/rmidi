#!/bin/bash
# Make build scripts executable and fix line endings

echo "🔧 Setting up build scripts..."

# Set executable permissions on shell scripts
find .github/scripts -name "*.sh" -exec chmod +x {} \;

# Ensure Unix line endings (in case scripts were edited on Windows)
if command -v dos2unix >/dev/null 2>&1; then
    find .github/scripts -name "*.sh" -exec dos2unix {} \;
fi

echo "✅ Build scripts setup complete"
