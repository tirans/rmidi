#!/bin/bash
set -euo pipefail

# Package Linux applications into distribution-ready formats
# Usage: package-linux-apps.sh <version> <build_type>

VERSION="${1:-1.0.0}"
BUILD_TYPE="${2:-production}"

echo "🐧 Packaging Linux applications..."
echo "Version: $VERSION"
echo "Build Type: $BUILD_TYPE"

# Ensure artifacts directory exists
mkdir -p artifacts

# Function to create a TAR.GZ package from a directory
create_tarball() {
    local source_dir="$1"
    local app_name="$2"
    local tarball_name="R2MIDI-${app_name}-${VERSION}-Linux.tar.gz"
    
    echo "📦 Creating TAR.GZ package: $tarball_name"
    
    if [ -d "$source_dir" ]; then
        # Create a temporary directory with proper structure
        local temp_dir=$(mktemp -d)
        local package_dir="$temp_dir/R2MIDI-${app_name}-${VERSION}"
        
        mkdir -p "$package_dir"
        cp -r "$source_dir"/* "$package_dir/"
        
        # Add README and license files
        if [ -f "README.md" ]; then
            cp README.md "$package_dir/"
        fi
        if [ -f "LICENSE" ]; then
            cp LICENSE "$package_dir/"
        fi
        
        # Create installation instructions
        cat > "$package_dir/INSTALL.txt" << EOF
R2MIDI ${app_name} Installation Instructions
============================================

Version: $VERSION
Platform: Linux
Package Type: Portable Application

Installation:
1. Extract this archive to your desired location:
   tar -xzf ${tarball_name}
   
2. Navigate to the extracted directory:
   cd R2MIDI-${app_name}-${VERSION}
   
3. Run the application:
   ./$(find . -name "r2midi*" -type f -executable | head -1 | sed 's|^\./||')

System Requirements:
- Linux (64-bit)
- ALSA or PulseAudio for MIDI support
- Qt6 libraries (usually installed by default)

Dependencies (install if needed):
- Ubuntu/Debian: sudo apt install libasound2 portaudio19-dev
- Fedora/RHEL: sudo dnf install alsa-lib portaudio
- Arch: sudo pacman -S alsa-lib portaudio

Support:
- GitHub: https://github.com/tirans/r2midi
- Issues: https://github.com/tirans/r2midi/issues

Note: This is an unsigned application. Some distributions may show warnings.
You can safely ignore these warnings for this open-source application.
EOF
        
        # Create desktop entry if this is a GUI application
        if [[ "$app_name" == *"Client"* ]]; then
            cat > "$package_dir/r2midi-client.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=R2MIDI Client
Comment=MIDI 2.0 Patch Selection Client
Exec=$(pwd)/$package_dir/r2midi-client
Icon=r2midi
Terminal=false
Categories=AudioVideo;Audio;MIDI;
EOF
        fi
        
        # Make executables
        find "$package_dir" -type f -name "*r2midi*" -exec chmod +x {} \;
        find "$package_dir" -type f -name "server" -exec chmod +x {} \;
        
        # Create the tarball
        (cd "$temp_dir" && tar -czf "$tarball_name" "R2MIDI-${app_name}-${VERSION}")
        
        # Move to artifacts directory
        mv "$temp_dir/$tarball_name" artifacts/
        
        # Cleanup
        rm -rf "$temp_dir"
        
        echo "✅ Created TAR.GZ package: artifacts/$tarball_name"
        return 0
    else
        echo "❌ Source directory not found: $source_dir"
        return 1
    fi
}

# Function to find and package DEB files
package_deb_files() {
    echo "🔍 Looking for DEB packages..."
    
    find dist/ -name "*.deb" | while read deb_file; do
        if [ -f "$deb_file" ]; then
            local deb_name=$(basename "$deb_file")
            local new_name=$(echo "$deb_name" | sed "s/\.deb$/-${VERSION}.deb/")
            
            echo "📦 Processing DEB: $deb_name -> $new_name"
            cp "$deb_file" "artifacts/$new_name"
            
            echo "✅ Packaged DEB: artifacts/$new_name"
        fi
    done
}

# Function to find and package AppImage files
package_appimage_files() {
    echo "🔍 Looking for AppImage packages..."
    
    find dist/ -name "*.AppImage" | while read appimage_file; do
        if [ -f "$appimage_file" ]; then
            local appimage_name=$(basename "$appimage_file")
            local new_name=$(echo "$appimage_name" | sed "s/\.AppImage$/-${VERSION}.AppImage/")
            
            echo "📦 Processing AppImage: $appimage_name -> $new_name"
            cp "$appimage_file" "artifacts/$new_name"
            
            # Make sure it's executable
            chmod +x "artifacts/$new_name"
            
            echo "✅ Packaged AppImage: artifacts/$new_name"
        fi
    done
}

# Process different application types
echo "🔍 Looking for built Linux applications..."

# Package Server application
if [ -d "dist/server" ]; then
    echo "📦 Packaging R2MIDI Server..."
    create_tarball "dist/server" "Server"
else
    echo "⚠️ Server application not found in dist/server"
fi

# Package Client application  
if [ -d "dist/r2midi-client" ]; then
    echo "📦 Packaging R2MIDI Client..."
    create_tarball "dist/r2midi-client" "Client"
else
    echo "⚠️ Client application not found in dist/r2midi-client"
fi

# Package any DEB files
package_deb_files

# Package any AppImage files
package_appimage_files

# Create a combined package for convenience
if [ -d "dist/server" ] && [ -d "dist/r2midi-client" ]; then
    echo "📦 Creating combined package..."
    
    local combined_tarball="R2MIDI-Complete-${VERSION}-Linux.tar.gz"
    local temp_dir=$(mktemp -d)
    local package_dir="$temp_dir/R2MIDI-Complete-${VERSION}"
    
    mkdir -p "$package_dir/server"
    mkdir -p "$package_dir/client"
    
    cp -r dist/server/* "$package_dir/server/"
    cp -r dist/r2midi-client/* "$package_dir/client/"
    
    # Add documentation
    if [ -f "README.md" ]; then
        cp README.md "$package_dir/"
    fi
    if [ -f "LICENSE" ]; then
        cp LICENSE "$package_dir/"
    fi
    
    # Create combined installation instructions
    cat > "$package_dir/INSTALL.txt" << EOF
R2MIDI Complete Package Installation Instructions
=================================================

Version: $VERSION
Platform: Linux
Package Type: Complete Portable Applications

This package contains both the R2MIDI Server and Client applications.

Installation:
1. Extract this archive:
   tar -xzf ${combined_tarball}
   
2. Navigate to the extracted directory:
   cd R2MIDI-Complete-${VERSION}

Usage:
1. Start the Server application:
   cd server && ./server
   
2. In another terminal, start the Client:
   cd client && ./r2midi-client

System Requirements:
- Linux (64-bit)
- ALSA or PulseAudio for MIDI support
- Qt6 libraries for the client GUI

Dependencies (install if needed):
- Ubuntu/Debian: sudo apt install libasound2 portaudio19-dev qt6-base-dev
- Fedora/RHEL: sudo dnf install alsa-lib portaudio qt6-qtbase
- Arch: sudo pacman -S alsa-lib portaudio qt6-base

Support:
- GitHub: https://github.com/tirans/r2midi
- Issues: https://github.com/tirans/r2midi/issues

Note: These are unsigned applications. Some distributions may show warnings.
You can safely ignore these warnings for this open-source application.
EOF
    
    # Create startup scripts
    cat > "$package_dir/start-server.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/server"
exec ./server "$@"
EOF
    
    cat > "$package_dir/start-client.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/client"
exec ./r2midi-client "$@"
EOF
    
    # Make scripts executable
    chmod +x "$package_dir/start-server.sh"
    chmod +x "$package_dir/start-client.sh"
    
    # Make application executables
    find "$package_dir" -type f -name "*r2midi*" -exec chmod +x {} \;
    find "$package_dir" -type f -name "server" -exec chmod +x {} \;
    
    # Create the combined tarball
    (cd "$temp_dir" && tar -czf "$combined_tarball" "R2MIDI-Complete-${VERSION}")
    
    # Move to artifacts directory
    mv "$temp_dir/$combined_tarball" artifacts/
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo "✅ Created combined package: artifacts/$combined_tarball"
fi

# Generate package information
cat > artifacts/LINUX_PACKAGES.txt << EOF
Linux Package Information
=========================

Version: $VERSION
Build Type: $BUILD_TYPE
Platform: Linux (unsigned)
Package Tool: Custom packaging script
Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

Package Types:
- TAR.GZ: Portable applications (extract and run)
- DEB: Debian/Ubuntu packages (if available)
- AppImage: Universal Linux applications (if available)

Created Packages:
EOF

# List all created packages
if [ -d "artifacts" ] && [ "$(ls -A artifacts/)" ]; then
    find artifacts/ -name "*.tar.gz" -o -name "*.deb" -o -name "*.AppImage" | sort | while read file; do
        if [ -f "$file" ]; then
            size=$(du -h "$file" | cut -f1)
            echo "  - $(basename "$file") ($size)" >> artifacts/LINUX_PACKAGES.txt
        fi
    done
else
    echo "  - No packages generated" >> artifacts/LINUX_PACKAGES.txt
fi

echo ""
echo "✅ Linux packaging complete!"
echo "📋 Package summary:"
cat artifacts/LINUX_PACKAGES.txt