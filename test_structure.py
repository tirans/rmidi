#!/usr/bin/env python3
"""
Test script to verify the restructured project works
"""
import sys
import os

# Add the project root to the Python path
project_root = os.path.dirname(__file__)
sys.path.insert(0, project_root)

def test_imports():
    """Test that all modules can be imported correctly"""
    try:
        print("Testing server imports...")
        from server.main import main
        print("✓ server.main imported successfully")
        
        from server.device_manager import DeviceManager
        print("✓ server.device_manager imported successfully")
        
        from server.midi_utils import MidiUtils
        print("✓ server.midi_utils imported successfully")
        
        from server.models import Device, Preset
        print("✓ server.models imported successfully")
        
        print("\nTesting client imports...")
        from r2midi_client.main import main as client_main
        print("✓ r2midi_client.main imported successfully")
        
        print("\nAll imports successful! ✓")
        return True
        
    except ImportError as e:
        print(f"✗ Import error: {e}")
        return False
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return False

def test_directory_structure():
    """Test that the directory structure is correct"""
    expected_structure = {
        'server': ['main.py', 'device_manager.py', 'midi_utils.py', 'models.py', '__init__.py'],
        'r2midi_client': ['main.py', '__init__.py'],
        'build': [],
        '.': ['pyproject.toml', 'README.md', 'LICENSE']
    }
    
    print("Testing directory structure...")
    all_good = True
    
    for directory, expected_files in expected_structure.items():
        dir_path = directory if directory != '.' else project_root
        actual_path = os.path.join(project_root, dir_path) if directory != '.' else project_root
        
        if not os.path.exists(actual_path):
            print(f"✗ Directory {directory} does not exist")
            all_good = False
            continue
            
        for file in expected_files:
            file_path = os.path.join(actual_path, file)
            if os.path.exists(file_path):
                print(f"✓ {directory}/{file} exists")
            else:
                print(f"✗ {directory}/{file} missing")
                all_good = False
    
    return all_good

if __name__ == '__main__':
    print("R2MIDI Project Structure Test")
    print("=" * 40)
    
    structure_ok = test_directory_structure()
    print()
    imports_ok = test_imports()
    
    print("\n" + "=" * 40)
    if structure_ok and imports_ok:
        print("✓ All tests passed! Project structure is correct.")
        sys.exit(0)
    else:
        print("✗ Some tests failed. Please check the project structure.")
        sys.exit(1)
