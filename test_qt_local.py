#!/usr/bin/env python3
"""
Quick local test to verify Qt testing setup works
Run this before pushing to CI to validate Qt test functionality
"""

import os
import platform
import subprocess
import sys


def check_ubuntu_version():
    """Check Ubuntu version and warn about package differences"""
    if platform.system() == "Linux":
        try:
            with open("/etc/os-release", "r") as f:
                content = f.read()
                if "Ubuntu" in content:
                    if "24.04" in content:
                        print("✅ Ubuntu 24.04 detected (same as CI)")
                    elif "22.04" in content or "20.04" in content:
                        print(
                            "⚠️  Older Ubuntu detected - CI uses 24.04 with different packages"
                        )
                        print(
                            "💡 If Qt issues occur, try: sudo apt install libgl1-mesa-dri"
                        )
                    else:
                        print("ℹ️  Ubuntu version detection inconclusive")
        except:
            print("ℹ️  Could not detect Ubuntu version")


def main():
    """Run Qt test locally to verify setup"""
    print("🧪 Testing Qt setup locally...")

    check_ubuntu_version()

    # Set Qt platform for headless testing (similar to CI)
    os.environ["QT_QPA_PLATFORM"] = "offscreen"

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
        result = subprocess.run(
            [sys.executable, "-m", "pytest", "tests/temp/test_qtbot.py", "-v", "-s"],
            capture_output=True,
            text=True,
        )

        print("📋 Test output:")
        print(result.stdout)
        if result.stderr:
            print("⚠️ Test stderr:")
            print(result.stderr)

        if result.returncode == 0:
            print("✅ Qt test passed! Ready for CI")
            print("🚀 Your next CI run should succeed")
            return True
        else:
            print("❌ Qt test failed")
            print("💡 Check system dependencies and try:")
            if platform.system() == "Linux":
                print("   sudo apt update")
                print("   sudo apt install libegl1-mesa-dev libgl1-mesa-dri libxcb-*")
            return False

    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 Try installing: pip install PyQt6 pytest-qt")
        if platform.system() == "Linux":
            print("💡 System deps: sudo apt install libegl1-mesa-dev libgl1-mesa-dri")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
