#!/bin/bash
# verify-action-paths.sh - Verify all GitHub Action paths are correct
set -euo pipefail

PROJECT_ROOT="/Users/tirane/Desktop/r2midi"
cd "$PROJECT_ROOT"

echo "🔍 Verifying GitHub Action path references..."

# Track results
TOTAL_CHECKS=0
PASSED_CHECKS=0
ISSUES=()

check_workflow_paths() {
    local file="$1"
    echo "📄 Checking: $file"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ ! -f "$file" ]; then
        ISSUES+=("Missing file: $file")
        return
    fi
    
    # Check for incorrect action paths (with ./)
    if grep -q "uses: \.\/\.github" "$file" 2>/dev/null; then
        local bad_lines=$(grep -n "uses: \.\/\.github" "$file" | head -3)
        ISSUES+=("Found incorrect paths in $file:")
        while IFS= read -r line; do
            ISSUES+=("  $line")
        done <<< "$bad_lines"
        return
    fi
    
    # Check for correct action paths (without ./)
    local action_refs=$(grep -c "uses: \.github" "$file" 2>/dev/null || echo "0")
    local workflow_refs=$(grep -c "uses: .github/workflows" "$file" 2>/dev/null || echo "0")
    
    if [ "$action_refs" -gt 0 ] || [ "$workflow_refs" -gt 0 ]; then
        echo "  ✅ Found $action_refs action refs and $workflow_refs workflow refs with correct paths"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo "  ℹ️ No action/workflow references found (this is normal for some files)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
}

echo "🔍 Checking workflow files..."
check_workflow_paths ".github/workflows/ci.yml"
check_workflow_paths ".github/workflows/release.yml"
check_workflow_paths ".github/workflows/reusable-build.yml"
check_workflow_paths ".github/workflows/macos-native.yml"
check_workflow_paths ".github/workflows/app-store.yml"
check_workflow_paths ".github/workflows/reusable-test.yml"

echo ""
echo "🔍 Checking action existence..."

# Verify all referenced actions exist
action_dirs=(
    ".github/actions/build-apps"
    ".github/actions/setup-environment"
    ".github/actions/setup-macos-signing"
    ".github/actions/package-apps"
    ".github/actions/cleanup-signing"
    ".github/actions/install-system-deps"
    ".github/actions/configure-build"
)

for action_dir in "${action_dirs[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ -d "$action_dir" ] && [ -f "$action_dir/action.yml" ]; then
        echo "  ✅ Action exists: $action_dir"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        ISSUES+=("Missing action or action.yml: $action_dir")
    fi
done

echo ""
echo "🧪 Testing workflow syntax..."

# Check workflow syntax
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        if python -c "
import yaml
import sys
try:
    with open('$workflow', 'r') as f:
        yaml.safe_load(f)
    print('✅ YAML syntax OK: $workflow')
    sys.exit(0)
except Exception as e:
    print('❌ YAML syntax error in $workflow: {}'.format(e))
    sys.exit(1)
" 2>/dev/null; then
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            ISSUES+=("YAML syntax error in: $workflow")
        fi
    fi
done

echo ""
echo "📊 Verification Summary:"
echo "================================"
echo "Total checks: $TOTAL_CHECKS"
echo "Passed checks: $PASSED_CHECKS"
echo "Failed checks: $((TOTAL_CHECKS - PASSED_CHECKS))"

if [ ${#ISSUES[@]} -eq 0 ]; then
    echo ""
    echo "🎉 All GitHub Action paths are CORRECT!"
    echo "✅ No more path issues found"
    echo ""
    echo "🚀 Ready to commit and test:"
    echo "git add .github/"
    echo "git commit -m 'fix: correct GitHub Action paths'"
    echo "git push"
else
    echo ""
    echo "❌ Issues found:"
    printf '%s\n' "${ISSUES[@]}"
    echo ""
    echo "Please fix these issues before proceeding."
    exit 1
fi
