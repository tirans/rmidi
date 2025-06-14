# R2MIDI GitHub Actions Build System

This document describes the complete GitHub Actions setup for building R2MIDI applications across all platforms with proper signing and distribution.

## 🏗️ Architecture Overview

The build system consists of **separated, modular workflows** and **external scripts** as requested:

### Workflows (`.github/workflows/`)
- **`release.yml`** - Main release workflow that orchestrates everything
- **`ci.yml`** - Continuous integration (tests, linting, security)
- **`build-windows.yml`** - Windows builds (unsigned, Briefcase)
- **`build-linux.yml`** - Linux builds (unsigned, Briefcase)  
- **`build-macos.yml`** - macOS builds (signed & notarized, Briefcase)

### Scripts (`.github/scripts/`)
- **`build-briefcase-apps.sh`** - Core Briefcase build logic
- **`sign-and-notarize-macos.sh`** - macOS signing & notarization (inside-out)
- **`package-windows-apps.sh`** - Windows packaging (ZIP, MSI)
- **`package-linux-apps.sh`** - Linux packaging (TAR.GZ, DEB, AppImage)
- **`package-macos-apps.sh`** - macOS packaging (DMG, PKG)
- **`update-version.sh`** - Version management across project files
- **`validate-build-environment.sh`** - Build environment validation
- **`validate-project-structure.sh`** - Project structure validation
- **`build-python-package.sh`** - Python package building for PyPI
- **`prepare-release-artifacts.sh`** - Final release artifact organization

## 🚀 Quick Setup

1. **Make scripts executable:**
   ```bash
   chmod +x .github/scripts/*.sh
   ```

2. **Run setup script:**
   ```bash
   ./.github/scripts/setup-workflows.sh
   ```

3. **Configure secrets** (see [Secrets Configuration](#secrets-configuration))

4. **Test by pushing to master** or creating a pull request

## 🔐 Secrets Configuration

### Required for macOS Signing & Notarization

Configure these in GitHub repository settings → Secrets and variables → Actions:

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `APPLE_CERTIFICATE_P12` | Base64 encoded Developer ID certificate | Export from Keychain, encode with `base64 -i cert.p12` |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the .p12 file | Set when exporting certificate |
| `APPLE_ID` | Your Apple ID email | Your Apple Developer account email |
| `APPLE_ID_PASSWORD` | App-specific password | Generate in Apple ID settings |
| `APPLE_TEAM_ID` | Apple Developer Team ID | Found in Apple Developer portal |

### Optional for PyPI Publishing

| Secret Name | Description |
|-------------|-------------|
| `PYPI_API_TOKEN` | PyPI API token (if not using OIDC) |

**Recommended:** Use OIDC trusted publishing instead of API tokens (more secure).

## 🏃‍♂️ How It Works

### Release Process (`release.yml`)
1. **Version Management** - Increments version, updates files, creates Git tag
2. **Testing** - Runs full CI suite across multiple Python versions/platforms
3. **Platform Builds** - Parallel builds for Windows, Linux, and macOS
4. **Python Package** - Builds wheel and source distribution
5. **PyPI Publishing** - Uploads to PyPI with OIDC trusted publishing
6. **GitHub Release** - Creates release with all artifacts and documentation

### Build Outputs

#### 🍎 macOS (Signed & Notarized)
- **DMG installers** - Drag-and-drop installation
- **PKG installers** - Automated installation with system integration
- **Inside-out signing** - Proper Apple Developer ID signing
- **Notarization** - Apple Notary Service with stapling
- **Gatekeeper compatible** - No security warnings

#### 🪟 Windows (Unsigned)
- **ZIP packages** - Portable applications (no installation required)
- **MSI installers** - Traditional Windows installers (if available)
- **Security warnings normal** - Expected for unsigned open-source apps

#### 🐧 Linux (Unsigned)
- **TAR.GZ archives** - Universal Linux packages
- **DEB packages** - Debian/Ubuntu installation packages
- **AppImage** - Universal Linux applications (if available)

#### 🐍 Python Package
- **PyPI distribution** - `pip install r2midi`
- **Wheel format** - Universal Python wheel
- **Source distribution** - For custom builds

## 🔧 Customization

### Modifying Build Behavior

**Platform-specific changes:**
- Edit individual build workflows (`build-*.yml`)
- Modify platform-specific scripts (`package-*-apps.sh`)

**Version management:**
- Customize `update-version.sh` for different versioning schemes
- Modify version file locations in the script

**Signing/packaging:**
- macOS: Edit `sign-and-notarize-macos.sh` for different signing requirements
- Windows: Modify `package-windows-apps.sh` for custom packaging
- Linux: Customize `package-linux-apps.sh` for additional package formats

### Adding New Platforms

1. Create new workflow file: `.github/workflows/build-<platform>.yml`
2. Create new packaging script: `.github/scripts/package-<platform>-apps.sh`
3. Add platform to `release.yml` workflow
4. Update validation scripts if needed

## 🧪 Testing

### Local Testing

**Validate project structure:**
```bash
./.github/scripts/validate-project-structure.sh
```

**Validate build environment:**
```bash
./.github/scripts/validate-build-environment.sh <platform>
```

**Test individual components:**
```bash
# Test Briefcase builds
./.github/scripts/build-briefcase-apps.sh linux unsigned

# Test packaging
./.github/scripts/package-linux-apps.sh "1.0.0" "dev"
```

### CI Testing

**Automatic triggers:**
- **Push to `master`** - Full release workflow
- **Push to `develop`** - CI workflow only  
- **Pull requests** - CI workflow only

**Manual triggers:**
- Go to GitHub Actions → Select workflow → "Run workflow"
- Choose version increment type and build type

## 📁 Artifact Organization

The build system automatically organizes artifacts by platform:

```
release_files/
├── macos/           # DMG and PKG files
├── windows/         # ZIP and MSI files  
├── linux/           # TAR.GZ, DEB, AppImage files
├── python/          # Wheel and source distribution
├── checksums/       # SHA256, SHA1, MD5 checksums
├── verify_release.sh # Verification script
└── RELEASE_NOTES.md # Comprehensive release notes
```

## 🛠️ Troubleshooting

### Common Issues

**macOS signing fails:**
- Verify all Apple secrets are correctly configured
- Check certificate is "Developer ID Application" type
- Ensure certificate includes private key

**Windows security warnings:**
- Expected behavior for unsigned applications
- Users should click "More info" → "Run anyway"

**Linux dependency issues:**
- Install system dependencies: `libasound2-dev portaudio19-dev qt6-base-dev`
- Use package managers appropriate for distribution

**Build failures:**
- Check `validate-build-environment.sh` output
- Verify all required files are present
- Review GitHub Actions logs for specific errors

### Debug Mode

Add this to any script for verbose output:
```bash
set -x  # Enable debug mode
# Your commands here
set +x  # Disable debug mode
```

## 🎯 Key Benefits

### ✅ As Requested
- **Separated files** - No lengthy workflow files
- **No inline scripts** - All logic in external `.sh` files  
- **Unsigned Windows/Linux** - Using Briefcase as requested
- **Signed & notarized macOS** - Using inside-out signing + notarization

### ✅ Production Ready
- **Comprehensive testing** - CI across multiple Python versions/platforms
- **Security scanning** - Vulnerability and code quality checks
- **Proper signing** - Apple Developer ID with notarization
- **Complete documentation** - Installation guides for all platforms
- **Artifact verification** - Checksums and verification scripts

### ✅ Maintainable
- **Modular design** - Easy to modify individual components
- **Error handling** - Robust error checking and reporting
- **Logging** - Detailed build information and summaries
- **Validation** - Pre-build environment and structure checks

## 📚 Additional Resources

- **Apple Code Signing Guide:** [MACOS_SIGNING_GUIDE.md](.github/MACOS_SIGNING_GUIDE.md) (if available)
- **Briefcase Documentation:** https://briefcase.readthedocs.io/
- **GitHub Actions Documentation:** https://docs.github.com/en/actions
- **Apple Notarization:** https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution

## 🆘 Support

If you encounter issues:
1. Review the troubleshooting section above
2. Check GitHub Actions logs for detailed error messages
3. Validate your project structure and environment
4. Open an issue with relevant logs and system information

---

**This setup provides enterprise-grade automated building with proper platform-specific signing and packaging, exactly as requested.**