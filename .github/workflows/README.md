# R2MIDI GitHub Actions Workflows

A modular, maintainable CI/CD pipeline for building, testing, and distributing R2MIDI applications across all platforms.

## 🏗️ Workflow Architecture

The R2MIDI project uses a **modular workflow system** with reusable components:

```
CI (ci.yml) → For development branches
Release (release.yml) → For production releases
App Store (app-store.yml) → For Mac App Store submissions
```

## 📋 Workflow Details

### 1. CI Workflow (`ci.yml`)

**Purpose**: Continuous integration for development

**Triggers**:
- Push to: `develop`, `feature/*`, `dev/*`, `test/*` branches
- Pull requests to: `master`, `main`, `develop`
- Manual dispatch (`workflow_dispatch`)

**Features**:
- Quick validation and testing
- Development builds with version suffix
- Tests only on PRs (no builds)
- Artifacts retained for 30 days

### 2. Release Workflow (`release.yml`)

**Purpose**: Production releases with full pipeline

**Triggers**:
- Push to: `master` branch
- Manual dispatch with version control

**Features**:
- Configurable version management (major/minor/patch/none)
- Multi-Python version testing (3.10, 3.11, 3.12)
- Automatic PyPI publishing
- Code-signed macOS builds
- GitHub release creation

### 3. App Store Workflow (`app-store.yml`)

**Purpose**: Mac App Store submission

**Triggers**:
- Manual dispatch only

**Features**:
- App Store certificate management
- Optional automatic submission
- Sandboxed builds for App Store
- Package creation (.pkg files)

## 🔧 Reusable Components

### Reusable Workflows
- `reusable-test.yml` - Standardized testing
- `reusable-build.yml` - Cross-platform building

### Composite Actions
Located in `.github/actions/`:
- `install-system-deps` - Platform dependencies
- `setup-macos-signing` - Certificate management
- `configure-build` - Build configuration
- `build-apps` - Application building
- `package-apps` - Artifact packaging
- `cleanup-signing` - Security cleanup

## 🔐 Required Secrets

### Core macOS Signing
```
APPLE_CERTIFICATE_P12        # Base64 Developer ID certificate
APPLE_CERTIFICATE_PASSWORD   # Certificate password
APPLE_ID                     # Apple Developer email
APPLE_ID_PASSWORD            # App-specific password
APPLE_TEAM_ID                # Developer Team ID
```

### App Store (Optional)
```
APPLE_APP_STORE_CERTIFICATE_P12      # Base64 Mac App Store certificate
APPLE_APP_STORE_CERTIFICATE_PASSWORD # Certificate password
APP_STORE_CONNECT_API_KEY            # Base64 .p8 API key
APP_STORE_CONNECT_KEY_ID             # API Key ID
APP_STORE_CONNECT_ISSUER_ID          # Issuer UUID
```

### Application Metadata (Optional)
```
APP_BUNDLE_ID_PREFIX        # Default: com.r2midi
APP_DISPLAY_NAME_SERVER     # Default: R2MIDI Server
APP_DISPLAY_NAME_CLIENT     # Default: R2MIDI Client
APP_AUTHOR_NAME             # Default: R2MIDI Team
APP_AUTHOR_EMAIL            # Default: team@r2midi.org
```

## 🚀 Usage

### Development
```bash
# Feature development
git checkout -b feature/new-feature
git push origin feature/new-feature
# → Triggers CI workflow
```

### Release
```bash
# Production release
git checkout master
git merge develop
git push origin master
# → Triggers Release workflow
```

### App Store
1. Go to Actions → App Store Release
2. Click "Run workflow"
3. Choose whether to auto-submit

## 📊 Build Matrix

| Platform | Development | Production | App Store |
|----------|-------------|------------|-----------|
| Linux    | ✅ Unsigned | ✅ Unsigned | ❌ N/A |
| Windows  | ✅ Unsigned | ✅ Unsigned | ❌ N/A |
| macOS    | ✅ Unsigned | ✅ Signed   | ✅ Signed |

## 🛠️ Customization

### Adding Platforms
1. Update matrix in workflow files
2. Add platform logic to composite actions
3. Update `install-system-deps` action

### Modifying Builds
1. Edit relevant composite actions
2. Test on feature branch
3. Update documentation

## 🔄 Version Management

- **Automatic**: Patch increment on master push
- **Manual**: Choose major/minor/patch/none
- **Format**: `{major}.{minor}.{patch}`

## 📚 References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [Composite Actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)

---

*Workflow version: 4.0 (Modular architecture)*
