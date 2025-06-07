#!/bin/bash
# Final setup script - run this to make everything executable and ready to use

echo "🎉 R2MIDI Workflow Fix - Final Setup"
echo "====================================="
echo ""

# Get the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Working directory: $SCRIPT_DIR"

echo ""
echo "🔧 Making all scripts executable..."

# Make Python scripts executable
chmod +x "$SCRIPT_DIR/scripts/update_pyproject.py"
chmod +x "$SCRIPT_DIR/scripts/generate_icons.py" 
chmod +x "$SCRIPT_DIR/scripts/validate_pyproject.py"

# Make shell scripts executable
chmod +x "$SCRIPT_DIR/scripts/debug_certificates.sh"

echo "✅ File permissions updated successfully!"
echo ""

# Show what was created
echo "📋 Created files:"
echo "=================="
find "$SCRIPT_DIR" -type f -name "*.py" -o -name "*.sh" -o -name "*.yml" -o -name "*.md" | sort | while read file; do
    rel_path="${file#$SCRIPT_DIR/}"
    echo "  ✅ $rel_path"
done

echo ""
echo "🚀 Ready to Deploy!"
echo "==================="
echo ""
echo "Copy these commands to apply the fix to your R2MIDI project:"
echo ""
echo "# 1. Set your R2MIDI project path"
echo "PROJ_PATH=\"/path/to/your/r2midi\""
echo ""
echo "# 2. Copy the fixed workflow" 
echo "cp \"$SCRIPT_DIR/.github/workflows/release.yml\" \"\$PROJ_PATH/.github/workflows/\""
echo ""
echo "# 3. Copy all scripts"
echo "mkdir -p \"\$PROJ_PATH/scripts\""
echo "cp \"$SCRIPT_DIR/scripts/\"* \"\$PROJ_PATH/scripts/\""
echo ""
echo "# 4. Make scripts executable in your project"
echo "chmod +x \"\$PROJ_PATH/scripts/\"*.py \"\$PROJ_PATH/scripts/\"*.sh"
echo ""
echo "# 5. Install dependencies"
echo "pip install pillow tomli"
echo ""
echo "# 6. Test locally (macOS only)"
echo "cd \"\$PROJ_PATH\""
echo "./scripts/debug_certificates.sh"
echo "python scripts/validate_pyproject.py"
echo ""
echo "🎯 After copying, commit and push to GitHub to test the fixed workflow!"
echo ""
echo "📖 See README.md and SETUP_INSTRUCTIONS.md for detailed documentation."
