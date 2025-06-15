#!/bin/bash
# Reorganize R2MIDI project structure

echo "R2MIDI Project Reorganization"
echo "=============================="
echo ""

# Function to create directory if it doesn't exist
create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "Created: $1"
    fi
}

# Function to move file if it exists
move_file() {
    if [ -f "$1" ]; then
        mv "$1" "$2"
        echo "Moved: $1 -> $2"
    else
        echo "Skip: $1 (not found)"
    fi
}

echo "1. Creating new directory structure..."
echo "-------------------------------------"

# Create new directories
create_dir "tests/scripts"
create_dir "tests/docs"
create_dir "tests/integration"
create_dir "tests/fixtures"
create_dir "scripts/dev"
create_dir "scripts/build"
create_dir "config"

echo ""
echo "2. Moving test-related files..."
echo "--------------------------------"

# Move test scripts
move_file "test_imports.py" "tests/scripts/"
move_file "test_structure.py" "tests/scripts/"
move_file "validate_pytest.py" "tests/scripts/"
move_file "validate_tests.py" "tests/scripts/"

# Move test documentation
move_file "TEST_FIXES_SUMMARY.md" "tests/docs/"

echo ""
echo "3. Moving utility scripts..."
echo "-----------------------------"

# Move development scripts
move_file "dev.sh" "scripts/dev/"
move_file "apply_fixes.sh" "scripts/dev/"
move_file "fix_git_submodule.sh" "scripts/dev/"
move_file "make_executable.sh" "scripts/dev/"

# Move build scripts
move_file "setup_icons.sh" "scripts/build/"
move_file "test_briefcase_builds.sh" "scripts/build/"
move_file "test_version_increment_robust.sh" "scripts/build/"

echo ""
echo "4. Moving configuration files..."
echo "---------------------------------"

# Move config files
move_file "entitlements.plist" "config/"
move_file "renovate.json" "config/"
move_file "pre-commit" "config/"

echo ""
echo "5. Moving documentation..."
echo "--------------------------"

# Move additional docs
move_file "briefcase_fixes.md" "docs/"
# Remove duplicate workflow file if it exists
if [ -f "python-package-improved.yml" ]; then
    rm "python-package-improved.yml"
    echo "Removed: python-package-improved.yml (duplicate)"
fi

echo ""
echo "6. Creating README files..."
echo "----------------------------"

# Create README for scripts directory
cat > scripts/README.md << 'EOF'
# R2MIDI Scripts

This directory contains utility and build scripts for the R2MIDI project.

## Directory Structure

- `dev/` - Development and maintenance scripts
  - `dev.sh` - Development environment setup
  - `apply_fixes.sh` - Apply project fixes
  - `fix_git_submodule.sh` - Fix git submodule issues
  - `make_executable.sh` - Make scripts executable

- `build/` - Build and packaging scripts
  - `setup_icons.sh` - Set up application icons
  - `test_briefcase_builds.sh` - Test Briefcase builds
  - `test_version_increment_robust.sh` - Test version incrementing

## Usage

All scripts should be run from the project root directory:

```bash
# Development scripts
./scripts/dev/dev.sh

# Build scripts
./scripts/build/test_briefcase_builds.sh
```
EOF
echo "Created: scripts/README.md"

# Create README for tests/scripts directory
cat > tests/scripts/README.md << 'EOF'
# Test Scripts

This directory contains scripts for validating and testing the R2MIDI project.

## Scripts

- `test_imports.py` - Validate Python imports
- `test_structure.py` - Validate project structure
- `validate_pytest.py` - Comprehensive pytest validation
- `validate_tests.py` - Test suite validation

## Usage

Run from the project root:

```bash
python tests/scripts/validate_pytest.py
python tests/scripts/test_imports.py
```
EOF
echo "Created: tests/scripts/README.md"

echo ""
echo "7. Updating pyproject.toml references..."
echo "-----------------------------------------"

# Update pyproject.toml to reference new config location
if [ -f "pyproject.toml" ]; then
    # Update entitlements reference
    sed -i.bak 's|entitlements_file = "entitlements.plist"|entitlements_file = "config/entitlements.plist"|g' pyproject.toml
    rm pyproject.toml.bak
    echo "Updated: pyproject.toml entitlements path"
fi

echo ""
echo "8. Making scripts executable..."
echo "--------------------------------"

# Make all scripts executable
find scripts -name "*.sh" -type f -exec chmod +x {} \;
find tests/scripts -name "*.py" -type f -exec chmod +x {} \;
echo "Made all scripts executable"

echo ""
echo "9. Creating convenience symlinks..."
echo "------------------------------------"

# Create symlinks for commonly used scripts (optional)
if [ ! -L "dev.sh" ]; then
    ln -s scripts/dev/dev.sh dev.sh
    echo "Created symlink: dev.sh -> scripts/dev/dev.sh"
fi

echo ""
echo "=============================="
echo "Reorganization Complete!"
echo "=============================="
echo ""
echo "Summary of changes:"
echo "- Test-related files moved to tests/"
echo "- Utility scripts moved to scripts/"
echo "- Configuration files moved to config/"
echo "- README files created for documentation"
echo "- pyproject.toml updated with new paths"
echo ""
echo "Next steps:"
echo "1. Review the changes"
echo "2. Update any hardcoded paths in your scripts"
echo "3. Commit the reorganized structure"
echo ""
echo "To run scripts from their new locations:"
echo "  ./scripts/dev/apply_fixes.sh"
echo "  python tests/scripts/validate_pytest.py"
echo "  ./scripts/build/test_briefcase_builds.sh"
