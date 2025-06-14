#!/bin/bash
set -euo pipefail

# Validate R2MIDI project structure and configuration
# Usage: validate-project-structure.sh

echo "🔍 Validating R2MIDI project structure..."

# Colors for output
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
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️ $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️ $message${NC}"
            ;;
    esac
}

# Global variables for tracking validation results
ERRORS=0
WARNINGS=0
CHECKS=0

# Function to check if a file exists and is readable
check_file() {
    local file="$1"
    local description="$2"
    local required="${3:-true}"
    
    ((CHECKS++))
    
    if [ -f "$file" ] && [ -r "$file" ]; then
        print_status "OK" "$description: $file"
        return 0
    else
        if [ "$required" = "true" ]; then
            print_status "ERROR" "$description missing: $file"
            ((ERRORS++))
            return 1
        else
            print_status "WARNING" "$description not found: $file (optional)"
            ((WARNINGS++))
            return 1
        fi
    fi
}

# Function to check if a directory exists
check_directory() {
    local dir="$1"
    local description="$2"
    local required="${3:-true}"
    
    ((CHECKS++))
    
    if [ -d "$dir" ]; then
        print_status "OK" "$description: $dir"
        return 0
    else
        if [ "$required" = "true" ]; then
            print_status "ERROR" "$description missing: $dir"
            ((ERRORS++))
            return 1
        else
            print_status "WARNING" "$description not found: $dir (optional)"
            ((WARNINGS++))
            return 1
        fi
    fi
}

# Function to validate pyproject.toml structure
validate_pyproject_toml() {
    echo ""
    print_status "INFO" "Validating pyproject.toml configuration..."
    
    if ! check_file "pyproject.toml" "Main configuration file"; then
        return 1
    fi
    
    # Check for required sections
    local required_sections=(
        "\[build-system\]"
        "\[project\]"
        "\[tool\.briefcase\]"
        "\[tool\.briefcase\.app\.server\]"
        "\[tool\.briefcase\.app\.r2midi-client\]"
    )
    
    for section in "${required_sections[@]}"; do
        ((CHECKS++))
        if grep -q "$section" pyproject.toml; then
            print_status "OK" "Found section: $section"
        else
            print_status "ERROR" "Missing section in pyproject.toml: $section"
            ((ERRORS++))
        fi
    done
    
    # Check for required project metadata
    local required_metadata=(
        "name"
        "version"
        "description"
        "authors"
        "requires-python"
        "dependencies"
    )
    
    for metadata in "${required_metadata[@]}"; do
        ((CHECKS++))
        if grep -q "^$metadata = " pyproject.toml; then
            print_status "OK" "Found project metadata: $metadata"
        else
            print_status "ERROR" "Missing project metadata: $metadata"
            ((ERRORS++))
        fi
    done
    
    # Validate version consistency
    ((CHECKS++))
    if [ -f "server/version.py" ]; then
        local pyproject_version=$(grep '^version = ' pyproject.toml | cut -d'"' -f2)
        local server_version=$(grep '__version__ = ' server/version.py | cut -d'"' -f2)
        
        if [ "$pyproject_version" = "$server_version" ]; then
            print_status "OK" "Version consistency between pyproject.toml and server/version.py"
        else
            print_status "WARNING" "Version mismatch: pyproject.toml ($pyproject_version) vs server/version.py ($server_version)"
            ((WARNINGS++))
        fi
    fi
}

# Function to validate Python source structure
validate_python_structure() {
    echo ""
    print_status "INFO" "Validating Python source structure..."
    
    # Check main directories
    check_directory "server" "Server application directory"
    check_directory "r2midi_client" "Client application directory"
    check_directory "tests" "Test directory" false
    
    # Check server files
    check_file "server/__init__.py" "Server package init file" false
    check_file "server/main.py" "Server main entry point"
    check_file "server/version.py" "Server version file"
    
    # Check client files
    check_file "r2midi_client/__init__.py" "Client package init file" false
    check_file "r2midi_client/main.py" "Client main entry point"
    
    # Check if main.py files have proper entry points
    ((CHECKS++))
    if [ -f "server/main.py" ]; then
        if grep -q "def main" server/main.py; then
            print_status "OK" "Server main.py has main() function"
        else
            print_status "WARNING" "Server main.py may be missing main() function"
            ((WARNINGS++))
        fi
    fi
    
    ((CHECKS++))
    if [ -f "r2midi_client/main.py" ]; then
        if grep -q "def main" r2midi_client/main.py; then
            print_status "OK" "Client main.py has main() function"
        else
            print_status "WARNING" "Client main.py may be missing main() function"
            ((WARNINGS++))
        fi
    fi
}

# Function to validate dependencies
validate_dependencies() {
    echo ""
    print_status "INFO" "Validating dependencies..."
    
    check_file "requirements.txt" "Main requirements file"
    check_file "r2midi_client/requirements.txt" "Client requirements file" false
    
    # Check for critical dependencies in requirements.txt
    if [ -f "requirements.txt" ]; then
        local critical_deps=(
            "fastapi"
            "uvicorn"
            "pydantic"
            "python-rtmidi"
            "mido"
        )
        
        for dep in "${critical_deps[@]}"; do
            ((CHECKS++))
            if grep -q "^$dep" requirements.txt; then
                print_status "OK" "Found critical dependency: $dep"
            else
                print_status "WARNING" "Missing critical dependency: $dep"
                ((WARNINGS++))
            fi
        done
    fi
    
    # Check client-specific dependencies
    if [ -f "r2midi_client/requirements.txt" ]; then
        ((CHECKS++))
        if grep -q "pyqt6\|PyQt6" r2midi_client/requirements.txt; then
            print_status "OK" "Found PyQt6 dependency for client"
        else
            print_status "WARNING" "PyQt6 dependency not found in client requirements"
            ((WARNINGS++))
        fi
    fi
}

# Function to validate build configuration
validate_build_config() {
    echo ""
    print_status "INFO" "Validating build configuration..."
    
    # Check for platform-specific configurations in pyproject.toml
    local platforms=("macOS" "windows" "linux")
    
    for platform in "${platforms[@]}"; do
        ((CHECKS++))
        if grep -q "\[tool\.briefcase\.app\.server\.$platform\]" pyproject.toml; then
            print_status "OK" "Found server configuration for $platform"
        else
            print_status "WARNING" "Missing server configuration for $platform"
            ((WARNINGS++))
        fi
        
        ((CHECKS++))
        if grep -q "\[tool\.briefcase\.app\.r2midi-client\.$platform\]" pyproject.toml; then
            print_status "OK" "Found client configuration for $platform"
        else
            print_status "WARNING" "Missing client configuration for $platform"
            ((WARNINGS++))
        fi
    done
    
    # Check for macOS-specific files
    check_file "entitlements.plist" "macOS entitlements file"
    
    # Validate entitlements.plist structure
    if [ -f "entitlements.plist" ]; then
        ((CHECKS++))
        if grep -q "com.apple.security.network.client" entitlements.plist; then
            print_status "OK" "Entitlements include network client permission"
        else
            print_status "WARNING" "Entitlements may be missing network client permission"
            ((WARNINGS++))
        fi
    fi
}

# Function to validate assets and resources
validate_assets() {
    echo ""
    print_status "INFO" "Validating assets and resources..."
    
    # Check for icon files
    check_file "r2midi.png" "Application icon (PNG)" false
    check_file "r2midi.ico" "Application icon (ICO)" false
    check_file "r2midi.icns" "Application icon (ICNS)" false
    check_directory "r2midi.iconset" "macOS iconset directory" false
    
    # Check resources directory
    check_directory "resources" "Resources directory" false
    
    # Check for documentation
    check_file "README.md" "Project README"
    check_file "LICENSE" "License file"
    check_file "CHANGELOG.md" "Changelog file" false
    
    # Check for CI/CD configuration
    check_directory ".github" "GitHub configuration directory"
    check_directory ".github/workflows" "GitHub workflows directory"
    check_directory ".github/scripts" "GitHub scripts directory" false
}

# Function to validate Git configuration
validate_git_config() {
    echo ""
    print_status "INFO" "Validating Git configuration..."
    
    check_file ".gitignore" "Git ignore file"
    
    # Check if we're in a Git repository
    ((CHECKS++))
    if git rev-parse --git-dir >/dev/null 2>&1; then
        print_status "OK" "Project is a Git repository"
        
        # Check for common ignore patterns
        if [ -f ".gitignore" ]; then
            local ignore_patterns=(
                "__pycache__"
                "*.pyc"
                "build/"
                "dist/"
                ".DS_Store"
            )
            
            for pattern in "${ignore_patterns[@]}"; do
                ((CHECKS++))
                if grep -q "$pattern" .gitignore; then
                    print_status "OK" "Git ignores: $pattern"
                else
                    print_status "WARNING" "Git ignore missing pattern: $pattern"
                    ((WARNINGS++))
                fi
            done
        fi
    else
        print_status "WARNING" "Not a Git repository"
        ((WARNINGS++))
    fi
}

# Function to validate file permissions
validate_permissions() {
    echo ""
    print_status "INFO" "Validating file permissions..."
    
    # Check script permissions
    local scripts=(
        ".github/scripts/build-briefcase-apps.sh"
        ".github/scripts/sign-and-notarize-macos.sh"
        ".github/scripts/package-windows-apps.sh"
        ".github/scripts/package-linux-apps.sh"
        ".github/scripts/package-macos-apps.sh"
        ".github/scripts/update-version.sh"
        ".github/scripts/validate-build-environment.sh"
        ".github/scripts/validate-project-structure.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            ((CHECKS++))
            if [ -x "$script" ]; then
                print_status "OK" "Script is executable: $script"
            else
                print_status "WARNING" "Script is not executable: $script"
                ((WARNINGS++))
            fi
        fi
    done
}

# Main validation workflow
echo "🚀 Starting R2MIDI project structure validation..."
echo "Working directory: $(pwd)"
echo ""

# Run all validation functions
validate_pyproject_toml
validate_python_structure
validate_dependencies
validate_build_config
validate_assets
validate_git_config
validate_permissions

# Generate validation summary
echo ""
echo "📋 Validation Summary"
echo "===================="
print_status "INFO" "Total checks performed: $CHECKS"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_status "OK" "All validations passed! Project structure is perfect."
    exit_code=0
elif [ $ERRORS -eq 0 ]; then
    print_status "WARNING" "Validation completed with $WARNINGS warnings."
    print_status "INFO" "Project structure is mostly correct, but could be improved."
    exit_code=0
else
    print_status "ERROR" "Validation failed with $ERRORS errors and $WARNINGS warnings."
    print_status "ERROR" "Project structure needs fixes before building."
    exit_code=1
fi

# Generate detailed report
cat > validation_report.txt << EOF
R2MIDI Project Structure Validation Report
==========================================

Validation Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Working Directory: $(pwd)
Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "Not available")

Summary:
- Total Checks: $CHECKS
- Errors: $ERRORS
- Warnings: $WARNINGS
- Status: $([ $exit_code -eq 0 ] && echo "PASSED" || echo "FAILED")

Next Steps:
EOF

if [ $ERRORS -gt 0 ]; then
    echo "- Fix all ERROR items above before proceeding with builds" >> validation_report.txt
fi

if [ $WARNINGS -gt 0 ]; then
    echo "- Review WARNING items to improve project quality" >> validation_report.txt
fi

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "- Project is ready for building and deployment" >> validation_report.txt
fi

echo ""
print_status "INFO" "Detailed report saved to: validation_report.txt"

exit $exit_code