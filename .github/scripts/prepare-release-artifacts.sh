#!/bin/bash
set -euo pipefail

# Prepare and organize all release artifacts for GitHub Release
# Usage: prepare-release-artifacts.sh <version>

VERSION="${1:-unknown}"

echo "📦 Preparing release artifacts for R2MIDI v$VERSION..."

# Create release directory structure
mkdir -p release_files/{macos,windows,linux,python,checksums}

# Function to calculate and store checksums
calculate_checksums() {
    local file="$1"
    local name=$(basename "$file")
    
    if [ -f "$file" ]; then
        echo "🔒 Calculating checksums for $name..."
        
        # Calculate multiple hash types
        local sha256=$(shasum -a 256 "$file" | cut -d' ' -f1)
        local sha1=$(shasum -a 1 "$file" | cut -d' ' -f1)
        local md5=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1 || md5 "$file" | cut -d' ' -f4)
        
        # Store in checksums file
        cat >> release_files/checksums/CHECKSUMS.txt << EOF
$name:
  SHA256: $sha256
  SHA1:   $sha1
  MD5:    $md5

EOF
        
        # Also create individual checksum files
        echo "$sha256  $name" >> "release_files/checksums/${name}.sha256"
        echo "$sha1  $name" >> "release_files/checksums/${name}.sha1"
        echo "$md5  $name" >> "release_files/checksums/${name}.md5"
        
        echo "✅ Checksums calculated for $name"
    fi
}

# Function to organize macOS artifacts
organize_macos_artifacts() {
    echo "🍎 Organizing macOS artifacts..."
    
    local found_files=0
    
    # Look for macOS DMG and PKG files
    find release_files -name "*.dmg" -o -name "*.pkg" | while read file; do
        if [ -f "$file" ]; then
            local basename_file=$(basename "$file")
            
            # Move to macOS directory if not already there
            if [[ "$file" != release_files/macos/* ]]; then
                mv "$file" "release_files/macos/"
                echo "📁 Moved $basename_file to macOS directory"
            fi
            
            calculate_checksums "release_files/macos/$basename_file"
            found_files=$((found_files + 1))
        fi
    done
    
    if [ $found_files -eq 0 ]; then
        echo "⚠️ Warning: No macOS artifacts found"
    else
        echo "✅ Organized $found_files macOS artifacts"
    fi
}

# Function to organize Windows artifacts
organize_windows_artifacts() {
    echo "🪟 Organizing Windows artifacts..."
    
    local found_files=0
    
    # Look for Windows ZIP and MSI files
    find release_files -name "*Windows*.zip" -o -name "*.msi" | while read file; do
        if [ -f "$file" ]; then
            local basename_file=$(basename "$file")
            
            # Move to Windows directory if not already there
            if [[ "$file" != release_files/windows/* ]]; then
                mv "$file" "release_files/windows/"
                echo "📁 Moved $basename_file to Windows directory"
            fi
            
            calculate_checksums "release_files/windows/$basename_file"
            found_files=$((found_files + 1))
        fi
    done
    
    if [ $found_files -eq 0 ]; then
        echo "⚠️ Warning: No Windows artifacts found"
    else
        echo "✅ Organized $found_files Windows artifacts"
    fi
}

# Function to organize Linux artifacts
organize_linux_artifacts() {
    echo "🐧 Organizing Linux artifacts..."
    
    local found_files=0
    
    # Look for Linux TAR.GZ, DEB, and AppImage files
    find release_files -name "*Linux*.tar.gz" -o -name "*.deb" -o -name "*.AppImage" | while read file; do
        if [ -f "$file" ]; then
            local basename_file=$(basename "$file")
            
            # Move to Linux directory if not already there
            if [[ "$file" != release_files/linux/* ]]; then
                mv "$file" "release_files/linux/"
                echo "📁 Moved $basename_file to Linux directory"
            fi
            
            calculate_checksums "release_files/linux/$basename_file"
            found_files=$((found_files + 1))
        fi
    done
    
    if [ $found_files -eq 0 ]; then
        echo "⚠️ Warning: No Linux artifacts found"
    else
        echo "✅ Organized $found_files Linux artifacts"
    fi
}

# Function to organize Python package artifacts
organize_python_artifacts() {
    echo "🐍 Organizing Python package artifacts..."
    
    local found_files=0
    
    # Look for Python wheel and source distribution files
    find release_files -name "*.whl" -o -name "*.tar.gz" | grep -v Linux | while read file; do
        if [ -f "$file" ]; then
            local basename_file=$(basename "$file")
            
            # Check if it's a Python package (not a Linux tarball)
            if [[ "$basename_file" =~ ^r2midi-.*\.(whl|tar\.gz)$ ]]; then
                # Move to Python directory if not already there
                if [[ "$file" != release_files/python/* ]]; then
                    mv "$file" "release_files/python/"
                    echo "📁 Moved $basename_file to Python directory"
                fi
                
                calculate_checksums "release_files/python/$basename_file"
                found_files=$((found_files + 1))
            fi
        fi
    done
    
    if [ $found_files -eq 0 ]; then
        echo "⚠️ Warning: No Python package artifacts found"
    else
        echo "✅ Organized $found_files Python package artifacts"
    fi
}

# Function to create installation guides
create_installation_guides() {
    echo "📝 Creating installation guides..."
    
    # macOS Installation Guide
    cat > release_files/macos/INSTALL_MACOS.md << EOF
# R2MIDI v$VERSION - macOS Installation

## Download Options

### DMG Installer (Recommended)
- Download the \`.dmg\` file
- Double-click to mount the disk image
- Drag the applications to your Applications folder
- Eject the disk image when done

### PKG Installer
- Download the \`.pkg\` file
- Double-click to run the installer
- Follow the installation wizard
- Applications will be installed to /Applications

## System Requirements
- macOS 11.0 (Big Sur) or later
- Apple Silicon (M1/M2) or Intel processor
- 100MB of available disk space

## Security Notice
All macOS applications are:
- ✅ Signed with Apple Developer ID
- ✅ Notarized by Apple
- ✅ Compatible with Gatekeeper

You should not see any security warnings when running these applications.

## Running the Applications
1. Start "R2MIDI Server" first
2. Then start "R2MIDI Client"
3. The client will automatically connect to the local server

## Troubleshooting
If you encounter any issues:
1. Check that both applications are in /Applications
2. Try restarting both applications
3. Check Console.app for error messages
4. Visit: https://github.com/tirans/r2midi/issues
EOF

    # Windows Installation Guide
    cat > release_files/windows/INSTALL_WINDOWS.md << EOF
# R2MIDI v$VERSION - Windows Installation

## Download Options

### ZIP Packages (Recommended)
- Download the appropriate ZIP file for your needs:
  - \`R2MIDI-Server-$VERSION-Windows.zip\` - Server only
  - \`R2MIDI-Client-$VERSION-Windows.zip\` - Client only  
  - \`R2MIDI-Complete-$VERSION-Windows.zip\` - Both applications
- Extract to your desired location
- No installation required - portable applications

### MSI Installer (If Available)
- Download the \`.msi\` file
- Double-click to run the installer
- Follow the installation wizard

## System Requirements
- Windows 10 or later (64-bit)
- 100MB of available disk space
- No administrator privileges required for portable installation

## Security Notice
⚠️ **Important**: These applications are unsigned
- Windows may show security warnings
- Click "More info" then "Run anyway" if prompted
- These warnings are normal for open-source applications

## Running the Applications
1. Extract the ZIP file(s) to a folder of your choice
2. Start the server application first
3. Then start the client application
4. The client will connect to the local server automatically

## Troubleshooting
If you encounter any issues:
1. Ensure Windows Defender isn't blocking the applications
2. Try running as administrator if needed
3. Check Windows Event Viewer for error messages
4. Visit: https://github.com/tirans/r2midi/issues
EOF

    # Linux Installation Guide
    cat > release_files/linux/INSTALL_LINUX.md << EOF
# R2MIDI v$VERSION - Linux Installation

## Download Options

### TAR.GZ Packages (Universal)
- Download the appropriate TAR.GZ file:
  - \`R2MIDI-Server-$VERSION-Linux.tar.gz\` - Server only
  - \`R2MIDI-Client-$VERSION-Linux.tar.gz\` - Client only
  - \`R2MIDI-Complete-$VERSION-Linux.tar.gz\` - Both applications
- Extract and run - no installation required

### DEB Packages (Debian/Ubuntu)
- Download the \`.deb\` file
- Install with: \`sudo dpkg -i filename.deb\`
- Or double-click in file manager

### AppImage (Universal)
- Download the \`.AppImage\` file
- Make executable: \`chmod +x filename.AppImage\`
- Run directly: \`./filename.AppImage\`

## System Requirements
- Linux (64-bit)
- ALSA or PulseAudio for MIDI support
- Qt6 libraries (for GUI client)
- 100MB of available disk space

## Dependencies
Install required system packages:

### Ubuntu/Debian
\`\`\`bash
sudo apt update
sudo apt install libasound2 portaudio19-dev qt6-base-dev
\`\`\`

### Fedora/RHEL
\`\`\`bash
sudo dnf install alsa-lib portaudio qt6-qtbase
\`\`\`

### Arch Linux
\`\`\`bash
sudo pacman -S alsa-lib portaudio qt6-base
\`\`\`

## Installation Instructions

### TAR.GZ Method
\`\`\`bash
# Extract the archive
tar -xzf R2MIDI-Complete-$VERSION-Linux.tar.gz

# Navigate to the directory
cd R2MIDI-Complete-$VERSION

# Run the applications
./start-server.sh    # Start server
./start-client.sh    # Start client (in another terminal)
\`\`\`

### AppImage Method
\`\`\`bash
# Make executable
chmod +x R2MIDI-Client-$VERSION.AppImage

# Run
./R2MIDI-Client-$VERSION.AppImage
\`\`\`

## Troubleshooting
If you encounter any issues:
1. Verify all dependencies are installed
2. Check ALSA/PulseAudio configuration
3. Try running from terminal to see error messages
4. Visit: https://github.com/tirans/r2midi/issues
EOF

    # Python Package Installation Guide
    cat > release_files/python/INSTALL_PYTHON.md << EOF
# R2MIDI v$VERSION - Python Package Installation

## Installation from PyPI (Recommended)

\`\`\`bash
# Install the latest version
pip install r2midi

# Install specific version
pip install r2midi==$VERSION

# Install with development dependencies
pip install r2midi[dev]
\`\`\`

## Installation from Downloaded Files

\`\`\`bash
# Install from wheel (recommended)
pip install r2midi-$VERSION-py3-none-any.whl

# Install from source distribution
pip install r2midi-$VERSION.tar.gz
\`\`\`

## System Requirements
- Python 3.9 or later
- pip (Python package installer)
- Platform-specific dependencies (see platform guides)

## Usage

### Server
\`\`\`bash
# Start the server
python -m server.main

# Or use the entry point (if configured)
r2midi-server
\`\`\`

### Client
\`\`\`bash
# Start the client
python -m r2midi_client.main

# Or use the entry point (if configured)
r2midi-client
\`\`\`

## Development Installation

\`\`\`bash
# Clone the repository
git clone https://github.com/tirans/r2midi.git
cd r2midi

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/macOS
venv\\Scripts\\activate    # Windows

# Install in development mode
pip install -e .
\`\`\`

## Troubleshooting
If you encounter any issues:
1. Ensure Python 3.9+ is installed
2. Update pip: \`pip install --upgrade pip\`
3. Install platform-specific dependencies
4. Visit: https://github.com/tirans/r2midi/issues
EOF

    echo "✅ Created installation guides for all platforms"
}

# Function to create release verification script
create_verification_script() {
    echo "🔍 Creating release verification script..."
    
    cat > release_files/verify_release.sh << 'EOF'
#!/bin/bash
# Release Verification Script for R2MIDI

echo "🔍 Verifying R2MIDI release artifacts..."

# Function to verify checksum
verify_checksum() {
    local file="$1"
    local expected_sha256="$2"
    
    if [ ! -f "$file" ]; then
        echo "❌ File not found: $file"
        return 1
    fi
    
    local actual_sha256
    if command -v sha256sum >/dev/null 2>&1; then
        actual_sha256=$(sha256sum "$file" | cut -d' ' -f1)
    elif command -v shasum >/dev/null 2>&1; then
        actual_sha256=$(shasum -a 256 "$file" | cut -d' ' -f1)
    else
        echo "⚠️ Warning: No SHA256 utility found"
        return 1
    fi
    
    if [ "$actual_sha256" = "$expected_sha256" ]; then
        echo "✅ Checksum verified: $(basename "$file")"
        return 0
    else
        echo "❌ Checksum mismatch: $(basename "$file")"
        echo "   Expected: $expected_sha256"
        echo "   Actual:   $actual_sha256"
        return 1
    fi
}

# Verify checksums for all artifacts
if [ -f "checksums/CHECKSUMS.txt" ]; then
    echo "📋 Verifying checksums against CHECKSUMS.txt..."
    
    # Parse checksums file and verify each file
    grep -E "^[^:]+:" checksums/CHECKSUMS.txt | cut -d':' -f1 | while read filename; do
        expected_sha256=$(grep -A3 "^$filename:" checksums/CHECKSUMS.txt | grep "SHA256:" | awk '{print $2}')
        
        # Find the file in subdirectories
        file_path=$(find . -name "$filename" -type f | head -1)
        
        if [ -n "$file_path" ] && [ -n "$expected_sha256" ]; then
            verify_checksum "$file_path" "$expected_sha256"
        fi
    done
else
    echo "⚠️ Warning: checksums/CHECKSUMS.txt not found"
fi

echo ""
echo "✅ Release verification complete!"
EOF

    chmod +x release_files/verify_release.sh
    echo "✅ Created release verification script"
}

# Function to create comprehensive release notes
create_release_notes() {
    echo "📝 Creating comprehensive release notes..."
    
    cat > release_files/RELEASE_NOTES.md << EOF
# R2MIDI v$VERSION Release Notes

## 📦 Available Downloads

### 🍎 macOS (Signed & Notarized)
- **DMG Installers**: Drag-and-drop installation
- **PKG Installers**: Automated installation with system integration
- **Security**: All applications are signed and notarized by Apple

### 🪟 Windows (Unsigned)
- **ZIP Packages**: Portable applications, no installation required
- **MSI Installers**: Traditional Windows installer packages (if available)
- **Note**: Applications are unsigned, security warnings are normal

### 🐧 Linux (Unsigned)
- **TAR.GZ Archives**: Universal Linux packages
- **DEB Packages**: Debian/Ubuntu installation packages
- **AppImage**: Universal Linux applications (if available)

### 🐍 Python Package
- **PyPI**: Available via \`pip install r2midi\`
- **Wheel**: Universal Python wheel for all platforms
- **Source**: Source distribution for custom builds

## 🔧 Installation

See the platform-specific installation guides:
- [macOS Installation Guide](macos/INSTALL_MACOS.md)
- [Windows Installation Guide](windows/INSTALL_WINDOWS.md)
- [Linux Installation Guide](linux/INSTALL_LINUX.md)
- [Python Package Guide](python/INSTALL_PYTHON.md)

## 🔒 Security & Verification

### Checksums
All release artifacts include SHA256, SHA1, and MD5 checksums for verification.
Use the provided \`verify_release.sh\` script to verify artifact integrity.

### Code Signing Status
- **macOS**: ✅ Signed with Apple Developer ID, notarized by Apple
- **Windows**: ❌ Unsigned (open-source project limitation)
- **Linux**: ❌ Unsigned (standard for most Linux software)

## 📋 System Requirements

### Minimum Requirements
- **Python**: 3.9 or later
- **Memory**: 512MB RAM
- **Storage**: 100MB available space
- **Network**: Required for server-client communication

### Platform-Specific
- **macOS**: 11.0 (Big Sur) or later
- **Windows**: Windows 10 or later (64-bit)
- **Linux**: Most modern distributions with Qt6 support

## 🚀 What's New in v$VERSION

See [CHANGELOG.md](https://github.com/tirans/r2midi/blob/master/CHANGELOG.md) for detailed changes.

## 🔗 Links
- **GitHub Repository**: https://github.com/tirans/r2midi
- **PyPI Package**: https://pypi.org/project/r2midi/
- **Documentation**: https://github.com/tirans/r2midi/wiki
- **Issues & Support**: https://github.com/tirans/r2midi/issues

## 📊 Build Information

- **Build Date**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
- **Build Tools**: Briefcase, Python Build, GitHub Actions
- **CI/CD**: Automated builds with comprehensive testing
- **Quality Assurance**: Code formatting, linting, security scanning

---

*This release was automatically generated by GitHub Actions.*
EOF

    echo "✅ Created comprehensive release notes"
}

# Main workflow
echo "🚀 Starting release artifact preparation..."

# Initialize checksums file
cat > release_files/checksums/CHECKSUMS.txt << EOF
R2MIDI v$VERSION - Release Checksums
====================================

Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

EOF

# Organize artifacts by platform
organize_macos_artifacts
organize_windows_artifacts  
organize_linux_artifacts
organize_python_artifacts

# Create documentation and guides
create_installation_guides
create_verification_script
create_release_notes

# Generate final release summary
echo "📋 Generating release summary..."

cat > release_files/RELEASE_SUMMARY.txt << EOF
R2MIDI v$VERSION Release Summary
===============================

Release Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Release Manager: GitHub Actions (Automated)

Artifacts Summary:
EOF

# Count artifacts by platform
for platform in macos windows linux python; do
    if [ -d "release_files/$platform" ]; then
        count=$(find "release_files/$platform" -type f -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" -o -name "*.msi" -o -name "*.tar.gz" -o -name "*.deb" -o -name "*.AppImage" -o -name "*.whl" | wc -l)
        echo "  - $platform: $count artifacts" >> release_files/RELEASE_SUMMARY.txt
    fi
done

cat >> release_files/RELEASE_SUMMARY.txt << EOF

Total Release Size: $(du -sh release_files/ | cut -f1)

Quality Assurance:
  ✅ All artifacts checksummed (SHA256, SHA1, MD5)
  ✅ Installation guides provided for all platforms
  ✅ Release verification script included
  ✅ Comprehensive documentation included

Next Steps:
  1. Review all artifacts in release_files/
  2. Test installation on target platforms
  3. Upload to GitHub Releases
  4. Announce release to community
EOF

echo ""
echo "✅ Release artifact preparation complete!"
echo ""
echo "📁 Release structure:"
find release_files -type f | sort

echo ""
echo "📋 Release summary:"
cat release_files/RELEASE_SUMMARY.txt

echo ""
echo "🎯 Release artifacts are ready for distribution!"
echo "   Location: $(pwd)/release_files/"