#!/bin/bash
set -euo pipefail

# Validate GitHub Actions workflow refactoring
# Usage: validate-refactoring.sh

echo "🔍 Validating GitHub Actions workflow refactoring..."

SCRIPTS_DIR=".github/scripts"
WORKFLOWS_DIR=".github/workflows"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status="$1"
    local message="$2"
    case "$status" in
        "PASS") echo -e "${GREEN}✅ PASS${NC}: $message" ;;
        "FAIL") echo -e "${RED}❌ FAIL${NC}: $message" ;;
        "WARN") echo -e "${YELLOW}⚠️ WARN${NC}: $message" ;;
        "INFO") echo -e "${BLUE}ℹ️ INFO${NC}: $message" ;;
    esac
}

# Track validation results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to run a check
run_check() {
    local description="$1"
    local command="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if eval "$command" >/dev/null 2>&1; then
        print_status "PASS" "$description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_status "FAIL" "$description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

echo ""
echo "📋 Validation Checklist:"
echo "========================"

# 1. Validate scripts directory structure
echo ""
echo "1. Scripts Directory Structure"
echo "------------------------------"

run_check "Scripts directory exists" "[ -d '$SCRIPTS_DIR' ]"
run_check "Workflows directory exists" "[ -d '$WORKFLOWS_DIR' ]"

# Required new scripts
NEW_SCRIPTS=(
    "install-system-dependencies.sh"
    "install-python-dependencies.sh"
    "setup-environment.sh"
    "extract-version.sh"
    "generate-build-summary.sh"
    "make-scripts-executable.sh"
)

for script in "${NEW_SCRIPTS[@]}"; do
    run_check "New script exists: $script" "[ -f '$SCRIPTS_DIR/$script' ]"
    run_check "New script is executable: $script" "[ -x '$SCRIPTS_DIR/$script' ]"
done

# Existing scripts should still exist
EXISTING_SCRIPTS=(
    "build-briefcase-apps.sh"
    "package-macos-apps.sh"
    "package-linux-apps.sh"
    "package-windows-apps.sh"
    "sign-and-notarize-macos.sh"
    "build-python-package.sh"
    "update-version.sh"
    "validate-build-environment.sh"
    "validate-project-structure.sh"
    "prepare-release-artifacts.sh"
    "setup-scripts.sh"
)

for script in "${EXISTING_SCRIPTS[@]}"; do
    run_check "Existing script preserved: $script" "[ -f '$SCRIPTS_DIR/$script' ]"
    run_check "Existing script is executable: $script" "[ -x '$SCRIPTS_DIR/$script' ]"
done

# 2. Validate workflow files
echo ""
echo "2. Workflow Files"
echo "-----------------"

WORKFLOW_FILES=(
    "ci.yml"
    "build-macos.yml"
    "build-linux.yml"
    "build-windows.yml"
    "build.yml"
    "release.yml"
)

for workflow in "${WORKFLOW_FILES[@]}"; do
    run_check "Workflow file exists: $workflow" "[ -f '$WORKFLOWS_DIR/$workflow' ]"
done

# 3. Validate workflow refactoring (check for script usage)
echo ""
echo "3. Workflow Refactoring"
echo "----------------------"

# Check that workflows are using scripts instead of inline code
check_workflow_uses_scripts() {
    local workflow="$1"
    local workflow_path="$WORKFLOWS_DIR/$workflow"
    
    if [ ! -f "$workflow_path" ]; then
        return 1
    fi
    
    # Check for script usage patterns
    if grep -q "\./\.github/scripts/" "$workflow_path"; then
        return 0
    else
        return 1
    fi
}

for workflow in "${WORKFLOW_FILES[@]}"; do
    run_check "Workflow uses scripts: $workflow" "check_workflow_uses_scripts '$workflow'"
done

# Check that inline code patterns are reduced
check_no_inline_dependency_installation() {
    local workflow="$1"
    local workflow_path="$WORKFLOWS_DIR/$workflow"
    
    if [ ! -f "$workflow_path" ]; then
        return 1
    fi
    
    # Should not contain inline apt-get, pip install sequences
    if ! grep -q "sudo apt-get install -y" "$workflow_path" && \
       ! grep -q "python -m pip install.*requirements\.txt" "$workflow_path"; then
        return 0
    else
        return 1
    fi
}

for workflow in "${WORKFLOW_FILES[@]}"; do
    run_check "Workflow has minimal inline code: $workflow" "check_no_inline_dependency_installation '$workflow'"
done

# 4. Validate script functionality
echo ""
echo "4. Script Functionality"
echo "----------------------"

# Test script syntax
for script in "${NEW_SCRIPTS[@]}"; do
    if [ -f "$SCRIPTS_DIR/$script" ]; then
        run_check "Script has valid syntax: $script" "bash -n '$SCRIPTS_DIR/$script'"
    fi
done

# Test that scripts have proper shebangs
for script in "${NEW_SCRIPTS[@]}"; do
    if [ -f "$SCRIPTS_DIR/$script" ]; then
        run_check "Script has proper shebang: $script" "head -1 '$SCRIPTS_DIR/$script' | grep -q '^#!/bin/bash'"
    fi
done

# Test that scripts use set -euo pipefail for safety
for script in "${NEW_SCRIPTS[@]}"; do
    if [ -f "$SCRIPTS_DIR/$script" ]; then
        run_check "Script uses safe mode: $script" "grep -q 'set -euo pipefail' '$SCRIPTS_DIR/$script'"
    fi
done

# 5. Check for GitHub Actions best practices
echo ""
echo "5. GitHub Actions Best Practices"
echo "--------------------------------"

# Check that workflows use shell: bash consistently
check_consistent_shell_usage() {
    local workflow="$1"
    local workflow_path="$WORKFLOWS_DIR/$workflow"
    
    if [ ! -f "$workflow_path" ]; then
        return 1
    fi
    
    # If there are run: blocks with shell scripts, they should specify shell: bash
    local script_runs=$(grep -A5 "run: |" "$workflow_path" | grep -c "\./\.github/scripts/" || echo "0")
    local shell_declarations=$(grep -c "shell: bash" "$workflow_path" || echo "0")
    
    # If we have script runs, we should have shell declarations
    if [ "$script_runs" -gt 0 ] && [ "$shell_declarations" -gt 0 ]; then
        return 0
    elif [ "$script_runs" -eq 0 ]; then
        # No script runs, that's fine
        return 0
    else
        return 1
    fi
}

for workflow in "${WORKFLOW_FILES[@]}"; do
    run_check "Workflow uses consistent shell: $workflow" "check_consistent_shell_usage '$workflow'"
done

# 6. Validate documentation
echo ""
echo "6. Documentation"
echo "---------------"

run_check "Refactoring summary exists" "[ -f '.github/REFACTORING_SUMMARY.md' ]"
run_check "Workflows README exists" "[ -f '$WORKFLOWS_DIR/README.md' ]"

# 7. Integration tests (if we can run them safely)
echo ""
echo "7. Integration Tests"
echo "-------------------"

# Test that setup-environment.sh works
if [ -f "$SCRIPTS_DIR/setup-environment.sh" ] && [ -x "$SCRIPTS_DIR/setup-environment.sh" ]; then
    run_check "setup-environment.sh runs without error" "(cd /tmp && bash '$PWD/$SCRIPTS_DIR/setup-environment.sh' --help >/dev/null 2>&1) || bash '$PWD/$SCRIPTS_DIR/setup-environment.sh' >/dev/null 2>&1"
fi

# Test that extract-version.sh works with test data
if [ -f "$SCRIPTS_DIR/extract-version.sh" ] && [ -x "$SCRIPTS_DIR/extract-version.sh" ] && [ -f "server/version.py" ]; then
    run_check "extract-version.sh can extract version" "bash '$SCRIPTS_DIR/extract-version.sh' >/dev/null 2>&1"
fi

# Generate final report
echo ""
echo "📊 Validation Summary"
echo "===================="
echo "Total Checks: $TOTAL_CHECKS"
echo "Passed: $PASSED_CHECKS"
echo "Failed: $FAILED_CHECKS"

if [ $FAILED_CHECKS -eq 0 ]; then
    print_status "PASS" "All validation checks passed! ✨"
    echo ""
    echo "🎉 GitHub Actions workflow refactoring is complete and validated!"
    echo ""
    echo "Next steps:"
    echo "1. Test workflows in a feature branch"
    echo "2. Monitor first CI runs for any issues"
    echo "3. Update team documentation as needed"
    
    exit 0
else
    print_status "FAIL" "$FAILED_CHECKS out of $TOTAL_CHECKS checks failed"
    echo ""
    echo "⚠️ Please address the failed checks before proceeding."
    echo ""
    echo "Common fixes:"
    echo "- Run: ./.github/scripts/make-scripts-executable.sh"
    echo "- Check file permissions"
    echo "- Verify script syntax"
    
    exit 1
fi
