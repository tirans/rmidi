#!/bin/bash
# validate-yaml.sh - Validate all GitHub Actions YAML files
set -euo pipefail

echo "🧪 Validating GitHub Actions YAML files..."
echo ""

# Track results
TOTAL_FILES=0
VALID_FILES=0
ERRORS=()

validate_yaml() {
    local file="$1"
    TOTAL_FILES=$((TOTAL_FILES + 1))
    
    echo "📄 Validating: $file"
    
    if [ ! -f "$file" ]; then
        ERRORS+=("❌ File not found: $file")
        return 1
    fi
    
    # Check YAML syntax using Python
    if python3 -c "
import yaml
import sys
try:
    with open('$file', 'r') as f:
        yaml.safe_load(f)
    print('  ✅ YAML syntax OK')
    sys.exit(0)
except yaml.YAMLError as e:
    print(f'  ❌ YAML error: {e}')
    sys.exit(1)
except Exception as e:
    print(f'  ❌ Error: {e}')
    sys.exit(1)
" 2>/dev/null; then
        VALID_FILES=$((VALID_FILES + 1))
        return 0
    else
        ERRORS+=("❌ YAML validation failed: $file")
        return 1
    fi
}

echo "🔍 Validating workflow files..."
validate_yaml ".github/workflows/ci.yml"
validate_yaml ".github/workflows/release.yml"
validate_yaml ".github/workflows/reusable-build.yml"
validate_yaml ".github/workflows/reusable-test.yml"
validate_yaml ".github/workflows/macos-native.yml"
validate_yaml ".github/workflows/app-store.yml"

echo ""
echo "🔍 Validating action files..."
validate_yaml ".github/actions/build-apps/action.yml"
validate_yaml ".github/actions/package-apps/action.yml"
validate_yaml ".github/actions/setup-environment/action.yml"
validate_yaml ".github/actions/setup-macos-signing/action.yml"
validate_yaml ".github/actions/cleanup-signing/action.yml"
validate_yaml ".github/actions/install-system-deps/action.yml"
validate_yaml ".github/actions/configure-build/action.yml"

echo ""
echo "📊 YAML Validation Summary:"
echo "=========================="
echo "Total files checked: $TOTAL_FILES"
echo "Valid files: $VALID_FILES"
echo "Failed files: $((TOTAL_FILES - VALID_FILES))"

if [ ${#ERRORS[@]} -eq 0 ]; then
    echo ""
    echo "🎉 All YAML files are valid!"
    echo "✅ GitHub Actions should now work correctly"
    echo ""
    echo "🚀 Next steps:"
    echo "1. Commit these changes"
    echo "2. Push to GitHub"
    echo "3. Check the Actions tab for successful runs"
    echo ""
    echo "git add .github/"
    echo "git commit -m 'fix: simplify and fix GitHub Actions YAML syntax'"
    echo "git push"
else
    echo ""
    echo "❌ YAML validation errors found:"
    printf '%s\n' "${ERRORS[@]}"
    echo ""
    echo "Please fix these errors before proceeding."
    exit 1
fi
