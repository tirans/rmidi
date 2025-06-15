#!/bin/bash
# remove-submodule.sh - Clean removal of server/midi-presets submodule

set -e

echo "🗑️ Removing server/midi-presets submodule cleanly..."

# Step 1: Deinitialize the submodule
echo "📝 Step 1: Deinitializing submodule..."
git submodule deinit -f server/midi-presets 2>/dev/null || echo "  ℹ️ Submodule not initialized or already deinitialized"

# Step 2: Remove from .git/modules
echo "📝 Step 2: Removing from .git/modules..."
rm -rf .git/modules/server/midi-presets 2>/dev/null || echo "  ℹ️ Module directory not found"

# Step 3: Remove from working tree and index
echo "📝 Step 3: Removing from working tree and index..."
git rm -rf server/midi-presets 2>/dev/null || echo "  ℹ️ Already removed from index"

# Step 4: Remove from .gitmodules
echo "📝 Step 4: Removing from .gitmodules..."
if [ -f .gitmodules ]; then
    # Remove the submodule section from .gitmodules
    git config -f .gitmodules --remove-section submodule.server/midi-presets 2>/dev/null || echo "  ℹ️ Section not found in .gitmodules"
    
    # If .gitmodules is now empty, remove it
    if [ ! -s .gitmodules ]; then
        rm .gitmodules
        git rm .gitmodules 2>/dev/null || true
        echo "  ✅ Removed empty .gitmodules file"
    else
        git add .gitmodules
        echo "  ✅ Updated .gitmodules file"
    fi
else
    echo "  ℹ️ .gitmodules file not found"
fi

# Step 5: Remove any remaining git config entries
echo "📝 Step 5: Cleaning up git config..."
git config --remove-section submodule.server/midi-presets 2>/dev/null || echo "  ℹ️ No git config entries found"

# Step 6: Create replacement directory if needed
echo "📝 Step 6: Creating replacement structure..."
if [ ! -d "server/midi-presets" ]; then
    mkdir -p server/midi-presets
    echo "# MIDI Presets" > server/midi-presets/README.md
    echo "" >> server/midi-presets/README.md
    echo "This directory previously contained a Git submodule." >> server/midi-presets/README.md
    echo "MIDI preset files can be placed here directly." >> server/midi-presets/README.md
    echo "" >> server/midi-presets/README.md
    echo "If you need the original presets, they are available at:" >> server/midi-presets/README.md
    echo "https://github.com/tirans/midi-presets" >> server/midi-presets/README.md
    
    # Create .gitkeep to ensure directory is tracked
    touch server/midi-presets/.gitkeep
    
    git add server/midi-presets/README.md server/midi-presets/.gitkeep
    echo "  ✅ Created replacement directory structure"
fi

echo ""
echo "✅ Submodule removal complete!"
echo ""
echo "📋 Summary of changes:"
echo "  - Removed server/midi-presets submodule"
echo "  - Created regular directory with README"
echo "  - Cleaned up all Git submodule references"
echo ""
echo "🔄 Next steps:"
echo "  1. Review the changes: git status"
echo "  2. Commit the changes: git commit -m 'remove: server/midi-presets submodule'"
echo "  3. Push the changes: git push"
echo ""
echo "ℹ️ If you need the MIDI presets, you can:"
echo "  - Download them manually from https://github.com/tirans/midi-presets"
echo "  - Copy the files directly into server/midi-presets/"
echo "  - Or add them as regular files (not a submodule)"
