#!/usr/bin/env python3

"""
Test import validation script
This script validates that all the test imports work correctly after refactoring.
"""

import sys
import os

# Add the project root to Python path
project_root = '/Users/tirane/Desktop/r2midi'
sys.path.insert(0, project_root)

def test_server_imports():
    """Test that all server imports work correctly"""
    try:
        print("Testing server imports...")
        
        # Test server.models
        from server.models import Device, Preset, PresetRequest, UIState
        print("✅ server.models imports work")
        
        # Test server.device_manager
        from server.device_manager import DeviceManager
        print("✅ server.device_manager imports work")
        
        # Test server.main
        from server.main import app, is_port_in_use, find_available_port
        print("✅ server.main imports work")
        
        # Test server.midi_utils
        from server.midi_utils import MidiUtils
        print("✅ server.midi_utils imports work")
        
        # Test server.ui_launcher
        from server.ui_launcher import UILauncher
        print("✅ server.ui_launcher imports work")
        
        return True
        
    except Exception as e:
        print(f"❌ Server import failed: {e}")
        return False

def test_client_imports():
    """Test that all client imports work correctly"""
    try:
        print("\nTesting client imports...")
        
        # Test r2midi_client.models
        from r2midi_client.models import Device, Preset, UIState
        print("✅ r2midi_client.models imports work")
        
        # Test r2midi_client.api_client
        from r2midi_client.api_client import CachedApiClient
        print("✅ r2midi_client.api_client imports work")
        
        return True
        
    except Exception as e:
        print(f"❌ Client import failed: {e}")
        return False

def main():
    """Main test function"""
    print("🧪 Running import validation tests...\n")
    
    server_ok = test_server_imports()
    client_ok = test_client_imports()
    
    print(f"\n{'='*50}")
    if server_ok and client_ok:
        print("🎉 All imports are working correctly!")
        print("✅ Test refactoring was successful!")
        return 0
    else:
        print("❌ Some imports are still broken")
        return 1

if __name__ == "__main__":
    sys.exit(main())
