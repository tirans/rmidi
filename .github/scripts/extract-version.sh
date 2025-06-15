#!/bin/bash
set -euo pipefail

# Simplified version extraction for CI use only
# Usage: extract-version.sh [input_version]

INPUT_VERSION="${1:-}"

# Function to extract version from server/version.py
get_version_from_file() {
    if [ -f "server/version.py" ]; then
        grep -o '__version__ = "[^"]*"' server/version.py | head -1 | cut -d'"' -f2 | tr -d '\n\r' | xargs
    else
        echo ""
    fi
}

# Determine the version to use
if [ -n "$INPUT_VERSION" ]; then
    VERSION=$(echo "$INPUT_VERSION" | tr -d '\n\r' | xargs)
else
    VERSION=$(get_version_from_file)
    if [ -z "$VERSION" ]; then
        echo "❌ Error: Could not extract version from server/version.py"
        exit 1
    fi
fi

# Output in the format expected by tests and CI
echo "Version: $VERSION"

# Set GitHub Actions outputs if in CI
if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi

# Set environment variable if in CI
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "APP_VERSION=$VERSION" >> "$GITHUB_ENV"
fi
