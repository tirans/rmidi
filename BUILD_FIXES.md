# Build Fixes Documentation

This document describes the fixes applied to resolve the three build failures in the r2midi project.

## 1. Windows Icon Generation Error Fix

**Problem**: The Windows build was failing with a UnicodeEncodeError when trying to print the checkmark symbol (√) due to Windows console using cp1252 encoding.

**Solution**: Modified `scripts/generate_icons.py` to:
- Replace Unicode symbols with ASCII-safe alternatives ([OK], [ERROR], [WARN])
- Add proper encoding handling with fallback to ASCII
- Set stdout to UTF-8 mode on Windows when possible

**Changes**:
- Replaced `√` with `[OK]` for Windows
- Added try-except block for encoding errors
- Added UTF-8 encoding configuration for Windows console

## 2. PyPI Publishing Error Fix

**Problem**: The GitHub Actions workflow was missing the required `id-token: write` permission for OIDC trusted publishing.

**Solution**: Added the missing permission to the `publish-pypi` job in `.github/workflows/release.yml`.

**Changes**:
```yaml
permissions:
  id-token: write  # Required for OIDC trusted publishing
```

**Note**: You have two options for PyPI publishing:
1. Keep using the API token (current setup) - ensure `PYPI_API_TOKEN` secret is set
2. Switch to trusted publishing - remove the `password` parameter and configure PyPI project settings

## 3. macOS Notarization Error Fix

**Problem**: The build was failing during notarization because credentials weren't being properly passed to briefcase.

**Solution**: Updated `.github/actions/package-apps/action.yml` to:
- Use `--identity` flag to specify signing identity directly
- Add `--notarize-app` flag when notarization profile is available
- Remove interactive prompts (echo "3") that were causing issues

**Changes**:
- Added proper command-line arguments for briefcase
- Added conditional logic to check for notarization profile
- Improved error handling and messaging

## Verification Steps

### 1. Test Windows Build Locally
```bash
# On Windows
python scripts/generate_icons.py
```

### 2. Verify GitHub Secrets
Ensure these secrets are set in your GitHub repository:
- `PYPI_API_TOKEN` - for PyPI publishing
- `APPLE_CERTIFICATE_P12` - base64 encoded Developer ID certificate
- `APPLE_CERTIFICATE_PASSWORD` - certificate password
- `APPLE_ID` - Apple ID for notarization
- `APPLE_ID_PASSWORD` - app-specific password
- `APPLE_TEAM_ID` - Apple Team ID
- `APP_STORE_CONNECT_API_KEY` - (recommended) API key for notarization
- `APP_STORE_CONNECT_KEY_ID` - (recommended) API key ID
- `APP_STORE_CONNECT_ISSUER_ID` - (recommended) Issuer ID

### 3. App Store Connect API (Recommended for macOS)
Using App Store Connect API is more reliable than Apple ID/password:

1. Create an API key at https://appstoreconnect.apple.com/access/api
2. Download the .p8 file
3. Base64 encode it: `base64 -i AuthKey_XXXXXXXXXX.p8`
4. Add as GitHub secrets:
   - `APP_STORE_CONNECT_API_KEY` - the base64 encoded content
   - `APP_STORE_CONNECT_KEY_ID` - the key ID (XXXXXXXXXX part)
   - `APP_STORE_CONNECT_ISSUER_ID` - your issuer ID

## Troubleshooting

### Windows Build Still Fails
If the Windows build still has encoding issues:
1. Check the GitHub Actions runner logs
2. Ensure Python 3.12 is being used
3. Try running with `PYTHONIOENCODING=utf-8` environment variable

### PyPI Publishing Fails
If PyPI publishing still fails:
1. Check if you're using trusted publishing or API token
2. For trusted publishing, configure it in PyPI project settings
3. For API token, ensure the token has upload permissions

### macOS Notarization Fails
If notarization still fails:
1. Verify all Apple credentials are correct
2. Check if the Apple Developer account is in good standing
3. Consider using App Store Connect API instead of Apple ID/password
4. Check briefcase logs for specific error messages

## Additional Notes

- The fixes are designed to be backward compatible
- No changes to passing build steps were made
- All platform-specific code is properly conditioned
- Error messages are more descriptive for easier debugging

## References

- [Briefcase Documentation](https://briefcase.readthedocs.io/)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Apple Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
