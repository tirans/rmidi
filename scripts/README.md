# R2MIDI Build Scripts

This directory contains scripts used by the GitHub Actions workflows to build and package R2MIDI applications.

## Files Overview

### 🔧 Core Build Scripts

#### `update_pyproject.py`
Updates `pyproject.toml` with build metadata and signing configuration.

**Usage:**
```bash
python scripts/update_pyproject.py \
  --version "1.0.0" \
  --author "Your Name" \
  --author-email "you@example.com" \
  --server-name "R2MIDI Server" \
  --client-name "R2MIDI Client" \
  --bundle-prefix "com.yourcompany" \
  --codesign-identity "Developer ID Application: Your Name (TEAMID)"
```

**For App Store builds:**
```bash
python scripts/update_pyproject.py \
  --app-store \
  --codesign-identity "3rd Party Mac Developer Application: Your Name (TEAMID)" \
  # ... other options
```

#### `generate_icons.py`
Generates application icons in various sizes and formats.

**Usage:**
```bash
python scripts/generate_icons.py
```

Creates icons in `resources/` directory:
- PNG files in various sizes (16x16 to 1024x1024)
- ICO file for Windows
- Platform-specific icon formats

**Requirements:**
```bash
pip install pillow
```

### 🔍 Debug and Validation Scripts

#### `debug_certificates.sh`
Helps troubleshoot macOS code signing certificate issues.

**Usage:**
```bash
# Debug the default briefcase keychain
./scripts/debug_certificates.sh

# Debug a specific keychain
./scripts/debug_certificates.sh my_keychain.keychain
```

**What it checks:**
- Available signing identities
- Certificate parsing methods
- Keychain status and accessibility
- Codesign functionality testing

#### `validate_pyproject.py`
Validates `pyproject.toml` for Briefcase compatibility.

**Usage:**
```bash
python scripts/validate_pyproject.py
```

**What it validates:**
- Required project metadata
- Briefcase configuration sections
- App-specific settings
- Icon file availability

## GitHub Actions Integration

These scripts are automatically used by the GitHub Actions workflows:

### In `build.yml`:
- `generate_icons.py` - Creates icons for all builds
- `update_pyproject.py` - Configures stable build metadata

### In `release.yml`:
- `generate_icons.py` - Creates icons for signed builds
- `update_pyproject.py` - Configures signing and notarization
- `debug_certificates.sh` - (Can be used for troubleshooting)

## Local Development

### Setting Up for Local Builds

1. **Generate icons:**
   ```bash
   python scripts/generate_icons.py
   ```

2. **Validate configuration:**
   ```bash
   python scripts/validate_pyproject.py
   ```

3. **Update pyproject.toml for local build:**
   ```bash
   python scripts/update_pyproject.py \
     --version "dev" \
     --author "Developer" \
     --author-email "dev@localhost"
   ```

### Troubleshooting Code Signing (macOS)

If you're having code signing issues on macOS:

1. **Debug certificates:**
   ```bash
   chmod +x scripts/debug_certificates.sh
   ./scripts/debug_certificates.sh
   ```

2. **Check keychain setup:**
   ```bash
   security list-keychains
   security find-identity -v -p codesigning
   ```

3. **Test signing:**
   ```bash
   echo "test" > test.txt
   codesign -s "Your Developer ID" test.txt
   rm test.txt
   ```

## Script Dependencies

### Python Requirements:
```bash
pip install pillow  # For generate_icons.py
pip install tomli   # For validate_pyproject.py (Python < 3.11)
```

### System Requirements:
- **macOS**: Required for `debug_certificates.sh`
- **All platforms**: Python 3.8+ for Python scripts

## Common Issues and Solutions

### Icon Generation Fails
```bash
pip install --upgrade pillow
```

### Certificate Parsing Issues
Run the debug script to identify the correct parsing method:
```bash
./scripts/debug_certificates.sh
```

### pyproject.toml Validation Errors
Fix missing sections identified by:
```bash
python scripts/validate_pyproject.py
```

## File Permissions

Make sure scripts are executable:
```bash
chmod +x scripts/*.sh
chmod +x scripts/*.py
```

## Contributing

When modifying these scripts:

1. **Test locally** before committing
2. **Update this README** if adding new scripts
3. **Validate with both apps** (server and client)
4. **Test on multiple platforms** when possible

## License

These scripts are part of the R2MIDI project and follow the same license terms.
