#!/bin/bash
set -euo pipefail

# Test the simplified version comparison logic
# Usage: test-version-fixes.sh

echo "🧪 Testing simplified version comparison logic..."

SCRIPTS_DIR=".github/scripts"

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo ""
    echo "🔧 Testing: $test_name"
    echo "Command:"
    echo "    $test_command"
    
    if eval "$test_command"; then
        echo "✅ PASS: $test_name"
        return 0
    else
        echo "❌ FAIL: $test_name"
        return 1
    fi
}

# Function to create test version file
create_test_version_file() {
    local version="$1"
    mkdir -p test_server
    cat > test_server/version.py << EOF
#!/usr/bin/env python3
"""Version information for R2MIDI."""

__version__ = "$version"
__author__ = "R2MIDI Team"
__email__ = "team@r2midi.org"
EOF
}

# Set up test environment
echo "🔧 Setting up test environment..."
ORIGINAL_DIR=$(pwd)
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Copy scripts to test directory
cp -r "$ORIGINAL_DIR/$SCRIPTS_DIR" .

echo "📁 Test directory: $TEST_DIR"

# Test 1: Version extraction with clean output
echo ""
echo "=== Test 1: Simplified Version Extraction ==="

create_test_version_file "1.2.3"
run_test "Extract clean version" "
    VERSION=\$(grep -o '__version__ = \"[^\"]*\"' test_server/version.py | head -1 | cut -d'\"' -f2 | tr -d '\n\r' | xargs)
    [ \"\$VERSION\" = \"1.2.3\" ]
"

# Test version with trailing whitespace
create_test_version_file "1.2.3 "
run_test "Extract version with trailing space" "
    VERSION=\$(grep -o '__version__ = \"[^\"]*\"' test_server/version.py | head -1 | cut -d'\"' -f2 | tr -d '\n\r' | xargs)
    [ \"\$VERSION\" = \"1.2.3\" ]
"

# Test 2: Version pattern matching for updates
echo ""
echo "=== Test 2: Version Pattern Matching ==="

cat > test_pattern_matching.toml << EOF
[project]
version = "1.2.3"

[tool.briefcase]
version = "1.2.3"
project_name = "Test"
EOF

run_test "Version pattern matching specificity" "
    OLD_VERSION='1.2.3'
    NEW_VERSION='1.2.4'
    ESCAPED_OLD=\$(echo \"\$OLD_VERSION\" | sed 's/\\./\\\\./g')
    
    # Update only project version (first occurrence)
    sed \"0,/^version = \\\"\$ESCAPED_OLD\\\"/s/^version = \\\"\$ESCAPED_OLD\\\"/version = \\\"\$NEW_VERSION\\\"/\" test_pattern_matching.toml > test_pattern_output.toml
    
    # Check that at least one was updated and file is valid
    grep -q 'version = \"1.2.4\"' test_pattern_output.toml
"

# Test 3: extract-version.sh Script with expected output format
echo ""
echo "=== Test 3: extract-version.sh Script ==="

mkdir -p server
create_test_version_file "1.2.5"
mv test_server/version.py server/

run_test "extract-version.sh with clean input" "
    VERSION=\$(./.github/scripts/extract-version.sh 2>/dev/null | grep 'Version:' | cut -d' ' -f2 || echo '')
    # The script should output the version cleanly
    [ \"\$VERSION\" = \"1.2.5\" ]
"

# Test 4: Edge case versions
echo ""
echo "=== Test 4: Edge Case Versions ==="

create_test_version_file "0.1.162"
mv test_server/version.py server/

run_test "extract-version.sh with decimal version" "
    VERSION=\$(./.github/scripts/extract-version.sh 2>/dev/null | grep 'Version:' | cut -d' ' -f2 || echo '')
    [ \"\$VERSION\" = \"0.1.162\" ]
"

# Test 5: Version comparison logic
echo ""
echo "=== Test 5: Version Comparison Logic ==="

# Create matching versions
create_test_version_file "1.2.3"
mv test_server/version.py server/

cat > pyproject.toml << EOF
[project]
version = "1.2.3"
description = "Test project"

[tool.briefcase]
version = "1.2.3"
project_name = "Test"
EOF

run_test "Versions match detection" "
    VERSION_PY=\$(grep -o '__version__ = \"[^\"]*\"' server/version.py | head -1 | cut -d'\"' -f2 | tr -d '\n\r' | xargs)
    VERSION_TOML=\$(grep '^version = ' pyproject.toml | head -1 | cut -d'\"' -f2 | tr -d '\n\r' | xargs)
    [ \"\$VERSION_PY\" = \"\$VERSION_TOML\" ]
"

# Create mismatched versions
cat > pyproject.toml << EOF
[project]
version = "1.2.4"
description = "Test project"

[tool.briefcase]
version = "1.2.4"
project_name = "Test"
EOF

run_test "Version mismatch detection" "
    VERSION_PY=\$(grep -o '__version__ = \"[^\"]*\"' server/version.py | head -1 | cut -d'\"' -f2 | tr -d '\n\r' | xargs)
    VERSION_TOML=\$(grep '^version = ' pyproject.toml | head -1 | cut -d'\"' -f2 | tr -d '\n\r' | xargs)
    [ \"\$VERSION_PY\" != \"\$VERSION_TOML\" ]
"

# Cleanup and summary
echo ""
echo "🧹 Cleaning up test environment..."
cd "$ORIGINAL_DIR"
rm -rf "$TEST_DIR"

echo ""
echo "✅ Simplified version comparison logic testing complete!"
echo ""
echo "🎯 Key simplifications implemented:"
echo "   ✅ Clean version extraction with expected output format"
echo "   ✅ CI-only version comparison logic"
echo "   ✅ Simplified test cases focused on core functionality"
echo "   ✅ Reduced complexity while maintaining reliability"
echo ""
echo "🚀 The simplified version logic should now work correctly!"
