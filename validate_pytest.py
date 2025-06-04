#!/usr/bin/env python3
"""
Comprehensive pytest validation script for r2midi
"""
import subprocess
import sys
import os
import json
from pathlib import Path

def run_command(cmd, description="", capture=True):
    """Run a command and return the result"""
    if description:
        print(f"\n{'='*60}")
        print(f"{description}")
        print(f"{'='*60}")
    
    print(f"Command: {cmd}")
    
    if capture:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode, result.stdout, result.stderr
    else:
        # Run without capturing for real-time output
        result = subprocess.run(cmd, shell=True)
        return result.returncode, "", ""

def check_prerequisites():
    """Check if all prerequisites are installed"""
    print("\n1. Checking Prerequisites")
    print("=" * 60)
    
    issues = []
    
    # Check Python version
    python_version = sys.version_info
    print(f"✓ Python version: {python_version.major}.{python_version.minor}.{python_version.micro}")
    
    # Check required packages
    packages = ["pytest", "pytest-asyncio", "pytest-mock", "pytest-cov"]
    for package in packages:
        code, stdout, _ = run_command(f"python -m pip show {package}", capture=True)
        if code == 0:
            # Extract version from output
            for line in stdout.split('\n'):
                if line.startswith('Version:'):
                    version = line.split(':')[1].strip()
                    print(f"✓ {package}: {version}")
                    break
        else:
            print(f"✗ {package}: NOT INSTALLED")
            issues.append(f"Missing package: {package}")
    
    # Check if setup.py exists
    if os.path.exists("setup.py"):
        print("✓ setup.py exists")
    else:
        print("✗ setup.py missing")
        issues.append("setup.py is missing")
    
    # Check if conftest.py exists
    if os.path.exists("conftest.py"):
        print("✓ conftest.py exists")
    else:
        print("✗ conftest.py missing")
        issues.append("conftest.py is missing")
    
    return issues

def check_test_structure():
    """Check if the test structure is correct"""
    print("\n2. Checking Test Structure")
    print("=" * 60)
    
    expected_structure = {
        "tests": {
            "__init__.py": "file",
            "unit": {
                "__init__.py": "file",
                "server": {
                    "__init__.py": "file",
                    "test_device_manager.py": "file",
                    "test_main.py": "file",
                    "test_midi_utils.py": "file",
                    "test_models.py": "file",
                    "test_ui_launcher.py": "file"
                },
                "r2midi_client": {
                    "__init__.py": "file",
                    "test_api_client.py": "file",
                    "test_models.py": "file"
                }
            }
        }
    }
    
    def check_structure(base_path, structure, indent=0):
        """Recursively check directory structure"""
        issues = []
        for name, expected_type in structure.items():
            path = os.path.join(base_path, name)
            indent_str = "  " * indent
            
            if expected_type == "file":
                if os.path.isfile(path):
                    print(f"{indent_str}✓ {name}")
                else:
                    print(f"{indent_str}✗ {name} (missing)")
                    issues.append(f"Missing file: {path}")
            else:  # directory
                if os.path.isdir(path):
                    print(f"{indent_str}✓ {name}/")
                    sub_issues = check_structure(path, expected_type, indent + 1)
                    issues.extend(sub_issues)
                else:
                    print(f"{indent_str}✗ {name}/ (missing)")
                    issues.append(f"Missing directory: {path}")
        
        return issues
    
    return check_structure(".", expected_structure)

def test_imports():
    """Test that all imports work correctly"""
    print("\n3. Testing Imports")
    print("=" * 60)
    
    import_tests = [
        ("server.main", ["app", "is_port_in_use", "find_available_port"]),
        ("server.device_manager", ["DeviceManager"]),
        ("server.midi_utils", ["MidiUtils"]),
        ("server.models", ["Device", "Preset", "PresetRequest", "UIState"]),
        ("server.ui_launcher", ["UILauncher"]),
        ("r2midi_client.api_client", ["CachedApiClient"]),
        ("r2midi_client.models", ["Device", "Preset", "UIState"]),
    ]
    
    issues = []
    
    for module, imports in import_tests:
        try:
            exec(f"from {module} import {', '.join(imports)}")
            print(f"✓ {module}: {', '.join(imports)}")
        except ImportError as e:
            print(f"✗ {module}: {e}")
            issues.append(f"Import error in {module}: {e}")
    
    return issues

def run_pytest_checks():
    """Run various pytest checks"""
    print("\n4. Running Pytest Checks")
    print("=" * 60)
    
    # Test discovery
    print("\n4.1 Test Discovery")
    print("-" * 40)
    code, stdout, stderr = run_command("pytest --collect-only -q")
    
    if code == 0:
        test_count = len([line for line in stdout.split('\n') if line.strip() and '::' in line])
        print(f"✓ Found {test_count} tests")
        
        # Count tests by module
        server_tests = len([line for line in stdout.split('\n') if 'server/test_' in line])
        client_tests = len([line for line in stdout.split('\n') if 'r2midi_client/test_' in line])
        print(f"  - Server tests: {server_tests}")
        print(f"  - Client tests: {client_tests}")
    else:
        print(f"✗ Test discovery failed")
        if stderr:
            print(f"Error: {stderr}")
    
    # Check for import errors
    print("\n4.2 Import Error Check")
    print("-" * 40)
    code, stdout, stderr = run_command("pytest --collect-only -v 2>&1 | grep -E '(ImportError|ModuleNotFoundError)' || echo 'No import errors found'")
    print(stdout.strip())
    
    # Run a sample test
    print("\n4.3 Running Sample Test")
    print("-" * 40)
    code, stdout, stderr = run_command("pytest tests/unit/server/test_models.py::TestModels::test_device_model -v")
    
    if code == 0:
        print("✓ Sample test passed")
    else:
        print("✗ Sample test failed")
        if stderr:
            print(f"Error: {stderr}")
    
    return code == 0

def run_full_test_suite():
    """Run the full test suite"""
    print("\n5. Running Full Test Suite")
    print("=" * 60)
    
    print("\nThis will run all tests. Continue? (y/n): ", end="")
    response = input().strip().lower()
    
    if response != 'y':
        print("Skipping full test suite")
        return True
    
    # Run tests with coverage
    print("\nRunning tests with coverage...")
    code, _, _ = run_command("pytest -v --cov=server --cov=r2midi_client --cov-report=term-missing", capture=False)
    
    return code == 0

def main():
    """Main function"""
    print("R2MIDI Pytest Validation")
    print("========================")
    
    # Change to project directory
    project_dir = "/Users/tirane/Desktop/r2midi"
    if os.path.exists(project_dir):
        os.chdir(project_dir)
    else:
        print(f"Error: Project directory not found: {project_dir}")
        return 1
    
    all_issues = []
    
    # Check prerequisites
    issues = check_prerequisites()
    all_issues.extend(issues)
    
    # Check test structure
    issues = check_test_structure()
    all_issues.extend(issues)
    
    # Test imports
    issues = test_imports()
    all_issues.extend(issues)
    
    # Run pytest checks
    pytest_ok = run_pytest_checks()
    if not pytest_ok:
        all_issues.append("Pytest checks failed")
    
    # Summary
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    
    if all_issues:
        print(f"\n❌ Found {len(all_issues)} issues:\n")
        for issue in all_issues:
            print(f"  • {issue}")
        
        print("\n📝 Recommendations:")
        print("1. Install missing packages: pip install -e .[test]")
        print("2. Create missing files/directories")
        print("3. Fix import errors in test files")
        print("4. Run: python apply_fixes.sh")
    else:
        print("\n✅ All checks passed! Tests are properly configured.")
        
        # Optionally run full test suite
        run_full_test_suite()
    
    return 0 if not all_issues else 1

if __name__ == "__main__":
    sys.exit(main())
