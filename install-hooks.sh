#!/bin/bash

# Script to install Git hooks

echo "Installing Git hooks..."

# Ensure hooks directory exists
mkdir -p hooks

# Make hooks executable
chmod +x hooks/pre-commit

# Create symbolic link to pre-commit hook
ln -sf "$(pwd)/hooks/pre-commit" .git/hooks/pre-commit

echo "Git hooks installed successfully!"
echo "The pre-commit hook will prevent committing files from the server/midi-presets directory."