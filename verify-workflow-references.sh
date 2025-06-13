#!/bin/bash
# verify-workflow-references.sh - Verify all GitHub workflow and action references are correct
set -euo pipefail

PROJECT_ROOT="/Users/tirane/Desktop/r2midi"
cd "$PROJECT_ROOT"

echo "🔍 Verifying GitHub workflow and action references..."

# Track results
TOTAL_CHECKS=0
PASSED_CHECKS=0
ISSUES=()

check_workflow_file() {
    local file="$1"
    echo "📄 Checking: $file"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ ! -f "$file" ]; then
        ISSUES+=("Missing file: $file")
        return
    fi
    
    local file_issues=()
    
    # Check for incorrect workflow references (missing version)
    if grep -q "uses: \.\/\.github/workflows/.*\.yml$" "$file" 2>/dev/null; then
        local bad_workflows=$(grep -n "uses: \.\/\.github/workflows/.*\.yml$" "$file")
        while IFS= read -r line; do
            file_issues+=("  Workflow missing version: $line")
        done <<< "$bad_workflows"
    fi
    
    # Check for incorrect action references (missing ./ prefix)
    if grep -q "uses: \.github/actions/" "$file" 2>/dev/null; then
        local bad_actions=$(grep -n "uses: \.github/actions/" "$file")
        while IFS= read -r line; do
            file_issues+=("  Action missing ./ prefix: $line")
        done <<< "$bad_actions"
    fi
    
    # Check for correct patterns
    local correct_workflows=$(grep -c "uses: \.\/\.github/workflows/.*\.yml@" "$file" 2>/dev/null || echo "0")
    local correct_actions=$(grep -c "uses: \.\/\.github/actions/" "$file" 2>/dev/null || echo "0")
    
    if [ ${#file_issues[@]} -gt 0 ]; then
        ISSUES+=("Issues in $file:")
        ISSUES+=("${file_issues[@]}")
    else
        echo "  ✅ Correct patterns: $correct_workflows workflows, $correct_actions actions"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
}

echo "🔍 Checking workflow files..."
check_workflow_file ".github/workflows/ci.yml"
check_workflow_file ".github/workflows/release.yml"
check_workflow_file ".github/workflows/reusable-build.yml"
check_workflow_file ".github/workflows/macos-native.yml"
check_workflow_file ".github/workflows/app-store.yml"
check_workflow_file ".github/workflows/reusable-test.yml"

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
echo "🧪 Testing YAML syntax..."

# Check workflow syntax
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        if python3 -c "
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
echo "📊 Reference Verification Summary:"
echo "=================================="
echo "Total checks: $TOTAL_CHECKS"
echo "Passed checks: $PASSED_CHECKS"
echo "Failed checks: $((TOTAL_CHECKS - PASSED_CHECKS))"

echo ""
echo "📋 Reference Format Rules:"
echo "- Reusable workflows: uses: ./.github/workflows/name.yml@main"
echo "- Local actions: uses: ./.github/actions/action-name"
echo "- External actions: uses: owner/repo@version"

if [ ${#ISSUES[@]} -eq 0 ]; then
    echo ""
    echo "🎉 All GitHub workflow and action references are CORRECT!"
    echo "✅ No reference issues found"
    echo ""
    echo "🚀 Ready to commit and test:"
    echo "git add .github/"
    echo "git commit -m 'fix: correct GitHub workflow and action references'"
    echo "git push"
else
    echo ""
    echo "❌ Issues found:"
    printf '%s\n' "${ISSUES[@]}"
    echo ""
    echo "Please fix these issues before proceeding."
    exit 1
fi
