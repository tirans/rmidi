# R2MIDI GitHub Actions Workflows

A comprehensive three-stage workflow system for building, testing, and distributing R2MIDI applications across all platforms with proper code signing.

## 🏗️ Workflow Architecture

The R2MIDI project uses a **three-stage progression** that ensures quality, security, and proper distribution:

```
Development → Staging → Production
    dev.yml → build.yml → release.yml
```

### Strategy Overview

- **Never create unsigned macOS builds** (security nightmare for users)
- **macOS only appears in signed production releases**
- **Clear progression from development to production**
- **Environment-based secret protection**
- **Comprehensive error handling and status reporting**

## 📋 Workflow Details

### 1. Development Workflow (`dev.yml`)

**Purpose**: Fast feedback for feature development and testing

**Triggers**:
- Push to: `develop`, `feature/*`, `dev/*`, `test/*` branches
- Pull requests to: `master`, `main`, `develop`
- Manual dispatch (`workflow_dispatch`)

**Platforms**:
- 🐧 **Linux**: Full builds, always works
- 🪟 **Windows**: Unsigned builds (security warnings expected)
- 🍎 **macOS**: Signed if certificates available, otherwise skipped

**Duration**: 10-15 minutes

**Features**:
- Quick validation with syntax checks and fast test suite
- Development versioning with branch/commit info
- macOS code signing in development environment (if configured)
- Security warnings expected for unsigned Windows builds
- Artifacts retained for 14 days

**Output Artifacts**:
- `dev-builds-linux-{run_number}` - Linux development builds
- `dev-builds-windows-{run_number}` - Windows development builds (unsigned)
- `dev-builds-macos-{run_number}` - macOS development builds (signed if certs available)

### 2. Stable Build Workflow (`build.yml`)

**Purpose**: Stable builds for staging and PyPI distribution

**Triggers**:
- Push to: `master` branch
- Pull requests to: `master`

**Platforms**:
- 🐧 **Linux**: Full builds, production ready
- 🪟 **Windows**: Unsigned builds, basic distribution
- 🚫 **macOS**: **NO BUILDS** (prevents unsigned app distribution)

**Duration**: 15-20 minutes

**Features**:
- Multi-Python version testing (3.10, 3.11, 3.12)
- Automatic PyPI publishing on master push
- Staging release creation with unsigned builds
- Production-quality Linux builds
- Test coverage reporting

**Output Artifacts**:
- PyPI package published automatically
- Staging GitHub release (draft) with unsigned Linux/Windows builds
- `stable-builds-linux` - Production-ready Linux builds
- `stable-builds-windows` - Unsigned Windows builds for testing

### 3. Production Release Workflow (`release.yml`)

**Purpose**: Production-signed releases for all platforms

**Triggers**:
- **Automatically after successful `build.yml` on master**
- Only runs if signing certificates are available

**Platforms**:
- 🐧 **Linux**: Consistent with staging builds
- 🪟 **Windows**: Signed builds (if certificates available)
- 🍎 **macOS**: Fully signed, notarized, App Store ready

**Duration**: 20-30 minutes

**Features**:
- Full code signing on all platforms
- macOS notarization support
- **Automatic App Store submission** with App Store Connect API
- App Store package creation (.pkg files)
- Production environment secret access
- Final GitHub release publication with App Store links

**Output Artifacts**:
- Final GitHub release with all signed applications
- Code-signed Windows executables
- Notarized macOS applications
- **App Store packages automatically submitted**
- App Store Connect upload confirmation

## 🔐 Security & Code Signing

### Platform-Specific Signing Behavior

| Platform | Development | Staging | Production |
|----------|-------------|---------|------------|
| **Linux** | ✅ No signing needed | ✅ Production ready | ✅ Same quality |
| **Windows** | ⚠️ Unsigned (warnings) | ⚠️ Unsigned (testing) | ✅ Code signed |
| **macOS** | ✅ Signed if certs available<br/>❌ Skip if no certs | 🚫 **No builds** | ✅ Fully signed & notarized |

### Required Secrets

Set these in **Repository Settings** → **Secrets and variables** → **Actions**:

#### 🍎 macOS Signing (Required for production)
```
APPLE_CERTIFICATE_P12           # Base64 Developer ID certificate
APPLE_CERTIFICATE_PASSWORD      # Certificate password
APPLE_ID                        # Apple Developer email
APPLE_ID_PASSWORD               # App-specific password
APPLE_TEAM_ID                   # Developer Team ID
```

#### 🪟 Windows Signing (Optional)
```
WINDOWS_CERTIFICATE_P12         # Base64 Windows certificate
WINDOWS_CERTIFICATE_PASSWORD    # Certificate password
```

#### ⚙️ App Configuration (Optional)
```
APP_BUNDLE_ID_PREFIX            # Bundle ID prefix (default: com.r2midi)
APP_DISPLAY_NAME_SERVER         # Server app name (default: R2MIDI Server)
APP_DISPLAY_NAME_CLIENT         # Client app name (default: R2MIDI Client)
APP_AUTHOR_NAME                 # Author name
APP_AUTHOR_EMAIL                # Author email
```

#### 🏪 Mac App Store (Required for App Store submission)
```
APPLE_APP_STORE_CERTIFICATE_P12     # Base64 Mac App Store certificate
APPLE_APP_STORE_CERTIFICATE_PASSWORD # Certificate password
APP_STORE_CONNECT_API_KEY           # Base64 encoded .p8 API key file
APP_STORE_CONNECT_KEY_ID            # API Key ID from App Store Connect
APP_STORE_CONNECT_ISSUER_ID         # Issuer ID from App Store Connect
```

#### 🏪 App Store Options (Optional)
```
ENABLE_APP_STORE_BUILD          # Enable App Store packages
ENABLE_APP_STORE_SUBMISSION     # Enable automatic App Store submission
ENABLE_NOTARIZATION             # Enable macOS notarization
```

### Environment Protection

- **Development**: Basic secret access for development signing
- **Production**: Full secret access with additional protection for direct distribution
- **App Store**: Dedicated environment with App Store Connect API access
- **PyPI Publishing**: Dedicated environment with publishing permissions

## 🏪 Mac App Store Integration

The workflow now includes **automatic App Store submission** for seamless distribution through the Mac App Store.

### App Store Submission Process

**Automatic Flow**:
1. **Build Phase**: Creates App Store compatible builds with proper certificates
2. **Signing Phase**: Signs with "3rd Party Mac Developer Application" certificates
3. **Packaging Phase**: Creates .pkg installer files
4. **Submission Phase**: Automatically uploads to App Store Connect via API
5. **Confirmation**: Provides submission status and next steps

### App Store vs Direct Distribution

| Aspect | Direct Distribution | App Store |
|--------|-------------------|----------|
| **Certificates** | Developer ID Application | 3rd Party Mac Developer Application |
| **Sandboxing** | Optional (app-sandbox: false) | Required (app-sandbox: true) |
| **Distribution** | Direct download, GitHub releases | Mac App Store only |
| **Review Process** | None | Apple review required |
| **Updates** | Manual user download | Automatic via App Store |
| **Discoverability** | Manual marketing | App Store search & featured |

### Setting Up App Store Submission

1. **Get App Store Certificates**:
   ```bash
   # Check current certificates
   python scripts/certificate_manager.py check
   
   # Follow download guide if missing
   python scripts/certificate_manager.py guide
   ```

2. **Create App Store Connect API Key**:
   - Go to [App Store Connect API](https://appstoreconnect.apple.com/access/api)
   - Create new API key with "Developer" role or higher
   - Download the .p8 file and note Key ID and Issuer ID

3. **Configure Secrets**:
   ```bash
   # Interactive setup
   python scripts/setup_github_secrets.py
   ```

4. **Required Secrets for App Store**:
   ```
   APPLE_APP_STORE_CERTIFICATE_P12     # Mac App Store certificate
   APPLE_APP_STORE_CERTIFICATE_PASSWORD # Certificate password
   APP_STORE_CONNECT_API_KEY           # Base64 .p8 API key
   APP_STORE_CONNECT_KEY_ID            # API Key ID
   APP_STORE_CONNECT_ISSUER_ID         # Issuer UUID
   ENABLE_APP_STORE_SUBMISSION=true    # Enable auto submission
   ```

### App Store Workflow Behavior

**When App Store is Configured**:
- ✅ Creates both direct distribution AND App Store builds
- ✅ Automatically submits to App Store Connect
- ✅ Includes App Store status in release notes
- ✅ Provides App Store Connect links

**When App Store is NOT Configured**:
- ✅ Creates only direct distribution builds
- ⚠️ Shows "App Store submission disabled" in release notes
- 📄 Provides setup instructions in release notes

### After Submission

1. **Check App Store Connect**:
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Review your app's processing status
   - Complete app metadata (descriptions, screenshots, etc.)

2. **Submit for Review**:
   - Once processing completes, submit for Apple review
   - Review typically takes 24-48 hours
   - Address any feedback from Apple

3. **Release**:
   - Once approved, set release date
   - App becomes available on Mac App Store
   - Users get automatic updates

### Troubleshooting App Store Submission

**Common Issues**:

- **"No App Store certificates found"**
  - Download "3rd Party Mac Developer Application" certificate
  - Install in Keychain and export with setup script

- **"API submission failed"**
  - Verify App Store Connect API key permissions
  - Ensure API key has "Developer" role or higher
  - Check Key ID and Issuer ID are correct

- **"App rejected during processing"**
  - Review App Store Connect processing logs
  - Common issues: missing entitlements, sandboxing violations
  - Check that app follows App Store guidelines

- **"Submission disabled"**
  - Set `ENABLE_APP_STORE_SUBMISSION=true` in repository secrets
  - Ensure all required App Store secrets are configured

## 🔒 Security for Open Source Projects

**This project is 100% safe for open source distribution.** All workflows have been audited to ensure no secrets, passwords, or sensitive information can be exposed.

### Security Measures Implemented

✅ **Complete secret masking** - All sensitive values are masked in logs
✅ **Output suppression** - Certificate and signing commands suppress sensitive output
✅ **No hardcoded secrets** - All sensitive data comes from GitHub repository secrets
✅ **Secure error handling** - Failures don't expose credential details
✅ **Temporary file cleanup** - Certificate files are securely deleted
✅ **Environment protection** - Production secrets require approval

For detailed security information, see [SECURITY_AUDIT.md](SECURITY_AUDIT.md).

### Safe vs Sensitive Information

**Safe to expose** (visible in public workflows):
- Bundle ID prefixes (com.yourcompany)
- App display names (R2MIDI Server)
- Author names and public emails
- Version numbers and build status
- Platform names and emojis

**Protected** (never exposed in logs):
- Certificate passwords and .p12 contents
- Apple ID passwords and Team IDs
- App Store Connect API keys
- Windows signing certificates
- All authentication credentials

## 🚀 Usage Guide

### For Developers

1. **Feature Development**:
   ```bash
   # Work on feature branch - triggers dev.yml
   git checkout -b feature/new-feature
   git push origin feature/new-feature
   ```

2. **Pull Request Testing**:
   ```bash
   # PR to develop/master - triggers dev.yml (tests only)
   gh pr create --base develop --title "Add new feature"
   ```

3. **Manual Development Builds**:
   - Go to **Actions** → **Development Builds**
   - Click **Run workflow**
   - Select branch and run

### For Release Management

1. **Staging Release**:
   ```bash
   # Merge to master - triggers build.yml
   git checkout master
   git merge develop
   git push origin master
   ```
   → Automatic PyPI publishing + staging release

2. **Production Release**:
   - **Automatic** after successful staging build
   - Runs `release.yml` if signing certificates available
   - Creates final signed release
   - **Automatically submits to Mac App Store** (if configured)

### For First-Time Setup

1. **Certificate Setup**:
   ```bash
   # Interactive setup helper
   python scripts/setup_github_secrets.py
   
   # Check available certificates
   python scripts/certificate_manager.py check
   
   # Export certificates for GitHub
   python scripts/certificate_manager.py export
   ```

2. **Configure Repository Secrets**:
   - Follow output from setup script
   - Add secrets to GitHub repository
   - Test with a development build

## 📊 Monitoring & Debugging

### Status Indicators

Each workflow provides comprehensive status summaries:

- ✅ **Success**: All builds completed successfully
- ⚠️ **Warning**: Partial success (some platforms skipped)
- ❌ **Failure**: Build errors or test failures
- ⏸️ **Skipped**: Triggered but conditions not met

### Common Issues

**Problem**: macOS builds fail in development
- **Cause**: No signing certificates configured
- **Solution**: Run `python scripts/setup_github_secrets.py` or skip macOS in dev

**Problem**: Windows security warnings
- **Cause**: Unsigned development/staging builds
- **Solution**: Expected behavior, use signed production builds

**Problem**: Production workflow doesn't trigger
- **Cause**: No signing certificates available
- **Solution**: Configure `APPLE_CERTIFICATE_P12` secret

**Problem**: App Store submission fails
- **Cause**: Missing App Store Connect API key or certificates
- **Solution**: Configure `APP_STORE_CONNECT_API_KEY` and `APPLE_APP_STORE_CERTIFICATE_P12`

**Problem**: App Store builds created but not submitted
- **Cause**: `ENABLE_APP_STORE_SUBMISSION` not set to `true`
- **Solution**: Add `ENABLE_APP_STORE_SUBMISSION=true` to repository secrets

**Problem**: PyPI publishing fails
- **Cause**: Authentication or version conflict
- **Solution**: Check PyPI trusted publishing configuration

### Debugging Commands

```bash
# Check workflow status
gh workflow list
gh run list --workflow="Development Builds"

# Download artifacts locally
gh run download 1234567890

# View workflow logs
gh run view 1234567890 --log

# Check certificate status (macOS)
python scripts/certificate_manager.py check

# Test Briefcase builds locally
briefcase create macOS app -a server
briefcase build macOS app -a server
```

## 🔄 Version Management

### Automatic Versioning

- **Development**: `{version}-dev.{branch}.{commit}` (e.g., `0.1.64-dev.feature-ui.a1b2c3d4`)
- **Pull Requests**: `{version}-pr{number}.{commit}` (e.g., `0.1.64-pr123.a1b2c3d4`)
- **Production**: Semantic version from `server/version.py` (e.g., `0.1.64`)

### Manual Version Updates

```bash
# Update version in server/version.py
echo '__version__ = "0.2.0"' > server/version.py

# Update pyproject.toml
sed -i 's/version = "0.1.64"/version = "0.2.0"/' pyproject.toml

# Commit and push to trigger builds
git add server/version.py pyproject.toml
git commit -m "Bump version to 0.2.0"
git push origin master
```

## 🛠️ Customization

### Adding New Platforms

1. **Update workflow matrices** in all three files
2. **Add platform-specific dependencies** in workflow steps
3. **Configure Briefcase** in `pyproject.toml`
4. **Test locally** before committing

### Custom Build Steps

1. **Development tweaks**: Modify `dev.yml`
2. **Production features**: Modify `release.yml`
3. **App Store submission**: Modify the `app-store-submission` job in `release.yml`
4. **Testing changes**: Modify `build.yml`

### Environment Customization

Add secrets for different environments:
```
STAGING_API_KEY
PRODUCTION_API_KEY
CUSTOM_BUILD_FLAGS
APP_STORE_METADATA_PATH         # Custom App Store metadata
APP_STORE_SCREENSHOTS_PATH      # Custom screenshot directory
```

## 📚 References

### Core Technologies
- [Briefcase Documentation](https://briefcase.readthedocs.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [PyPI Trusted Publishing](https://docs.pypi.org/trusted-publishers/github-actions/)

### Apple Development
- [Apple Code Signing Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [macOS App Sandboxing](https://developer.apple.com/documentation/security/app_sandbox)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

### App Store Resources
- [App Store Connect Portal](https://appstoreconnect.apple.com)
- [App Store Connect API Keys](https://appstoreconnect.apple.com/access/api)
- [TestFlight for macOS](https://developer.apple.com/testflight/)
- [App Store Marketing Guidelines](https://developer.apple.com/app-store/marketing/guidelines/)

## 🆘 Support

For workflow issues:

1. **Check the workflow documentation** (this file)
2. **Review workflow logs** in GitHub Actions
3. **Test locally** with Briefcase commands
4. **Use helper scripts** for certificate management
5. **Create an issue** with workflow logs and error details

---

*Last updated: June 2025*
*Workflow version: 3.1 (Three-stage architecture with App Store integration)*
