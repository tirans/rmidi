#!/bin/bash
# Fix git submodule initialization issues

echo "Fixing git submodule configuration..."

# Remove any existing submodule config
git submodule deinit -f server/midi-presets 2>/dev/null || true
rm -rf .git/modules/server/midi-presets 2>/dev/null || true

# Re-add the submodule
git rm -rf server/midi-presets 2>/dev/null || true
git submodule add https://github.com/tirans/midi-presets.git server/midi-presets

# Initialize and update
git submodule init
git submodule update --init --recursive

echo "Submodule fixed!"
