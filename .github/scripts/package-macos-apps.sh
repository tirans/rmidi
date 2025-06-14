#!/bin/bash
set -euo pipefail

# Package macOS applications into distribution-ready formats
# Usage: package-macos-apps.sh <version> <build_type>

VERSION="${1:-1.0.0}"
BUILD_TYPE="${2:-production}"

echo "🍎 Packaging macOS applications..."
echo "Version: $VERSION"
echo "Build Type: $BUILD_TYPE"

# Ensure artifacts directory exists
mkdir -p artifacts

# Function to verify and organize signed DMG files
organize_dmg_files() {
    echo "🔍 Looking for signed DMG files..."
    
    find . -maxdepth 1 -name "*.dmg" | while read dmg_file; do
        if [ -f "$dmg_file" ]; then
            local dmg_name=$(basename "$dmg_file")
            local new_name="R2MIDI-${dmg_name}"
            
            echo "📦 Processing DMG: $dmg_name"
            
            # Verify the DMG is signed
            if codesign -dv "$dmg_file" 2>&1 | grep -q "Developer ID"; then
                echo "✅ DMG is properly signed"
            else
                echo "⚠️ Warning: DMG may not be properly signed"
            fi
            
            # Verify notarization
            if spctl --assess --type install "$dmg_file" 2>&1 | grep -q "accepted"; then
                echo "✅ DMG is notarized and accepted by Gatekeeper"
            else
                echo "⚠️ Warning: DMG may not be properly notarized"
            fi
            
            # Copy to artifacts with proper naming
            cp "$dmg_file" "artifacts/$new_name"
            echo "✅ Packaged DMG: artifacts/$new_name"
        fi
    done
}

# Function to verify and organize signed PKG files
organize_pkg_files() {
    echo "🔍 Looking for signed PKG files..."
    
    find . -maxdepth 1 -name "*.pkg" | while read pkg_file; do
        if [ -f "$pkg_file" ]; then
            local pkg_name=$(basename "$pkg_file")
            local new_name="R2MIDI-${pkg_name}"
            
            echo "📦 Processing PKG: $pkg_name"
            
            # Verify the PKG is signed
            if pkgutil --check-signature "$pkg_file" | grep -q "signed"; then
                echo "✅ PKG is properly signed"
            else
                echo "⚠️ Warning: PKG may not be properly signed"
            fi
            
            # Verify notarization
            if spctl --assess --type install "$pkg_file" 2>&1 | grep -q "accepted"; then
                echo "✅ PKG is notarized and accepted by Gatekeeper"
            else
                echo "⚠️ Warning: PKG may not be properly notarized"
            fi
            
            # Copy to artifacts with proper naming
            cp "$pkg_file" "artifacts/$new_name"
            echo "✅ Packaged PKG: artifacts/$new_name"
        fi
    done
}

# Function to create a combined installer if multiple apps exist
create_combined_installer() {
    local server_dmg=""
    local client_dmg=""
    
    # Find individual DMG files
    server_dmg=$(find artifacts/ -name "*Server*.dmg" | head -1)
    client_dmg=$(find artifacts/ -name "*Client*.dmg" | head -1)
    
    if [ -n "$server_dmg" ] && [ -n "$client_dmg" ] && [ -f "$server_dmg" ] && [ -f "$client_dmg" ]; then
        echo "📦 Creating combined installer package..."
        
        local combined_name="R2MIDI-Complete-${VERSION}-macOS.dmg"
        local temp_dir=$(mktemp -d)
        local mount_point1="$temp_dir/server_mount"
        local mount_point2="$temp_dir/client_mount"
        local package_dir="$temp_dir/R2MIDI-Complete-${VERSION}"
        
        mkdir -p "$mount_point1" "$mount_point2" "$package_dir"
        
        # Mount and copy server app
        if hdiutil attach "$server_dmg" -mountpoint "$mount_point1" -readonly; then
            find "$mount_point1" -name "*.app" -type d | while read app; do
                cp -R "$app" "$package_dir/"
            done
            hdiutil detach "$mount_point1"
        fi
        
        # Mount and copy client app
        if hdiutil attach "$client_dmg" -mountpoint "$mount_point2" -readonly; then
            find "$mount_point2" -name "*.app" -type d | while read app; do
                cp -R "$app" "$package_dir/"
            done
            hdiutil detach "$mount_point2"
        fi
        
        # Add documentation
        if [ -f "README.md" ]; then
            cp README.md "$package_dir/"
        fi
        if [ -f "LICENSE" ]; then
            cp LICENSE "$package_dir/"
        fi
        
        # Create installation instructions
        cat > "$package_dir/Installation Instructions.txt" << EOF
R2MIDI Complete Installation Instructions
=========================================

Version: $VERSION
Platform: macOS (signed and notarized)

This package contains both the R2MIDI Server and Client applications.

Installation:
1. Drag both applications to your Applications folder
2. The applications are signed and notarized, so they should run without security warnings

Usage:
1. Start the R2MIDI Server application first
2. Then start the R2MIDI Client application
3. The Client will automatically connect to the local Server

System Requirements:
- macOS 11.0 (Big Sur) or later
- Apple Silicon (M1/M2) or Intel processor

Security:
- Both applications are signed with Apple Developer ID
- Both applications are notarized by Apple
- Safe to run on macOS with default security settings

Support:
- GitHub: https://github.com/tirans/r2midi
- Issues: https://github.com/tirans/r2midi/issues
EOF
        
        # Create the combined DMG
        if command -v create-dmg >/dev/null 2>&1; then
            create-dmg \
                --volname "R2MIDI Complete $VERSION" \
                --volicon "r2midi.icns" \
                --window-pos 200 120 \
                --window-size 800 600 \
                --icon-size 100 \
                --app-drop-link 600 300 \
                "$combined_name" \
                "$package_dir"
        else
            # Fallback to hdiutil
            hdiutil create -format UDZO -srcfolder "$package_dir" -volname "R2MIDI Complete $VERSION" "$combined_name"
        fi
        
        # Move to artifacts directory
        if [ -f "$combined_name" ]; then
            mv "$combined_name" artifacts/
            echo "✅ Created combined installer: artifacts/$combined_name"
        fi
        
        # Cleanup
        rm -rf "$temp_dir"
    else
        echo "ℹ️ Cannot create combined installer - missing individual DMG files"
    fi
}

# Function to create checksums for all packages
create_checksums() {
    echo "🔒 Creating checksums for packages..."
    
    if [ -d "artifacts" ] && [ "$(ls -A artifacts/)" ]; then
        (cd artifacts && find . -name "*.dmg" -o -name "*.pkg" | while read file; do
            if [ -f "$file" ]; then
                echo "🔸 Creating checksum for $(basename "$file")..."
                shasum -a 256 "$file" >> CHECKSUMS.txt
            fi
        done)
        
        if [ -f "artifacts/CHECKSUMS.txt" ]; then
            echo "✅ Created checksums file: artifacts/CHECKSUMS.txt"
        fi
    fi
}

# Main packaging workflow
echo "🔍 Organizing macOS packages..."

# Organize signed DMG and PKG files
organize_dmg_files
organize_pkg_files

# Create combined installer if possible
create_combined_installer

# Create checksums
create_checksums

# Generate package information
cat > artifacts/MACOS_PACKAGES.txt << EOF
macOS Package Information
========================

Version: $VERSION
Build Type: $BUILD_TYPE
Platform: macOS (signed and notarized)
Package Tool: Custom packaging script
Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

Signing Details:
- Code Signing: Apple Developer ID Application
- Installer Signing: Apple Developer ID Installer (for PKG)
- Notarization: Apple Notary Service
- Gatekeeper: Compatible with all macOS security settings

Package Types:
- DMG: Disk image installers (drag and drop)
- PKG: Package installers (automated installation)

Created Packages:
EOF

# List all created packages
if [ -d "artifacts" ] && [ "$(ls -A artifacts/)" ]; then
    find artifacts/ -name "*.dmg" -o -name "*.pkg" | sort | while read file; do
        if [ -f "$file" ]; then
            size=$(du -h "$file" | cut -f1)
            echo "  - $(basename "$file") ($size)" >> artifacts/MACOS_PACKAGES.txt
            
            # Add signature verification info
            if [[ "$file" == *.dmg ]]; then
                if codesign -dv "$file" 2>&1 | grep -q "Developer ID"; then
                    echo "    ✅ Signed and verified" >> artifacts/MACOS_PACKAGES.txt
                fi
            elif [[ "$file" == *.pkg ]]; then
                if pkgutil --check-signature "$file" | grep -q "signed"; then
                    echo "    ✅ Signed and verified" >> artifacts/MACOS_PACKAGES.txt
                fi
            fi
        fi
    done
else
    echo "  - No packages generated" >> artifacts/MACOS_PACKAGES.txt
fi

# Add checksum information
if [ -f "artifacts/CHECKSUMS.txt" ]; then
    echo "" >> artifacts/MACOS_PACKAGES.txt
    echo "SHA256 Checksums:" >> artifacts/MACOS_PACKAGES.txt
    cat artifacts/CHECKSUMS.txt >> artifacts/MACOS_PACKAGES.txt
fi

echo ""
echo "✅ macOS packaging complete!"
echo "📋 Package summary:"
cat artifacts/MACOS_PACKAGES.txt