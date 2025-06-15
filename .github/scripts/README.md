# R2MIDI GitHub Actions Scripts

Centralized shell scripts for building, testing, and deploying R2MIDI applications across all platforms.

## 📁 Script Categories

### 🔧 Setup and Environment
| Script | Purpose | Usage |
|--------|---------|--------|
| `setup-environment.sh` | Configure build environment, Git, PYTHONPATH | `./setup-environment.sh` |
| `setup-scripts.sh` | Make all scripts executable | `./setup-scripts.sh` |
| `make-scripts-executable.sh` | Utility to fix script permissions | `./make-scripts-executable.sh` |

### 📦 Dependency Management
| Script | Purpose | Usage |
|--------|---------|--------|
| `install-system-dependencies.sh` | Install platform-specific system packages | `./install-system-dependencies.sh <platform>` |
| `install-python-dependencies.sh` | Install Python packages by build type | `./install-python-dependencies.sh <build_type>` |

### 🏗️ Building
| Script | Purpose | Usage |
|--------|---------|--------|
| `build-briefcase-apps.sh` | Build applications using Briefcase | `./build-briefcase-apps.sh <platform> <signing_mode>` |
| `build-python-package.sh` | Build Python package for PyPI | `./build-python-package.sh` |

### 📱 Platform Packaging
| Script | Purpose | Usage |
|--------|---------|--------|
| `package-macos-apps.sh` | Create macOS DMG/PKG installers | `./package-macos-apps.sh <version> <build_type>` |
| `package-linux-apps.sh` | Create Linux packages (DEB/TAR.GZ/AppImage) | `./package-linux-apps.sh <version> <build_type>` |
| `package-windows-apps.sh` | Create Windows packages (ZIP/MSI) | `./package-windows-apps.sh <version> <build_type>` |

### 🔐 Code Signing
| Script | Purpose | Usage |
|--------|---------|--------|
| `sign-and-notarize-macos.sh` | Sign and notarize macOS applications | `./sign-and-notarize-macos.sh <version> <build_type> <apple_id> <password> <team_id>` |

### 📊 Version and Metadata
| Script | Purpose | Usage |
|--------|---------|--------|
| `extract-version.sh` | Extract version and set GitHub outputs | `./extract-version.sh [version_override]` |
| `update-version.sh` | Update version across project files | `./update-version.sh <version_type>` |
| `generate-build-summary.sh` | Generate build summaries for GitHub | `./generate-build-summary.sh <platform> <build_type> [version] [signing]` |

### ✅ Validation
| Script | Purpose | Usage |
|--------|---------|--------|
| `validate-build-environment.sh` | Validate build environment setup | `./validate-build-environment.sh <platform>` |
| `validate-project-structure.sh` | Validate project file structure | `./validate-project-structure.sh` |
| `validate-refactoring.sh` | Validate workflow refactoring | `./validate-refactoring.sh` |

### 🚀 Release Management
| Script | Purpose | Usage |
|--------|---------|--------|
| `prepare-release-artifacts.sh` | Organize release artifacts | `./prepare-release-artifacts.sh <version>` |

## 🎯 Quick Reference

### Common Workflows

#### Development Setup
```bash
./setup-environment.sh
./install-system-dependencies.sh linux
./install-python-dependencies.sh development
```

#### Local Build Testing
```bash
./validate-build-environment.sh linux
./build-briefcase-apps.sh linux unsigned
./package-linux-apps.sh 1.0.0 dev
```

#### macOS Release Build
```bash
./install-system-dependencies.sh macos
./install-python-dependencies.sh production
./build-briefcase-apps.sh macos signed
./sign-and-notarize-macos.sh 1.0.0 production $APPLE_ID $APPLE_PASSWORD $TEAM_ID
./package-macos-apps.sh 1.0.0 production
```

#### Python Package Release
```bash
./install-python-dependencies.sh package
./build-python-package.sh
```

## 📝 Script Parameters

### Platform Values
- `linux` - Linux distributions (Ubuntu, Debian, etc.)
- `macos` - macOS (Darwin)
- `windows` - Windows

### Build Types
- `production` - Full production dependencies
- `development` - Development tools + production deps
- `testing` - Minimal testing dependencies
- `ci` - All CI/CD tools including security scanners
- `package` - Only packaging tools

### Signing Modes
- `signed` - Code signed (macOS only)
- `unsigned` - No code signing

### Version Types
- `major` - Increment major version (x.0.0)
- `minor` - Increment minor version (x.y.0) 
- `patch` - Increment patch version (x.y.z)
- `none` - No version change

## 🔍 Script Standards

All scripts follow these conventions:

### Safety
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

### Error Handling
- Proper exit codes (0 = success, non-zero = error)
- Descriptive error messages
- Graceful degradation where possible

### Logging
- Emoji prefixes for readability (🔧 🍎 🐧 🪟 ✅ ❌)
- Consistent output format
- Progress indicators for long operations

### Documentation
- Usage comments at the top
- Parameter descriptions
- Example usage

## 🛠️ Development Guidelines

### Adding New Scripts
1. Use the standard template:
```bash
#!/bin/bash
set -euo pipefail

# Description of what the script does
# Usage: script-name.sh <required_param> [optional_param]

PARAM="${1:-default_value}"
echo "🔧 Starting operation..."

# Script logic here

echo "✅ Operation complete!"
```

2. Make executable: `chmod +x script-name.sh`
3. Test locally before committing
4. Update this README

### Modifying Existing Scripts
1. Test changes locally first
2. Maintain backward compatibility
3. Update documentation if parameters change
4. Run `validate-refactoring.sh` to verify

### Testing Scripts
```bash
# Syntax check
bash -n script-name.sh

# Dry run (if supported)
./script-name.sh --dry-run

# Full validation
./validate-refactoring.sh
```

## 🔧 Troubleshooting

### Common Issues

#### Permission Denied
```bash
./make-scripts-executable.sh
```

#### Script Not Found
```bash
# Check if you're in the project root
pwd
ls .github/scripts/
```

#### Environment Issues
```bash
./validate-build-environment.sh $(uname -s | tr '[:upper:]' '[:lower:]')
```

#### Version Extraction Fails
```bash
# Check if server/version.py exists and has correct format
grep '__version__' server/version.py
```

### Debug Mode
Most scripts support verbose output:
```bash
bash -x ./script-name.sh  # Trace execution
```

## 📊 Dependencies

### System Requirements
- **Bash** 4.0+ (for associative arrays)
- **Git** (for version management)
- **Python** 3.9+ (for builds)

### Platform Tools
- **Linux**: apt/yum/pacman package managers
- **macOS**: Xcode Command Line Tools, optional Homebrew
- **Windows**: No additional requirements

## 🧹 Cleanup and Maintenance

### Recent Cleanup (December 2024)
Removed redundant scripts that were not used in any workflows:
- `setup-clean-workflows.sh` - Redundant setup functionality
- `setup-workflows.sh` - Duplicate of above
- `setup-scripts.sh` - Functionality covered by `make-scripts-executable.sh`

### Manual Cleanup Commands
```bash
# Remove any remaining redundant files
rm -f .github/scripts/*.backup
rm -f .github/scripts/setup-clean-workflows.sh
rm -f .github/scripts/setup-workflows.sh
```

### Script Categories
- **Production Scripts (15)**: Used directly in GitHub Actions workflows
- **Utility Scripts (4)**: For development, testing, and maintenance
- **Documentation (1)**: This README file

## 📚 References

- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [GitHub Actions Scripts](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions)
- [Briefcase Documentation](https://briefcase.readthedocs.io/)

---

*Scripts version: 4.0 (Cleaned and optimized)*  
*Total scripts: 19 (15 production + 4 utility)*  
*Last updated: December 2024*
