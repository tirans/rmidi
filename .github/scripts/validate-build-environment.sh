#!/bin/bash
# validate-build-environment.sh - Validate build environment before running builds
set -euo pipefail

echo "🔍 Validating build environment..."

# Check Python installation
if ! python --version >/dev/null 2>&1; then
    echo "❌ Python not found"
    exit 1
fi

echo "✅ Python: $(python --version)"

# Check essential directories
REQUIRED_DIRS=("server" "r2midi_client" ".github/scripts" ".github/actions/build-apps")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ Missing directory: $dir"
        exit 1
    fi
done

# Check essential files
REQUIRED_FILES=("pyproject.toml" "requirements.txt" "server/main.py" "r2midi_client/main.py")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing file: $file"
        exit 1
    fi
done

# Check build scripts
BUILD_SCRIPTS=(".github/scripts/build-macos.sh" ".github/scripts/build-briefcase.sh")
for script in "${BUILD_SCRIPTS[@]}"; do
    if [ ! -x "$script" ]; then
        echo "❌ Build script not executable: $script"
        chmod +x "$script" 2>/dev/null && echo "🔧 Fixed permissions for: $script" || echo "❌ Could not fix permissions"
    else
        echo "✅ Build script ready: $script"
    fi
done

# Check disk space (require at least 2GB)
if command -v df >/dev/null 2>&1; then
    AVAILABLE_SPACE=$(df . | tail -1 | awk '{print $4}')
    if [ "$AVAILABLE_SPACE" -lt 2097152 ]; then
        echo "⚠️ Low disk space: $(df -h . | tail -1 | awk '{print $4}') available"
        echo "Recommend at least 2GB free space for builds"
    else
        echo "✅ Disk space: $(df -h . | tail -1 | awk '{print $4}') available"
    fi
fi

# Check for midi-presets directory (common issue)
if [ ! -d "server/midi-presets" ]; then
    echo "📁 Creating server/midi-presets directory..."
    mkdir -p server/midi-presets
    echo "# MIDI Presets Directory" > server/midi-presets/README.md
    echo "Place MIDI preset files here." >> server/midi-presets/README.md
    echo "✅ Created server/midi-presets directory"
fi

# Validate pyproject.toml structure
if ! python -c "
import tomllib
try:
    with open('pyproject.toml', 'rb') as f:
        config = tomllib.load(f)
    assert 'tool' in config, 'No [tool] section'
    assert 'briefcase' in config['tool'], 'No [tool.briefcase] section'
    assert 'app' in config['tool']['briefcase'], 'No apps configured'
    print('✅ pyproject.toml configuration valid')
except Exception as e:
    print(f'❌ pyproject.toml validation failed: {e}')
    exit(1)
" 2>/dev/null; then
    echo "❌ pyproject.toml validation failed - check Briefcase configuration"
    exit 1
fi

echo "✅ Build environment validation passed"
echo ""
echo "🚀 Ready to run builds! Use:"
echo "  - macOS: Enhanced native builds with py2app conflict resolution"
echo "  - Linux: Improved Briefcase builds with broken pipe fixes"
echo "  - Windows: Enhanced Briefcase builds with process management"
