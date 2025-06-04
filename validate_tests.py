#!/usr/bin/env python3
"""
Validate that pytest tests are properly configured and discoverable
"""
import subprocess
import sys
import os

def run_command(cmd, description):
    """Run a command and print the results"""
    print(f"\n{'='*60}")
    print(f"{description}")
    print(f"{'='*60}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, shell=True)
        print(f"Command: {cmd}")
        print(f"Exit code: {result.returncode}")
        
        if result.stdout:
            print(f"\nOutput:\n{result.stdout}")
        
        if result.stderr:
            print(f"\nErrors:\n{result.stderr}")
            
        return result.returncode == 0
    except Exception as e:
        print(f"Error running command: {e}")
        return False

def main():
    """Main validation function"""
    print("R2MIDI Pytest Validation")
    print("========================")
    
    # Check Python version
    print(f"\nPython version: {sys.version}")
    
    # Check if we're in the right directory
    if not os.path.exists('pyproject.toml'):
        print("ERROR: Not in r2midi root directory!")
        return 1
    
    # Check if pytest is installed
    success = run_command(
        "python -m pip show pytest",
        "1. Checking if pytest is installed"
    )
    
    if not success:
        print("\nERROR: pytest is not installed!")
        print("Run: pip install pytest pytest-asyncio pytest-mock pytest-cov")
        return 1
    
    # Check test discovery
    success = run_command(
        "pytest --collect-only -q",
        "2. Checking pytest test discovery"
    )
    
    # Check for import errors
    run_command(
        "pytest --collect-only -v 2>&1 | grep -E '(ImportError|ModuleNotFoundError|cannot import)' || echo 'No import errors found'",
        "3. Checking for import errors"
    )
    
    # List all discovered tests
    run_command(
        "pytest --collect-only -q | grep -E '^tests/' | sort | uniq",
        "4. Listing all discovered test files"
    )
    
    # Try to run a simple test
    run_command(
        "pytest tests/unit/server/test_models.py -v -k test_device_model",
        "5. Running a sample test"
    )
    
    # Check test structure
    print(f"\n{'='*60}")
    print("6. Checking test structure")
    print(f"{'='*60}")
    
    test_dirs = [
        "tests/unit/server",
        "tests/unit/r2midi_client"
    ]
    
    for test_dir in test_dirs:
        if os.path.exists(test_dir):
            files = [f for f in os.listdir(test_dir) if f.startswith('test_') and f.endswith('.py')]
            print(f"\n{test_dir}:")
            for f in files:
                print(f"  ✓ {f}")
        else:
            print(f"\n❌ Missing directory: {test_dir}")
    
    # Check for common issues
    print(f"\n{'='*60}")
    print("7. Checking for common issues")
    print(f"{'='*60}")
    
    issues = []
    
    # Check if conftest.py exists
    if not os.path.exists('conftest.py'):
        issues.append("Missing conftest.py in root directory")
    
    # Check if __init__.py exists in test directories
    init_files = [
        "tests/__init__.py",
        "tests/unit/__init__.py",
        "tests/unit/server/__init__.py",
        "tests/unit/r2midi_client/__init__.py"
    ]
    
    for init_file in init_files:
        if not os.path.exists(init_file):
            issues.append(f"Missing {init_file}")
    
    # Check pytest.ini
    if not os.path.exists('pytest.ini'):
        issues.append("Missing pytest.ini")
    
    if issues:
        print("\nIssues found:")
        for issue in issues:
            print(f"  ⚠️  {issue}")
    else:
        print("\n✅ No configuration issues found!")
    
    # Summary
    print(f"\n{'='*60}")
    print("Summary")
    print(f"{'='*60}")
    
    if success and not issues:
        print("✅ Pytest is properly configured and tests are discoverable!")
        return 0
    else:
        print("❌ There are issues with the test configuration.")
        print("\nRecommended fixes:")
        print("1. Run: pip install -e .[test]")
        print("2. Ensure all __init__.py files exist")
        print("3. Check that imports in test files are correct")
        return 1

if __name__ == "__main__":
    sys.exit(main())
