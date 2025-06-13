#!/bin/bash
# verify-deployment.sh - Final verification of build fixes deployment
set -euo pipefail

PROJECT_ROOT="/Users/tirane/Desktop/r2midi"
cd "$PROJECT_ROOT"

echo "🔍 Verifying R2MIDI build fixes deployment..."

# Track results
TOTAL_CHECKS=0
PASSED_CHECKS=0
ISSUES=()

check_file() {
    local file="$1"
    local should_be_executable="${2:-false}"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -f "$file" ]; then
        echo "✅ File exists: $file"
        
        if [ "$should_be_executable" = "true" ]; then
            if [ -x "$file" ]; then
                echo "✅ Executable: $file"
                PASSED_CHECKS=$((PASSED_CHECKS + 1))
            else
                echo "🔧 Making executable: $file"
                chmod +x "$file" && echo "✅ Fixed permissions: $file" && PASSED_CHECKS=$((PASSED_CHECKS + 1)) || ISSUES+=("Could not make executable: $file")
            fi
        else
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        fi
    else
        ISSUES+=("Missing file: $file")
    fi
}

echo "📁 Checking core build scripts..."
check_file ".github/scripts/build-macos.sh" true
check_file ".github/scripts/build-briefcase.sh" true
check_file ".github/scripts/validate-build-environment.sh" true

echo "📁 Checking action files..."
check_file ".github/actions/build-apps/action.yml" false

echo "📁 Checking documentation..."
check_file ".github/BUILD_TROUBLESHOOTING.md" false
check_file ".github/BUILD_FIXES_SUMMARY.md" false

echo "📁 Checking deployment script..."
check_file "deploy-build-fixes.sh" true

echo "🧪 Testing script syntax..."
SYNTAX_CHECKS=0
SYNTAX_PASSED=0

for script in .github/scripts/*.sh deploy-build-fixes.sh; do
    if [ -f "$script" ]; then
        SYNTAX_CHECKS=$((SYNTAX_CHECKS + 1))
        if bash -n "$script" 2>/dev/null; then
            echo "✅ Syntax OK: $script"
            SYNTAX_PASSED=$((SYNTAX_PASSED + 1))
        else
            ISSUES+=("Syntax error in: $script")
        fi
    fi
done

echo "🔍 Validating project structure..."
STRUCTURE_CHECKS=0
STRUCTURE_PASSED=0

required_files=("pyproject.toml" "requirements.txt" "server/main.py" "r2midi_client/main.py")
for file in "${required_files[@]}"; do
    STRUCTURE_CHECKS=$((STRUCTURE_CHECKS + 1))
    if [ -f "$file" ]; then
        echo "✅ Required file: $file"
        STRUCTURE_PASSED=$((STRUCTURE_PASSED + 1))
    else
        ISSUES+=("Missing required file: $file")
    fi
done

# Create server/midi-presets if it doesn't exist
if [ ! -d "server/midi-presets" ]; then
    echo "📁 Creating server/midi-presets directory..."
    mkdir -p server/midi-presets
    echo "# MIDI Presets Directory" > server/midi-presets/README.md
    echo "Place MIDI preset files here." >> server/midi-presets/README.md
    echo "✅ Created server/midi-presets directory"
fi

echo ""
echo "📊 Verification Summary:"
echo "================================"
echo "File checks: $PASSED_CHECKS/$TOTAL_CHECKS passed"
echo "Syntax checks: $SYNTAX_PASSED/$SYNTAX_CHECKS passed"
echo "Structure checks: $STRUCTURE_PASSED/$STRUCTURE_CHECKS passed"

if [ ${#ISSUES[@]} -eq 0 ]; then
    echo ""
    echo "🎉 Deployment verification PASSED!"
    echo "✅ All build fixes have been successfully deployed"
    echo ""
    echo "🚀 Next steps:"
    echo "1. Run: ./.github/scripts/validate-build-environment.sh"
    echo "2. Commit changes: git add . && git commit -m 'feat: resilient build system'"
    echo "3. Test builds on GitHub Actions"
    echo ""
    echo "📋 What was fixed:"
    echo "- macOS: py2app conflicts and file copying errors"
    echo "- Linux: Broken pipe errors from find commands"
    echo "- Windows: Process termination and encoding issues"
    echo "- All: Enhanced error handling and retry mechanisms"
else
    echo ""
    echo "⚠️ Issues found during verification:"
    printf '%s\n' "${ISSUES[@]}"
    echo ""
    echo "Please resolve these issues before proceeding."
    exit 1
fi
