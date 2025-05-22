#!/bin/bash

echo "NOTICE: This test script is deprecated."
echo "Version incrementing is now handled automatically by GitHub Actions."
echo "See .github/workflows/python-package.yml for details."
echo "You can safely remove this script from your local repository."

# Display current versions for reference
echo -e "\nCurrent version in version.py:"
grep "__version__" version.py

echo "Current version in pyproject.toml:"
grep "version =" pyproject.toml

echo -e "\nThese versions will be automatically incremented when changes are pushed to the master branch."
echo "No manual testing or version incrementing is required."
