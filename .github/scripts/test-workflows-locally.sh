#!/bin/bash
set -euo pipefail

# Test the refactored GitHub Actions setup locally
# Usage: test-workflows-locally.sh [platform] [build_type]

PLATFORM="${1:-$(uname -s | tr '[:upper:]' '[:lower:]')}"
BUILD_TYPE="${2:-development}"

echo "🧪 Testing R2MIDI GitHub Actions setup locally..."
echo "Platform: $PLATFORM"
echo "Build Type: $BUILD_TYPE"
echo ""

# Track test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local allow_failure="${3:-false}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "🔧 Testing: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo "✅ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        if [ "$allow_failure" = "true" ]; then
            echo "⚠️ SKIP: $test_name (optional)"
        else
            echo "❌ FAIL: $test_name"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
    echo ""
}

# Function to run a test with output
run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "🔧 Testing: $test_name"
    
    if output=$(eval "$test_command" 2>&1); then
        echo "✅ PASS: $test_name"
        echo "📋 Output:"
        echo "$output" | head -5
        if [ $(echo "$output" | wc -l) -gt 5 ]; then
            echo "   ... (output truncated)"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "❌ FAIL: $test_name"
        echo "📋 Error output:"
        echo "$output" | head -5
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

echo "🔍 Phase 1: Validation"
echo "======================"

# Run the validation script
run_test_with_output "Validation script" "./.github/scripts/validate-refactoring.sh"

echo "🛠️ Phase 2: Environment Setup"
echo "============================="

# Test environment setup
run_test_with_output "Environment setup" "./.github/scripts/setup-environment.sh"

# Test version extraction
run_test_with_output "Version extraction" "./.github/scripts/extract-version.sh"

echo "📦 Phase 3: Dependency Installation"
echo "==================================="

# Test system dependency detection (don't actually install)
run_test "System dependency validation" "./.github/scripts/install-system-dependencies.sh --help" true

# Test Python dependency installation for development
run_test_with_output "Python dependencies ($BUILD_TYPE)" "./.github/scripts/install-python-dependencies.sh $BUILD_TYPE"

echo "🏗️ Phase 4: Build Environment Validation"
echo "========================================"

# Test build environment validation
run_test_with_output "Build environment validation" "./.github/scripts/validate-build-environment.sh $PLATFORM"

# Test project structure validation
run_test_with_output "Project structure validation" "./.github/scripts/validate-project-structure.sh"

echo "🎯 Phase 5: Build Testing (Dry Run)"
echo "==================================="

# Test Briefcase configuration (dry run)
if command -v briefcase >/dev/null 2>&1; then
    run_test "Briefcase configuration" "briefcase dev --version" true
else
    echo "⚠️ SKIP: Briefcase not installed (expected in some environments)"
    echo ""
fi

# Test Python package building (in temp directory to avoid conflicts)
TEMP_DIR=$(mktemp -d)
cp -r . "$TEMP_DIR/" 2>/dev/null || true
(
    cd "$TEMP_DIR"
    run_test "Python package build test" "./.github/scripts/build-python-package.sh" true
)
rm -rf "$TEMP_DIR"

echo "📋 Phase 6: Summary Generation"
echo "=============================="

# Test build summary generation
run_test_with_output "Build summary generation" "./.github/scripts/generate-build-summary.sh $PLATFORM $BUILD_TYPE 1.0.0-test unsigned"

echo "🔐 Phase 7: Security Checks"
echo "========================="

# Check for potential security issues in scripts
echo "🔧 Testing: Script security analysis"
SECURITY_ISSUES=0

# Check for hardcoded secrets (should be none)
if grep -r "password\|secret\|key" .github/scripts/ --include="*.sh" | grep -v "APPLE_ID_PASSWORD" | grep -v "CERTIFICATE_PASSWORD" | grep -v "password.*variable" | grep -v "password.*parameter" >/dev/null 2>&1; then
    echo "❌ FAIL: Potential hardcoded secrets found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
else
    echo "✅ PASS: No hardcoded secrets detected"
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# Check for unsafe shell practices
if grep -r "eval.*\$" .github/scripts/ --include="*.sh" | grep -v "eval.*command" >/dev/null 2>&1; then
    echo "❌ FAIL: Potentially unsafe eval usage found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
else
    echo "✅ PASS: No unsafe eval usage detected"
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi

TESTS_RUN=$((TESTS_RUN + 2))
echo ""

echo "📊 Test Results Summary"
echo "======================="
echo "Total Tests: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ $SECURITY_ISSUES -gt 0 ]; then
    echo "Security Issues: $SECURITY_ISSUES"
fi

echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "🎉 All tests passed! Your GitHub Actions setup is ready."
    echo ""
    echo "✅ Safe to:"
    echo "   - Commit and push changes"
    echo "   - Create pull requests"
    echo "   - Run CI/CD workflows"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. git add .github/"
    echo "   2. git commit -m 'refactor: move inline code to reusable scripts'"
    echo "   3. git push origin feature/script-refactoring"
    echo "   4. Monitor first CI run for any issues"
    
    exit 0
else
    echo "⚠️ $TESTS_FAILED tests failed. Please address issues before proceeding."
    echo ""
    echo "🔧 Common fixes:"
    echo "   - Run: ./.github/scripts/make-scripts-executable.sh"
    echo "   - Check file permissions: ls -la .github/scripts/"
    echo "   - Verify Python environment: python --version"
    echo "   - Check project structure: ls -la server/ r2midi_client/"
    echo ""
    echo "🆘 For help:"
    echo "   - Review individual script output above"
    echo "   - Run scripts individually for debugging"
    echo "   - Check .github/scripts/README.md"
    
    exit 1
fi
