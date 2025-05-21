#!/bin/bash

# This script tests the version incrementing functionality
# It simulates a git commit and checks if the version is incremented properly

# Save the current version
echo "Current version in version.py:"
grep "__version__" version.py

echo "Current version in pyproject.toml:"
grep "version =" pyproject.toml

# Run the pre-commit hook
echo -e "\nRunning pre-commit hook..."
./pre-commit

# Check the new version
echo -e "\nNew version in version.py:"
grep "__version__" version.py

echo "New version in pyproject.toml:"
grep "version =" pyproject.toml

echo -e "\nTest completed. If the versions were incremented, the pre-commit hook is working correctly."
echo "Note: This test only simulates a commit. No actual commit was made."
echo "To revert the version changes, you can edit the files manually or use git checkout."