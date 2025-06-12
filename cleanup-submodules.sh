#!/bin/bash
# cleanup-submodules.sh - Complete cleanup of Git submodules

set -e

echo "🗑️ Comprehensive Git Submodule Cleanup"
echo "======================================="
echo ""

# Step 1: Remove the submodule directory completely
echo "📝 Removing submodule directory..."
if [ -d "server/midi-presets" ]; then
    rm -rf server/midi-presets
    echo "  ✅ Removed server/midi-presets directory"
else
    echo "  ℹ️ server/midi-presets directory not found"
fi

# Step 2: Remove from .gitmodules
echo "📝 Cleaning .gitmodules..."
if [ -f .gitmodules ]; then
    # Remove the submodule section
    git config -f .gitmodules --remove-section submodule.server/midi-presets 2>/dev/null || echo "  ℹ️ Section not found in .gitmodules"
    
    # If .gitmodules is now empty, remove it
    if [ ! -s .gitmodules ]; then
        rm .gitmodules
        echo "  ✅ Removed empty .gitmodules file"
    else
        echo "  ✅ Updated .gitmodules file"
    fi
else
    echo "  ℹ️ .gitmodules file not found"
fi

# Step 3: Remove from Git index and working tree
echo "📝 Removing from Git index..."
git rm -rf server/midi-presets 2>/dev/null || echo "  ℹ️ Already removed from index"

# Step 4: Remove Git submodule metadata
echo "📝 Cleaning Git metadata..."
rm -rf .git/modules/server/midi-presets 2>/dev/null || echo "  ℹ️ No Git modules to remove"

# Step 5: Remove Git config entries
echo "📝 Cleaning Git configuration..."
git config --remove-section submodule.server/midi-presets 2>/dev/null || echo "  ℹ️ No Git config entries found"

# Step 6: Create replacement directory structure
echo "📝 Creating replacement directory..."
mkdir -p server/midi-presets

cat > server/midi-presets/README.md << 'EOF'
# MIDI Presets Directory

This directory can contain MIDI preset files for the R2MIDI server.

## Usage

Place your MIDI preset files (`.mid`, `.json`, etc.) in this directory.
The server will automatically detect and load them.

## Original Presets

The original MIDI presets were previously managed as a Git submodule.
If you need those presets, you can download them from:
https://github.com/tirans/midi-presets

## Adding Presets

You can add presets in several ways:

1. **Direct copy**: Copy `.mid` files directly into this directory
2. **Download**: Download presets from the original repository
3. **Create**: Create your own preset files

## File Structure

```
server/midi-presets/
├── README.md          # This file
├── .gitkeep          # Ensures directory is tracked by Git
└── your-presets.mid  # Your MIDI preset files
```
EOF

# Create .gitkeep to ensure directory is tracked
touch server/midi-presets/.gitkeep

# Add the new files to Git
git add server/midi-presets/README.md server/midi-presets/.gitkeep

echo ""
echo "✅ Submodule cleanup complete!"
echo ""
echo "📋 What was done:"
echo "  - Removed server/midi-presets submodule completely"
echo "  - Cleaned up .gitmodules file"
echo "  - Removed all Git submodule metadata"
echo "  - Created regular directory with documentation"
echo "  - Added .gitkeep to track the directory in Git"
echo ""
echo "🔄 Next steps:"
echo "  1. Review changes: git status"
echo "  2. Commit changes: git commit -m 'remove: server/midi-presets Git submodule'"
echo "  3. Push changes: git push"
echo ""
echo "ℹ️ To add MIDI presets:"
echo "  - Copy .mid files directly to server/midi-presets/"
echo "  - Or download from: https://github.com/tirans/midi-presets"
echo ""
