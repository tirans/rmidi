#!/bin/bash
set -euo pipefail

# Setup environment for R2MIDI builds
# Usage: setup-environment.sh [options]

echo "🔧 Setting up R2MIDI build environment..."

# Function to configure Git
setup_git() {
    echo "🔗 Configuring Git..."
    
    # Mark workspace as safe directory - handle both CI and local
    if [ -n "${GITHUB_WORKSPACE:-}" ]; then
        git config --global --add safe.directory "$GITHUB_WORKSPACE" 2>/dev/null || true
    fi
    git config --global --add safe.directory "$PWD" 2>/dev/null || true
    
    # Set up Git user for CI if in GitHub Actions
    if [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
        git config --local user.name "GitHub Action" 2>/dev/null || true
        git config --local user.email "action@github.com" 2>/dev/null || true
        echo "✅ Configured Git for GitHub Actions"
    else
        echo "ℹ️ Not in GitHub Actions, skipping Git user configuration"
    fi
    
    echo "✅ Git configuration complete"
}

# Function to setup workspace
setup_workspace() {
    echo "📁 Setting up workspace..."
    
    # Skip submodule setup since server/midi-presets is in .gitignore
    # This indicates the build is designed to work without it
    echo "ℹ️ Skipping submodule setup (not required for build)"
    
    # Set up Python path
    export PYTHONPATH="${PWD}:${PYTHONPATH:-}"
    if [ -n "${GITHUB_ENV:-}" ]; then
        echo "PYTHONPATH=$PYTHONPATH" >> "$GITHUB_ENV"
    fi
    
    echo "✅ Workspace setup complete"
}

# Function to extract and set version information
setup_version() {
    echo "📋 Setting up version information..."
    
    if [ -f "server/version.py" ]; then
        VERSION=$(grep -o '__version__ = "[^"]*"' server/version.py | cut -d'"' -f2 | tr -d '\n\r' | xargs)
        echo "Extracted version: $VERSION"
        
        # Set environment variables
        if [ -n "${GITHUB_ENV:-}" ]; then
            echo "APP_VERSION=$VERSION" >> "$GITHUB_ENV"
        fi
        export APP_VERSION="$VERSION"
        
        # Set GitHub Actions outputs if available
        if [ -n "${GITHUB_OUTPUT:-}" ]; then
            echo "version=$VERSION" >> "$GITHUB_OUTPUT"
        fi
        
        echo "✅ Version information set: $VERSION"
    else
        echo "⚠️ Warning: server/version.py not found, version not set"
    fi
}

# Function to setup platform-specific environment
setup_platform_environment() {
    local platform=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    echo "🖥️ Setting up platform-specific environment for $platform..."
    
    case "$platform" in
        linux)
            # Set up display for headless testing
            export DISPLAY="${DISPLAY:-:99}"
            
            # Set up virtual display if available and in CI
            if [ "${GITHUB_ACTIONS:-false}" = "true" ] && command -v Xvfb >/dev/null 2>&1; then
                echo "📺 Setting up virtual display for testing..."
                export QT_QPA_PLATFORM=offscreen
            fi
            ;;
        darwin)
            # macOS-specific setup
            echo "🍎 macOS environment setup"
            
            # Set up code signing environment if certificates are available
            if [ -n "${APPLE_CERTIFICATE_P12:-}" ]; then
                echo "🔐 Apple certificates detected"
                export CODESIGN_AVAILABLE=true
            fi
            ;;
        *)
            echo "ℹ️ Platform: $platform (no specific setup required)"
            ;;
    esac
    
    echo "✅ Platform environment setup complete"
}

# Function to create build directories
setup_build_directories() {
    echo "📁 Creating build directories..."
    
    # Create standard build directories
    mkdir -p build
    mkdir -p dist
    mkdir -p artifacts
    
    # Create platform-specific directories if needed
    if [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
        mkdir -p build_artifacts
        mkdir -p release_files
    fi
    
    echo "✅ Build directories created"
}

# Function to setup CI-specific environment
setup_ci_environment() {
    if [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
        echo "🤖 Setting up CI-specific environment..."
        
        # Set up step summary file
        if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
            {
                echo "## 🚀 R2MIDI Build Environment Setup"
                echo ""
                echo "**Environment**: $(uname -s) $(uname -m)"
                echo "**Python**: $(python --version 2>/dev/null || echo 'Not available')"
                echo "**Working Directory**: $PWD"
                
                if [ -n "${APP_VERSION:-}" ]; then
                    echo "**Version**: $APP_VERSION"
                fi
                
                echo "**Setup Time**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
            } >> "$GITHUB_STEP_SUMMARY"
        fi
        
        echo "✅ CI environment setup complete"
    else
        echo "ℹ️ Not in CI environment, skipping CI-specific setup"
    fi
}

# Function to validate environment
validate_environment() {
    echo "🔍 Validating environment setup..."
    
    local errors=0
    
    # Check Python
    if ! command -v python >/dev/null 2>&1; then
        echo "❌ Python not found"
        errors=$((errors + 1))
    else
        echo "✅ Python: $(python --version 2>/dev/null || echo 'Available')"
    fi
    
    # Check Git
    if ! command -v git >/dev/null 2>&1; then
        echo "❌ Git not found"
        errors=$((errors + 1))
    else
        echo "✅ Git: $(git --version 2>/dev/null || echo 'Available')"
    fi
    
    # Check required files
    local required_files=(
        "pyproject.toml"
        "server/main.py"
        "r2midi_client/main.py"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "❌ Missing required file: $file"
            errors=$((errors + 1))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        echo "✅ Environment validation passed"
    else
        echo "❌ Environment validation failed with $errors errors"
        exit 1
    fi
}

# Main setup workflow
echo "🚀 Starting environment setup..."

# Run setup functions
setup_git
setup_workspace
setup_version
setup_platform_environment
setup_build_directories
setup_ci_environment

# Validate the setup
validate_environment

echo ""
echo "✅ Environment setup complete!"
echo "📋 Setup summary written to build_environment_setup.txt"

# Generate setup summary for troubleshooting
cat > build_environment_setup.txt << EOF
R2MIDI Build Environment Setup Summary
======================================

Setup Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Platform: $(uname -s) $(uname -m)
Working Directory: $PWD
Python Version: $(python --version 2>/dev/null || echo 'Not available')
Git Version: $(git --version 2>/dev/null || echo 'Not available')

Environment Variables:
- PYTHONPATH: ${PYTHONPATH:-"Not set"}
- APP_VERSION: ${APP_VERSION:-"Not set"}
- GITHUB_ACTIONS: ${GITHUB_ACTIONS:-"false"}
- DISPLAY: ${DISPLAY:-"Not set"}

Build Directories:
- build/: $([ -d build ] && echo "✅ Created" || echo "❌ Missing")
- dist/: $([ -d dist ] && echo "✅ Created" || echo "❌ Missing")
- artifacts/: $([ -d artifacts ] && echo "✅ Created" || echo "❌ Missing")

Status: ✅ READY FOR BUILD
EOF
