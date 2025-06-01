#!/bin/bash

# Test script for the robust version increment and push process
# This script simulates the GitHub Actions workflow for incrementing versions

echo "Testing robust version increment and push process"

# Setup Git user for testing
git config --local user.name "Test Bot"
git config --local user.email "test@example.com"

# Get current version
CURRENT_VERSION=$(grep -o '__version__ = "[^"]*"' version.py | cut -d'"' -f2)
echo "Current version: $CURRENT_VERSION"

# Increment version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
echo "New version: $NEW_VERSION"

# Create a temporary branch for testing
TEST_BRANCH="test-version-increment-$(date +%s)"
git checkout -b $TEST_BRANCH

# Update version files
sed -i.bak "s/__version__ = \"$CURRENT_VERSION\"/__version__ = \"$NEW_VERSION\"/" version.py
sed -i.bak "s/version = \"$CURRENT_VERSION\"/version = \"$NEW_VERSION\"/" pyproject.toml
rm version.py.bak pyproject.toml.bak  # Remove backup files

# Commit changes
git add version.py pyproject.toml
git commit -m "Test: Bump version from $CURRENT_VERSION to $NEW_VERSION"

# Simulate the robust push process
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  # Check if there are any changes to stash
  if git diff --quiet; then
    echo "No local changes to save"
  else
    # Stash any local changes
    git stash save "Temporary stash before pull"
    echo "Local changes stashed"
  fi
  
  # Pull latest changes with rebase
  git pull --rebase origin $TEST_BRANCH || true
  PULL_STATUS=$?
  
  # Apply stashed changes if they exist
  if git stash list | grep -q "Temporary stash before pull"; then
    git stash pop
    STASH_STATUS=$?
    if [ $STASH_STATUS -ne 0 ]; then
      echo "Warning: Stash pop had conflicts, resolving..."
      git add .
      git rebase --continue
    fi
  fi
  
  # Try to push with force-with-lease (we'll just echo instead of actually pushing in this test)
  echo "Would push to origin $TEST_BRANCH with --force-with-lease here"
  # Fetch the latest changes before retrying to update our reference
  git fetch origin $TEST_BRANCH || true
  PUSH_STATUS=0  # Simulate successful push
  
  if [ $PUSH_STATUS -eq 0 ]; then
    echo "Successfully pushed version bump"
    break
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
      echo "Push failed, retrying ($RETRY_COUNT/$MAX_RETRIES)..."
      sleep 2  # Add a small delay before retrying
    else
      echo "Failed to push after $MAX_RETRIES attempts"
      exit 1
    fi
  fi
done

# Clean up - discard changes and return to original branch
git checkout master
git branch -D $TEST_BRANCH

echo "Test completed successfully"