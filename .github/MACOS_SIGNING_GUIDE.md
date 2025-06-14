# 🍎 macOS Code Signing & Notarization Setup

## Overview

The R2MIDI project now supports proper macOS code signing and notarization for production builds. This ensures that applications can be distributed outside the Mac App Store without triggering security warnings.

## Build Strategy by Platform

### 🐧 Linux & 🪟 Windows
- **Tool**: Briefcase
- **Output**: Standard application packages (.deb, .msi, .zip, .tar.gz)
- **Signing**: Not applicable

### 🍎 macOS
- **Tool**: py2app (native Apple toolchain)
- **Output**: Signed and notarized .app bundles
- **Packaging**: DMG installers, PKG installers, ZIP archives
- **Security**: Code signed with Developer ID + notarized by Apple

## Required Secrets for macOS Signing

To enable code signing and notarization, you need to set up these GitHub repository secrets:

### Code Signing Certificate
```
APPLE_CERTIFICATE_P12
```
- Base64 encoded P12 certificate file
- Export your "Developer ID Application" certificate from Keychain Access
- Include private key when exporting
- Convert to base64: `base64 -i certificate.p12 | pbcopy`

```
APPLE_CERTIFICATE_PASSWORD
```
- Password for the P12 certificate file

### Notarization Credentials
```
APPLE_ID
```
- Your Apple ID email address
- Must be enrolled in Apple Developer Program

```
APPLE_ID_PASSWORD
```
- App-specific password for your Apple ID
- Generate at: https://appleid.apple.com/account/manage
- Section: "Sign-In and Security" → "App-Specific Passwords"

```
APPLE_TEAM_ID
```
- Your 10-character Apple Developer Team ID
- Find in Apple Developer Portal or Keychain Access

## Setting Up macOS Signing

### 1. Generate Certificates
1. Log in to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
2. Create a "Developer ID Application" certificate
3. Download and install in Keychain Access
4. Export as P12 file with private key

### 2. Create App-Specific Password
1. Go to [Apple ID Account](https://appleid.apple.com/account/manage)
2. Sign-In and Security → App-Specific Passwords
3. Generate new password for "GitHub Actions"
4. Save the generated password

### 3. Add Secrets to GitHub
1. Go to your repository → Settings → Secrets and variables → Actions
2. Add all required secrets listed above

## Workflow Configuration

### Production Builds (Signed & Notarized)
```yaml
uses: ./.github/workflows/reusable-build.yml
with:
  platform: macOS
  os: macos-13  # or macos-14
  build-type: production
  sign-builds: true  # Enable signing and notarization
secrets: inherit  # Pass all secrets
```

### Development Builds (Unsigned)
```yaml
uses: ./.github/workflows/reusable-build.yml
with:
  platform: macOS
  os: macos-13
  build-type: dev
  sign-builds: false  # Skip signing for faster dev builds
```

## Build Process Details

### 1. Environment Setup
- Install py2app and native macOS build tools
- Skip Briefcase for macOS (doesn't support proper signing)

### 2. Code Signing Setup
- Import P12 certificate into temporary keychain
- Configure codesign access
- Set up notarization profile with credentials

### 3. Application Building
- Build server app with py2app
- Build client app with py2app
- Each app is a standalone .app bundle

### 4. Code Signing Process
- Sign all nested frameworks and libraries
- Sign main application bundles
- Use "runtime" hardening for notarization compatibility
- Verify signatures after signing

### 5. Notarization Process
- Create ZIP archives for notarization submission
- Submit to Apple's notarization service
- Wait for notarization approval
- Staple notarization tickets to applications

### 6. Package Creation
- **DMG**: Drag-and-drop installers with Applications folder link
- **PKG**: Automated installers for enterprise deployment
- **ZIP**: Portable archives for manual installation

## Verification

### Local Verification Commands
```bash
# Verify code signature
codesign --verify --deep --strict /path/to/App.app

# Check signature details
codesign -dv /path/to/App.app

# Test Gatekeeper approval
spctl --assess --type exec /path/to/App.app

# Check notarization status
spctl --assess -vv --type install /path/to/installer.dmg
```

### Build Verification (Automatic)
The workflow automatically verifies:
- ✅ Code signature validity
- ✅ Deep signature verification
- ✅ Notarization status
- ✅ Gatekeeper approval

## Security Benefits

### For End Users
- ✅ No "unidentified developer" warnings
- ✅ No need to bypass Gatekeeper
- ✅ Automatic security scanning by Apple
- ✅ Smooth installation experience

### For Distribution
- ✅ Can be distributed outside Mac App Store
- ✅ Compatible with enterprise deployment
- ✅ Meets corporate security requirements
- ✅ No manual security overrides needed

## Output Files

### Development Builds
```
artifacts/
├── R2MIDI Server.app          # Unsigned server app
├── R2MIDI Client.app          # Unsigned client app
└── BUILD_INFO.txt             # Build metadata
```

### Production Builds (Signed & Notarized)
```
artifacts/
├── R2MIDI-Server-1.0.0.dmg   # Signed server DMG
├── R2MIDI-Server-1.0.0.pkg   # Server PKG installer
├── R2MIDI-Client-1.0.0.dmg   # Signed client DMG
├── R2MIDI-Client-1.0.0.pkg   # Client PKG installer
├── R2MIDI-Suite-1.0.0.dmg    # Combined installer
├── r2midi-server-1.0.0-macos.zip  # Server ZIP
├── r2midi-client-1.0.0-macos.zip  # Client ZIP
├── PACKAGES.txt               # Installation instructions
└── BUILD_INFO.md              # Detailed build info
```

## Troubleshooting

### Common Issues

#### "No signing identity found"
- Check that `APPLE_CERTIFICATE_P12` and `APPLE_CERTIFICATE_PASSWORD` are set
- Verify P12 file includes private key
- Ensure certificate is "Developer ID Application" type

#### "Notarization failed"
- Verify Apple ID credentials are correct
- Check that Apple ID has Developer Program access
- Ensure app-specific password is valid
- Confirm Team ID is correct

#### "App is damaged" on user machines
- Usually indicates signing issue
- Check that all nested binaries are signed
- Verify notarization was successful
- User can run: `xattr -cr /Applications/YourApp.app`

### Debug Commands
```bash
# List available signing identities
security find-identity -v -p codesigning

# Check keychain contents
security list-keychains

# View notarization history
xcrun notarytool history --keychain-profile "profile-name"
```

## Performance Notes

- ⏱️ Signing adds ~2-3 minutes to build time
- ⏱️ Notarization adds ~5-15 minutes (Apple processing time)
- 💾 Signed apps are slightly larger due to signatures
- 🔄 Total macOS production build time: ~20-30 minutes

## Best Practices

1. **Development**: Use unsigned builds for faster iteration
2. **Testing**: Test signed builds before major releases
3. **Secrets**: Rotate certificates and passwords annually
4. **Verification**: Always verify signatures in CI
5. **Distribution**: Prefer DMG for end users, PKG for enterprise

This setup ensures R2MIDI applications are properly signed and trusted by macOS, providing a professional distribution experience. 🚀
