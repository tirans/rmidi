#!/bin/bash
set -euo pipefail

# Generate build summary for GitHub Actions
# Usage: generate-build-summary.sh <platform> <build_type> [version] [signing_status]

PLATFORM="${1:-unknown}"
BUILD_TYPE="${2:-production}"
VERSION="${3:-${APP_VERSION:-unknown}}"
SIGNING_STATUS="${4:-unsigned}"

echo "📋 Generating build summary for $PLATFORM..."

# Function to get platform emoji
get_platform_emoji() {
    case "$1" in
        linux) echo "🐧" ;;
        macos) echo "🍎" ;;
        windows) echo "🪟" ;;
        python) echo "🐍" ;;
        *) echo "📦" ;;
    esac
}

# Function to get signing status with emoji
get_signing_emoji() {
    case "$1" in
        signed|notarized) echo "✅" ;;
        unsigned) echo "❌" ;;
        *) echo "⚠️" ;;
    esac
}

# Function to list artifacts with sizes
list_artifacts() {
    local search_path="${1:-artifacts}"
    local pattern="${2:-*}"
    
    if [ -d "$search_path" ]; then
        local found=false
        find "$search_path" -name "$pattern" -type f | sort | while read file; do
            if [ -f "$file" ]; then
                local size=$(du -h "$file" | cut -f1)
                local basename_file=$(basename "$file")
                echo "- $basename_file ($size)"
                found=true
            fi
        done
        
        if [ "$found" = false ]; then
            echo "- No artifacts found"
        fi
    else
        echo "- Artifacts directory not found"
    fi
}

# Function to get build tool info
get_build_tool() {
    if command -v briefcase >/dev/null 2>&1; then
        echo "Briefcase"
    else
        echo "Custom build"
    fi
}

# Function to get detailed signing information
get_signing_details() {
    case "$PLATFORM-$SIGNING_STATUS" in
        macos-signed|macos-notarized)
            echo "Apple Developer ID (signed & notarized)"
            ;;
        macos-unsigned)
            echo "Unsigned (development build)"
            ;;
        windows-signed)
            echo "Code signed with certificate"
            ;;
        windows-unsigned)
            echo "Unsigned (as requested)"
            ;;
        linux-unsigned|python-unsigned)
            echo "Unsigned (standard for $PLATFORM)"
            ;;
        *)
            echo "Unknown signing status"
            ;;
    esac
}

# Generate the build summary for GitHub Actions
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    cat >> "$GITHUB_STEP_SUMMARY" << EOF
## $(get_platform_emoji "$PLATFORM") $PLATFORM Build Complete

**Version:** $VERSION  
**Build Type:** $BUILD_TYPE  
**Signing:** $(get_signing_emoji "$SIGNING_STATUS") $(get_signing_details)  
**Build Tool:** $(get_build_tool)  
EOF

    # Add platform-specific information
    case "$PLATFORM" in
        macos)
            cat >> "$GITHUB_STEP_SUMMARY" << EOF
**Packaging:** DMG + PKG installers  
**Gatekeeper:** Compatible with all macOS security settings  
EOF
            ;;
        windows)
            cat >> "$GITHUB_STEP_SUMMARY" << EOF
**Packaging:** ZIP portable + MSI installers  
**Security Warning:** Expected for unsigned applications  
EOF
            ;;
        linux)
            cat >> "$GITHUB_STEP_SUMMARY" << EOF
**Packaging:** DEB + TAR.GZ + AppImage  
**Distribution:** Compatible with most Linux distributions  
EOF
            ;;
        python)
            cat >> "$GITHUB_STEP_SUMMARY" << EOF
**Packaging:** Wheel + Source distribution  
**PyPI:** Ready for upload  
EOF
            ;;
    esac

    # List created packages/artifacts
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "### 📦 Created Packages:" >> "$GITHUB_STEP_SUMMARY"
    
    case "$PLATFORM" in
        macos)
            list_artifacts "artifacts" "*.dmg" >> "$GITHUB_STEP_SUMMARY"
            list_artifacts "artifacts" "*.pkg" >> "$GITHUB_STEP_SUMMARY"
            ;;
        windows)
            list_artifacts "artifacts" "*.zip" >> "$GITHUB_STEP_SUMMARY"
            list_artifacts "artifacts" "*.msi" >> "$GITHUB_STEP_SUMMARY"
            ;;
        linux)
            list_artifacts "artifacts" "*.deb" >> "$GITHUB_STEP_SUMMARY"
            list_artifacts "artifacts" "*.tar.gz" >> "$GITHUB_STEP_SUMMARY"
            list_artifacts "artifacts" "*.AppImage" >> "$GITHUB_STEP_SUMMARY"
            ;;
        python)
            list_artifacts "dist" "*.whl" >> "$GITHUB_STEP_SUMMARY"
            list_artifacts "dist" "*.tar.gz" >> "$GITHUB_STEP_SUMMARY"
            ;;
        *)
            list_artifacts "artifacts" "*" >> "$GITHUB_STEP_SUMMARY"
            ;;
    esac
    
    # Add build metrics if available
    if [ -d "artifacts" ] || [ -d "dist" ]; then
        echo "" >> "$GITHUB_STEP_SUMMARY"
        echo "### 📊 Build Metrics:" >> "$GITHUB_STEP_SUMMARY"
        
        # Calculate total size
        local total_size="Unknown"
        if [ -d "artifacts" ]; then
            total_size=$(du -sh artifacts/ 2>/dev/null | cut -f1 || echo "Unknown")
        elif [ -d "dist" ]; then
            total_size=$(du -sh dist/ 2>/dev/null | cut -f1 || echo "Unknown")
        fi
        
        echo "- **Total package size:** $total_size" >> "$GITHUB_STEP_SUMMARY"
        echo "- **Build time:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$GITHUB_STEP_SUMMARY"
        echo "- **Runner OS:** $(uname -s) $(uname -m)" >> "$GITHUB_STEP_SUMMARY"
    fi
fi

# Generate detailed build report file
cat > "build_summary_${PLATFORM}.txt" << EOF
R2MIDI Build Summary - $PLATFORM
===============================

Build Information:
- Platform: $PLATFORM
- Version: $VERSION
- Build Type: $BUILD_TYPE
- Signing Status: $SIGNING_STATUS
- Build Tool: $(get_build_tool)
- Build Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
- Runner: $(uname -s) $(uname -m)

Signing Details:
$(get_signing_details)

Created Artifacts:
EOF

# Add artifacts to the report
case "$PLATFORM" in
    macos)
        echo "DMG Files:" >> "build_summary_${PLATFORM}.txt"
        list_artifacts "artifacts" "*.dmg" >> "build_summary_${PLATFORM}.txt"
        echo "" >> "build_summary_${PLATFORM}.txt"
        echo "PKG Files:" >> "build_summary_${PLATFORM}.txt"
        list_artifacts "artifacts" "*.pkg" >> "build_summary_${PLATFORM}.txt"
        ;;
    windows)
        echo "ZIP Files:" >> "build_summary_${PLATFORM}.txt"
        list_artifacts "artifacts" "*.zip" >> "build_summary_${PLATFORM}.txt"
        echo "" >> "build_summary_${PLATFORM}.txt"
        echo "MSI Files:" >> "build_summary_${PLATFORM}.txt"
        list_artifacts "artifacts" "*.msi" >> "build_summary_${PLATFORM}.txt"
        ;;
    linux)
        echo "DEB Packages:" >> "build_summary_${PLATFORM}.txt"
        list_artifacts "artifacts" "*.deb" >> "build_summary_${PLATFORM}.txt"
        echo "" >> "build_summary_${PLATFORM}.txt"
        echo "TAR.GZ Archives:" >> "build_summary_${PLATFORM}.txt"
        list_artifacts "artifacts" "*.tar.gz" >> "build_summary_${PLATFORM}.txt"
        echo "" >> "build_summary_${PLATFORM}.txt"
        echo "AppImage Files:" >> "build_summary_${PLATFORM}.txt"
        list_artifacts "artifacts" "*.AppImage" >> "build_summary_${PLATFORM}.txt"
        ;;
    python)
        echo "Wheel Files:" >> "build_summary_${PLATFORM}.txt"
        list_artifacts "dist" "*.whl" >> "build_summary_${PLATFORM}.txt"
        echo "" >> "build_summary_${PLATFORM}.txt"
        echo "Source Distributions:" >> "build_summary_${PLATFORM}.txt"
        list_artifacts "dist" "*.tar.gz" >> "build_summary_${PLATFORM}.txt"
        ;;
    *)
        echo "All Files:" >> "build_summary_${PLATFORM}.txt"
        list_artifacts "artifacts" "*" >> "build_summary_${PLATFORM}.txt"
        ;;
esac

# Add platform-specific notes
cat >> "build_summary_${PLATFORM}.txt" << EOF

Platform-Specific Notes:
EOF

case "$PLATFORM" in
    macos)
        cat >> "build_summary_${PLATFORM}.txt" << EOF
- DMG files provide drag-and-drop installation
- PKG files provide automated installation with system integration
- All applications are signed and notarized for security
- Compatible with all macOS security settings (no warnings)
EOF
        ;;
    windows)
        cat >> "build_summary_${PLATFORM}.txt" << EOF
- ZIP files are portable applications (no installation required)
- MSI files provide traditional Windows installer experience
- Applications are unsigned - security warnings are expected
- Windows Defender may need approval for unsigned applications
EOF
        ;;
    linux)
        cat >> "build_summary_${PLATFORM}.txt" << EOF
- DEB packages work with Debian/Ubuntu and derivatives
- TAR.GZ archives work with any Linux distribution
- AppImage files are universal and self-contained
- Most Linux software is unsigned - no security warnings expected
EOF
        ;;
    python)
        cat >> "build_summary_${PLATFORM}.txt" << EOF
- Wheel files provide fast installation across platforms
- Source distributions allow custom compilation
- Compatible with pip and other Python package managers
- Ready for PyPI upload and distribution
EOF
        ;;
esac

echo "✅ Build summary generated for $PLATFORM"
echo "📋 Summary files created:"
echo "   - GitHub Actions Step Summary (in workflow)"
echo "   - build_summary_${PLATFORM}.txt (detailed report)"

# Output key information for other scripts
echo "PLATFORM=$PLATFORM"
echo "VERSION=$VERSION"
echo "BUILD_TYPE=$BUILD_TYPE"
echo "SIGNING_STATUS=$SIGNING_STATUS"
