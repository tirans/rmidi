#!/bin/bash
# Fix git submodule initialization issues

echo "🔧 Fixing git submodule configuration..."

# Remove any existing submodule config
echo "🗑️ Removing existing submodule configuration..."
git submodule deinit -f server/midi-presets 2>/dev/null || true
rm -rf .git/modules/server/midi-presets 2>/dev/null || true

# Re-add the submodule
echo "➕ Re-adding the submodule..."
git rm -rf server/midi-presets 2>/dev/null || true
git submodule add -f https://github.com/tirans/midi-presets.git server/midi-presets

# Initialize and update with proper branch handling
echo "🔄 Initializing submodule..."
git submodule init

# Ensure we're using the main branch instead of a specific commit
echo "🌿 Checking out main branch of submodule..."
cd server/midi-presets || { echo "❌ Failed to enter submodule directory"; exit 1; }
git fetch origin
git checkout main
git pull origin main
cd ../..

echo "✅ Submodule fixed and updated to latest main branch!"
