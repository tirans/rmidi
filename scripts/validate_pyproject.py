#!/usr/bin/env python3
"""
Script to validate pyproject.toml for Briefcase builds.
Checks that all required sections and fields are present.
"""

import sys
import re
from pathlib import Path

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("❌ tomllib/tomli not available. Install with: pip install tomli")
        sys.exit(1)


def validate_pyproject():
    """Validate pyproject.toml for Briefcase configuration."""
    
    pyproject_path = Path("pyproject.toml")
    if not pyproject_path.exists():
        print(f"❌ pyproject.toml not found at {pyproject_path.absolute()}")
        return False
    
    print(f"🔍 Validating {pyproject_path}...")
    
    try:
        with open(pyproject_path, "rb") as f:
            config = tomllib.load(f)
    except Exception as e:
        print(f"❌ Failed to parse pyproject.toml: {e}")
        return False
    
    # Check basic project info
    project = config.get("project", {})
    if not project:
        print("❌ Missing [project] section")
        return False
    
    required_project_fields = ["name", "version", "description"]
    for field in required_project_fields:
        if field not in project:
            print(f"❌ Missing project.{field}")
            return False
        else:
            print(f"✅ project.{field} = {project[field]}")
    
    # Check Briefcase tool configuration
    tool = config.get("tool", {})
    if not tool:
        print("❌ Missing [tool] section")
        return False
    
    briefcase = tool.get("briefcase", {})
    if not briefcase:
        print("❌ Missing [tool.briefcase] section")
        return False
    
    # Check required briefcase fields
    required_briefcase_fields = ["project_name", "bundle", "version"]
    for field in required_briefcase_fields:
        if field not in briefcase:
            print(f"❌ Missing tool.briefcase.{field}")
            return False
        else:
            print(f"✅ tool.briefcase.{field} = {briefcase[field]}")
    
    # Check app configurations
    apps = briefcase.get("app", {})
    if not apps:
        print("❌ Missing [tool.briefcase.app] section")
        return False
    
    expected_apps = ["server", "r2midi-client"]
    for app_name in expected_apps:
        app_config = apps.get(app_name, {})
        if not app_config:
            print(f"❌ Missing [tool.briefcase.app.{app_name}] section")
            return False
        
        # Check required app fields
        required_app_fields = ["formal_name", "description", "sources", "module_name"]
        for field in required_app_fields:
            if field not in app_config:
                print(f"❌ Missing tool.briefcase.app.{app_name}.{field}")
                return False
            else:
                print(f"✅ tool.briefcase.app.{app_name}.{field} = {app_config[field]}")
        
        # Check macOS specific configuration
        macos_config = app_config.get("macOS", {})
        if macos_config:
            app_config_macos = macos_config.get("app", {})
            if app_config_macos:
                print(f"✅ Found macOS app configuration for {app_name}")
                
                # Check for codesign identity
                if "codesign_identity" in app_config_macos:
                    identity = app_config_macos["codesign_identity"]
                    print(f"✅ tool.briefcase.app.{app_name}.macOS.app.codesign_identity = {identity}")
                else:
                    print(f"⚠️ No codesign_identity found for {app_name} (may be set at runtime)")
                
                # Check icon configuration
                if "icon" in app_config_macos:
                    icon = app_config_macos["icon"]
                    print(f"✅ tool.briefcase.app.{app_name}.macOS.app.icon = {icon}")
                else:
                    print(f"⚠️ No icon specified for {app_name}")
            
            # Check installer configuration (for PKG)
            installer_config = macos_config.get("installer", {})
            if installer_config:
                print(f"✅ Found macOS installer configuration for {app_name}")
                if "codesign_identity" in installer_config:
                    identity = installer_config["codesign_identity"]
                    print(f"✅ tool.briefcase.app.{app_name}.macOS.installer.codesign_identity = {identity}")
        else:
            print(f"⚠️ No macOS configuration found for {app_name}")
    
    print("\n📋 VALIDATION SUMMARY:")
    print("======================")
    print("✅ Basic project configuration is valid")
    print("✅ Briefcase configuration is present")
    print("✅ Both server and client apps are configured")
    
    return True


def check_icon_files():
    """Check if icon files exist."""
    
    print("\n🎨 Checking icon files...")
    print("=========================")
    
    resources_dir = Path("resources")
    if not resources_dir.exists():
        print("❌ resources/ directory not found")
        return False
    
    required_icons = [
        "r2midi.png",
        "icon.png",
        "icon_512x512.png"
    ]
    
    for icon in required_icons:
        icon_path = resources_dir / icon
        if icon_path.exists():
            print(f"✅ Found {icon}")
        else:
            print(f"❌ Missing {icon}")
    
    # List all available icons
    available_icons = list(resources_dir.glob("*.png")) + list(resources_dir.glob("*.ico"))
    if available_icons:
        print(f"\n📋 Available icon files:")
        for icon in sorted(available_icons):
            print(f"  - {icon.name}")
    
    return True


def main():
    """Main validation function."""
    
    print("🔍 R2MIDI pyproject.toml Validator")
    print("===================================")
    
    success = True
    
    # Validate pyproject.toml
    if not validate_pyproject():
        success = False
    
    # Check icon files
    check_icon_files()
    
    if success:
        print("\n🎉 Validation completed successfully!")
        print("Your pyproject.toml is ready for Briefcase builds.")
    else:
        print("\n❌ Validation failed!")
        print("Please fix the issues above before running Briefcase.")
        sys.exit(1)


if __name__ == "__main__":
    main()
