#!/usr/bin/env python3
"""
Quick local test to verify Qt testing setup works
Run this before pushing to CI to validate Qt test functionality
"""

import os
import sys
import subprocess

def main():
    """Run Qt test locally to verify setup"""
    print("🧪 Testing Qt setup locally...")
    
    # Set Qt platform for headless testing (similar to CI)
    os.environ['QT_QPA_PLATFORM'] = 'offscreen'
    
    try:
        # Test PyQt6 import
        print("📦 Testing PyQt6 import...")
        from PyQt6.QtWidgets import QApplication, QPushButton
        print("✅ PyQt6 import successful")
        
        # Test pytest-qt
        print("🔧 Testing pytest-qt installation...")
        import pytestqt
        print("✅ pytest-qt import successful")
        
        # Run the specific Qt test
        print("🚀 Running Qt test...")
        result = subprocess.run([
            sys.executable, "-m", "pytest", 
            "tests/temp/test_qtbot.py", "-v"
        ], capture_output=True, text=True)
        
        print("📋 Test output:")
        print(result.stdout)
        if result.stderr:
            print("⚠️ Test stderr:")
            print(result.stderr)
            
        if result.returncode == 0:
            print("✅ Qt test passed! Ready for CI")
            return True
        else:
            print("❌ Qt test failed")
            return False
            
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 Try installing: pip install PyQt6 pytest-qt")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
