#!/bin/bash
set -euo pipefail

# Sign and notarize macOS applications following Apple's inside-out signing requirements
# Usage: sign-and-notarize-macos.sh <version> <build_type> <apple_id> <apple_id_password> <team_id>

VERSION="${1:-1.0.0}"
BUILD_TYPE="${2:-production}"
APPLE_ID="${3}"
APPLE_ID_PASSWORD="${4}"
TEAM_ID="${5}"

echo "🍎 Starting macOS signing and notarization process..."
echo "Version: $VERSION"
echo "Build Type: $BUILD_TYPE"
echo "Team ID: $TEAM_ID"

# Validate required environment
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ] || [ -z "$TEAM_ID" ]; then
    echo "❌ Error: Missing required Apple credentials"
    echo "Required: APPLE_ID, APPLE_ID_PASSWORD, TEAM_ID"
    exit 1
fi

# Find the signing identity
SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | cut -d'"' -f2)
if [ -z "$SIGNING_IDENTITY" ]; then
    echo "❌ Error: No 'Developer ID Application' certificate found"
    echo "Available identities:"
    security find-identity -v -p codesigning
    exit 1
fi

echo "📋 Using signing identity: $SIGNING_IDENTITY"

# Function to sign an application bundle using inside-out approach
sign_app_bundle() {
    local app_path="$1"
    local app_name=$(basename "$app_path")
    
    echo "🔐 Signing $app_name using inside-out approach..."
    
    if [ ! -d "$app_path" ]; then
        echo "❌ Error: App bundle not found: $app_path"
        return 1
    fi
    
    # Step 1: Sign all frameworks and libraries inside the app bundle first
    echo "📦 Signing embedded frameworks and libraries..."
    find "$app_path" -type f \( -name "*.dylib" -o -name "*.so" \) -exec codesign --force --verify --verbose --sign "$SIGNING_IDENTITY" --options runtime {} \; || true
    
    # Step 2: Sign frameworks
    find "$app_path" -type d -name "*.framework" | while read framework; do
        if [ -d "$framework" ]; then
            echo "🔗 Signing framework: $(basename "$framework")"
            codesign --force --verify --verbose --sign "$SIGNING_IDENTITY" --options runtime "$framework" || true
        fi
    done
    
    # Step 3: Sign nested app bundles
    find "$app_path" -type d -name "*.app" -not -path "$app_path" | while read nested_app; do
        if [ -d "$nested_app" ]; then
            echo "📱 Signing nested app: $(basename "$nested_app")"
            codesign --force --verify --verbose --sign "$SIGNING_IDENTITY" --options runtime --entitlements entitlements.plist "$nested_app" || true
        fi
    done
    
    # Step 4: Sign the main executable
    if [ -f "$app_path/Contents/MacOS/$(basename "$app_path" .app)" ]; then
        echo "⚡ Signing main executable..."
        codesign --force --verify --verbose --sign "$SIGNING_IDENTITY" --options runtime "$app_path/Contents/MacOS/$(basename "$app_path" .app)"
    fi
    
    # Step 5: Sign the entire app bundle (outermost layer)
    echo "🎯 Signing app bundle: $app_name"
    codesign --force --verify --verbose --sign "$SIGNING_IDENTITY" --options runtime --entitlements entitlements.plist "$app_path"
    
    # Verify the signature
    echo "✅ Verifying signature for $app_name..."
    codesign --verify --deep --strict --verbose=2 "$app_path"
    spctl --assess --type exec --verbose "$app_path"
    
    echo "✅ Successfully signed $app_name"
}

# Function to create a DMG and sign it
create_and_sign_dmg() {
    local app_path="$1"
    local app_name=$(basename "$app_path" .app)
    local dmg_name="$app_name-$VERSION.dmg"
    
    echo "💽 Creating DMG for $app_name..."
    
    # Create temporary directory for DMG contents
    local temp_dmg_dir=$(mktemp -d)
    cp -R "$app_path" "$temp_dmg_dir/"
    
    # Create the DMG
    if command -v create-dmg >/dev/null 2>&1; then
        create-dmg \
            --volname "$app_name $VERSION" \
            --volicon "r2midi.icns" \
            --window-pos 200 120 \
            --window-size 800 400 \
            --icon-size 100 \
            --icon "$app_name.app" 200 190 \
            --hide-extension "$app_name.app" \
            --app-drop-link 600 190 \
            "$dmg_name" \
            "$temp_dmg_dir"
    else
        # Fallback to hdiutil
        hdiutil create -format UDZO -srcfolder "$temp_dmg_dir" -volname "$app_name $VERSION" "$dmg_name"
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_dmg_dir"
    
    # Sign the DMG
    echo "🔐 Signing DMG: $dmg_name"
    codesign --force --verify --verbose --sign "$SIGNING_IDENTITY" "$dmg_name"
    
    echo "✅ Created and signed DMG: $dmg_name"
    return 0
}

# Function to notarize a file
notarize_file() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    
    echo "📤 Submitting $file_name for notarization..."
    
    # Submit for notarization
    local submit_result
    submit_result=$(xcrun notarytool submit "$file_path" \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_ID_PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait \
        --output-format json)
    
    local submission_id
    submission_id=$(echo "$submit_result" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    
    echo "📋 Submission ID: $submission_id"
    
    # Check if notarization was successful
    if echo "$submit_result" | grep -q '"status":"Accepted"'; then
        echo "✅ Notarization successful for $file_name"
        
        # Staple the notarization ticket
        echo "📎 Stapling notarization ticket..."
        xcrun stapler staple "$file_path"
        
        # Verify stapling
        echo "🔍 Verifying stapled ticket..."
        xcrun stapler validate "$file_path"
        
        echo "✅ Successfully notarized and stapled $file_name"
        return 0
    else
        echo "❌ Notarization failed for $file_name"
        echo "📋 Submission result:"
        echo "$submit_result"
        
        # Get detailed log
        echo "📋 Getting notarization log..."
        xcrun notarytool log "$submission_id" \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_ID_PASSWORD" \
            --team-id "$TEAM_ID"
        
        return 1
    fi
}

# Function to create a signed PKG installer
create_signed_pkg() {
    local app_path="$1"
    local app_name=$(basename "$app_path" .app)
    local pkg_name="$app_name-$VERSION.pkg"
    
    echo "📦 Creating PKG installer for $app_name..."
    
    # Find installer signing identity
    local installer_identity
    installer_identity=$(security find-identity -v -p basic | grep "Developer ID Installer" | head -1 | cut -d'"' -f2)
    
    if [ -z "$installer_identity" ]; then
        echo "⚠️ Warning: No 'Developer ID Installer' certificate found, skipping PKG creation"
        return 1
    fi
    
    echo "📋 Using installer identity: $installer_identity"
    
    # Create the PKG
    pkgbuild --root artifacts --install-location "/Applications" \
        --sign "$installer_identity" \
        --identifier "com.r2midi.$app_name" \
        --version "$VERSION" \
        "$pkg_name"
    
    echo "✅ Created signed PKG: $pkg_name"
    return 0
}

# Main signing and notarization workflow
echo "🔍 Looking for built applications..."

# Ensure artifacts directory exists
mkdir -p artifacts

# Process each application
for app_type in "server" "r2midi-client"; do
    app_dir="dist/$app_type"
    
    if [ -d "$app_dir" ]; then
        # Find the .app bundle
        app_bundle=$(find "$app_dir" -name "*.app" -type d | head -1)
        
        if [ -n "$app_bundle" ] && [ -d "$app_bundle" ]; then
            echo "📱 Found app bundle: $app_bundle"
            
            # Step 1: Sign the app bundle
            sign_app_bundle "$app_bundle"
            
            # Step 2: Create and sign DMG
            if create_and_sign_dmg "$app_bundle"; then
                dmg_file="$(basename "$app_bundle" .app)-$VERSION.dmg"
                
                # Step 3: Notarize the DMG
                if notarize_file "$dmg_file"; then
                    # Move to artifacts
                    mv "$dmg_file" artifacts/
                    echo "✅ DMG ready: artifacts/$dmg_file"
                else
                    echo "❌ Failed to notarize DMG for $app_type"
                fi
            fi
            
            # Step 4: Create PKG installer (optional)
            if [ "$BUILD_TYPE" = "production" ]; then
                if create_signed_pkg "$app_bundle"; then
                    pkg_file="$(basename "$app_bundle" .app)-$VERSION.pkg"
                    
                    # Notarize the PKG
                    if notarize_file "$pkg_file"; then
                        # Move to artifacts
                        mv "$pkg_file" artifacts/
                        echo "✅ PKG ready: artifacts/$pkg_file"
                    else
                        echo "❌ Failed to notarize PKG for $app_type"
                    fi
                fi
            fi
            
        else
            echo "⚠️ Warning: No .app bundle found for $app_type"
        fi
    else
        echo "⚠️ Warning: No dist directory found for $app_type"
    fi
done

# Create signing report
cat > artifacts/SIGNING_REPORT.txt << EOF
macOS Signing and Notarization Report
=====================================

Build Information:
- Version: $VERSION
- Build Type: $BUILD_TYPE
- Signing Identity: $SIGNING_IDENTITY
- Team ID: $TEAM_ID
- Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

Signing Method: Apple Developer ID (inside-out signing)
Notarization: Apple Notary Service with stapling
Tool: xcrun notarytool

Applications Processed:
EOF

# List processed applications
if [ -d "artifacts" ] && [ "$(ls -A artifacts/)" ]; then
    find artifacts/ -name "*.dmg" -o -name "*.pkg" | sort | while read file; do
        if [ -f "$file" ]; then
            size=$(du -h "$file" | cut -f1)
            echo "  - $(basename "$file") ($size)" >> artifacts/SIGNING_REPORT.txt
        fi
    done
else
    echo "  - No signed applications generated" >> artifacts/SIGNING_REPORT.txt
fi

echo ""
echo "✅ macOS signing and notarization process complete!"
echo "📋 Signing report:"
cat artifacts/SIGNING_REPORT.txt