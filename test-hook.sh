#!/bin/bash

# Test script to verify the pre-commit hook works correctly

echo "Testing pre-commit hook..."

# Ensure the hook is installed
if [ ! -f .git/hooks/pre-commit ]; then
    echo "Installing hooks..."
    ./install-hooks.sh
fi

# Create the server/midi-presets directory if it doesn't exist
mkdir -p server/midi-presets

# Test Case 2: Preventing Commits of the midi-presets Directory Itself
echo "Test Case 2: Preventing Commits of the midi-presets Directory Itself"
git add server/midi-presets
# Run the pre-commit hook manually
.git/hooks/pre-commit

# Clean up
echo "Cleaning up..."
git reset HEAD server/midi-presets

echo "Test completed."