#!/bin/bash
set -euo pipefail

# Setup environment for R2MIDI builds
# Usage: setup-environment.sh [options]

echo "🔧 Setting up R2MIDI build environment..."

# Function to configure Git (with better error handling)
setup_git() {
    echo "🔗 Configuring Git..."
    
    # Mark workspace as safe directory - handle both CI and local
    if [ -n "${GITHUB_WORKSPACE:-}" ]; then
        git config --global --add safe.directory "$GITHUB_WORKSPACE" 2>/dev/null || echo "⚠️ Could not set GITHUB_WORKSPACE as safe directory"
    fi
    git config --global --add safe.directory "$PWD" 2>/dev/null || echo "⚠️ Could not set PWD as safe directory"
    
    # Set up Git user for CI if in GitHub Actions
    if [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
        git config --local user.name "GitHub Action" 2>/dev/null || echo "⚠️ Could not set Git user.name"
        git config --local user.email "action@github.com" 2>/dev/null || echo "⚠️ Could not set Git user.email"
        echo "✅ Configured Git for GitHub Actions"
    else
        echo "ℹ️ Not in GitHub Actions, skipping Git user configuration"
    fi
    
    echo "✅ Git configuration complete"
}

# Function to setup workspace
setup_workspace() {
    echo "📁 Setting up workspace..."
    
    # Set up Python path
    export PYTHONPATH="${PWD}:${PYTHONPATH:-}"
    if [ -n "${GITHUB_ENV:-}" ]; then
        echo "PYTHONPATH=$PYTHONPATH" >> "$GITHUB_ENV" 2>/dev/null || echo "⚠️ Could not set PYTHONPATH in GITHUB_ENV"
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
        export APP_VERSION="$VERSION"
        if [ -n "${GITHUB_ENV:-}" ]; then
            echo "APP_VERSION=$VERSION" >> "$GITHUB_ENV" 2>/dev/null || echo "⚠️ Could not set APP_VERSION in GITHUB_ENV"
        fi
        
        # Set GitHub Actions outputs if available
        if [ -n "${GITHUB_OUTPUT:-}" ]; then
            echo "version=$VERSION" >> "$GITHUB_OUTPUT" 2>/dev/null || echo "⚠️ Could not set version in GITHUB_OUTPUT"
        fi
        
        echo "✅ Version information set: $VERSION"
    else
        echo "⚠️ Warning: server/version.py not found, version not set"
    fi
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
        mkdir -p build_artifacts || echo "⚠️ Could not create build_artifacts directory"
        mkdir -p release_files || echo "⚠️ Could not create release_files directory"
    fi
    
    echo "✅ Build directories created"
}

# Function to validate environment (non-fatal)
validate_environment() {
    echo "🔍 Validating environment setup..."
    
    local warnings=0
    
    # Check Python
    if ! command -v python >/dev/null 2>&1; then
        echo "⚠️ Warning: Python not found"
        warnings=$((warnings + 1))
    else
        echo "✅ Python: $(python --version 2>/dev/null || echo 'Available')"
    fi
    
    # Check Git
    if ! command -v git >/dev/null 2>&1; then
        echo "⚠️ Warning: Git not found"
        warnings=$((warnings + 1))
    else
        echo "✅ Git: $(git --version 2>/dev/null || echo 'Available')"
    fi
    
    # Check required files (non-fatal)
    local required_files=(
        "pyproject.toml"
        "server/main.py"
        "r2midi_client/main.py"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "⚠️ Warning: Missing file: $file"
            warnings=$((warnings + 1))
        fi
    done
    
    if [ $warnings -eq 0 ]; then
        echo "✅ Environment validation passed"
    else
        echo "⚠️ Environment validation completed with $warnings warnings (non-fatal)"
    fi
}

# Main setup workflow
echo "🚀 Starting environment setup..."

# Run setup functions (don't exit on individual failures)
setup_git || echo "⚠️ Git setup had issues but continuing..."
setup_workspace || echo "⚠️ Workspace setup had issues but continuing..."
setup_version || echo "⚠️ Version setup had issues but continuing..."
setup_build_directories || echo "⚠️ Build directory setup had issues but continuing..."

# Validate the setup (non-fatal)
validate_environment || echo "⚠️ Validation had issues but continuing..."

echo ""
echo "✅ Environment setup complete!"

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

Build Directories:
- build/: $([ -d build ] && echo "✅ Created" || echo "❌ Missing")
- dist/: $([ -d dist ] && echo "✅ Created" || echo "❌ Missing")
- artifacts/: $([ -d artifacts ] && echo "✅ Created" || echo "❌ Missing")

Status: ✅ SETUP COMPLETE (check warnings above if any)
EOF

echo "📋 Setup summary written to build_environment_setup.txt"
