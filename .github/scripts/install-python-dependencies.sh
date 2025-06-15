#!/bin/bash
set -euo pipefail

# Install Python dependencies for R2MIDI project
# Usage: install-python-dependencies.sh [build_type]

BUILD_TYPE="${1:-production}"

echo "🐍 Installing Python dependencies for $BUILD_TYPE build..."

# Upgrade pip first
echo "📦 Upgrading pip..."
python -m pip install --upgrade pip

# Install core build tools
echo "🔧 Installing core build tools..."
python -m pip install --upgrade setuptools wheel

# Install project-specific dependencies based on build type
case "$BUILD_TYPE" in
    production|staging)
        echo "📦 Installing production dependencies..."
        
        # Install Briefcase for application building
        python -m pip install briefcase
        
        # Install main requirements
        if [ -f requirements.txt ]; then 
            echo "📋 Installing server requirements..."
            pip install -r requirements.txt
        else
            echo "⚠️ Warning: requirements.txt not found"
        fi
        
        # Install client requirements
        if [ -f r2midi_client/requirements.txt ]; then 
            echo "📋 Installing client requirements..."
            pip install -r r2midi_client/requirements.txt
        else
            echo "⚠️ Warning: r2midi_client/requirements.txt not found"
        fi
        ;;
        
    development|dev)
        echo "🔧 Installing development dependencies..."
        
        # Install all production dependencies first
        python -m pip install briefcase
        
        if [ -f requirements.txt ]; then 
            pip install -r requirements.txt
        fi
        
        if [ -f r2midi_client/requirements.txt ]; then 
            pip install -r r2midi_client/requirements.txt
        fi
        
        # Install development and testing tools
        python -m pip install \
            flake8 \
            pytest \
            pytest-cov \
            black \
            isort \
            mypy \
            build \
            twine
        
        # Install the project in development mode
        if [ -f pyproject.toml ] || [ -f setup.py ]; then
            echo "📦 Installing project in development mode..."
            pip install -e ".[test]" || pip install -e .
        fi
        ;;
        
    testing|test)
        echo "🧪 Installing testing dependencies..."
        
        # Install minimal dependencies for testing
        if [ -f requirements.txt ]; then 
            pip install -r requirements.txt
        fi
        
        if [ -f r2midi_client/requirements.txt ]; then 
            pip install -r r2midi_client/requirements.txt
        fi
        
        # Install testing tools
        python -m pip install \
            flake8 \
            pytest \
            pytest-cov
        
        # Install the project for testing
        if [ -f pyproject.toml ] || [ -f setup.py ]; then
            pip install -e ".[test]" || pip install -e .
        fi
        ;;
        
    ci)
        echo "🤖 Installing CI dependencies..."
        
        # Install all dependencies needed for CI
        python -m pip install briefcase
        
        if [ -f requirements.txt ]; then 
            pip install -r requirements.txt
        fi
        
        if [ -f r2midi_client/requirements.txt ]; then 
            pip install -r r2midi_client/requirements.txt
        fi
        
        # Install CI-specific tools
        python -m pip install \
            flake8 \
            pytest \
            pytest-cov \
            black \
            isort \
            mypy \
            build \
            twine \
            safety \
            bandit
        
        # Install the project for testing
        if [ -f pyproject.toml ] || [ -f setup.py ]; then
            pip install -e ".[test]" || pip install -e .
        fi
        ;;
        
    package|packaging)
        echo "📦 Installing packaging dependencies..."
        
        # Only install tools needed for packaging
        python -m pip install \
            build \
            twine \
            setuptools \
            wheel
        ;;
        
    *)
        echo "❌ Error: Unknown build type '$BUILD_TYPE'"
        echo "Valid types: production, development, testing, ci, package"
        exit 1
        ;;
esac

# Verify installation
echo "🔍 Verifying Python dependencies..."

# Check critical packages
if python -c "import pip" 2>/dev/null; then
    echo "✅ pip is working"
else
    echo "❌ pip verification failed"
    exit 1
fi

# Check if we're in CI and can import the main modules
if [ "${GITHUB_ACTIONS:-false}" = "true" ] && [ "$BUILD_TYPE" != "package" ]; then
    echo "🤖 CI verification: Testing module imports..."
    
    # Set PYTHONPATH for testing
    export PYTHONPATH="${PWD}:${PYTHONPATH:-}"
    
    # Test critical imports
    if python -c "import server.main" 2>/dev/null; then
        echo "✅ Server module imports successfully"
    else
        echo "⚠️ Warning: Server module import failed (may be expected in some contexts)"
    fi
    
    if python -c "import r2midi_client.main" 2>/dev/null; then
        echo "✅ Client module imports successfully"
    else
        echo "⚠️ Warning: Client module import failed (may be expected in some contexts)"
    fi
fi

# Show installed package summary
echo "📋 Installed Python packages summary:"
echo "Python version: $(python --version)"
echo "Pip version: $(pip --version)"

if [ "$BUILD_TYPE" != "package" ]; then
    echo "Key packages:"
    
    # Check for Briefcase
    if pip show briefcase >/dev/null 2>&1; then
        briefcase_version=$(pip show briefcase | grep Version | cut -d' ' -f2)
        echo "  - Briefcase: $briefcase_version"
    fi
    
    # Check for pytest
    if pip show pytest >/dev/null 2>&1; then
        pytest_version=$(pip show pytest | grep Version | cut -d' ' -f2)
        echo "  - pytest: $pytest_version"
    fi
    
    # Check for PyQt6
    if pip show PyQt6 >/dev/null 2>&1; then
        pyqt6_version=$(pip show PyQt6 | grep Version | cut -d' ' -f2)
        echo "  - PyQt6: $pyqt6_version"
    fi
    
    # Check for FastAPI
    if pip show fastapi >/dev/null 2>&1; then
        fastapi_version=$(pip show fastapi | grep Version | cut -d' ' -f2)
        echo "  - FastAPI: $fastapi_version"
    fi
fi

echo "✅ Python dependencies installation complete for $BUILD_TYPE build!"
