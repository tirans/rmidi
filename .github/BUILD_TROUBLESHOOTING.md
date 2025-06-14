# Build Troubleshooting Guide

## Common Issues and Solutions

### macOS Build Failures

#### Issue: py2app file copying conflicts
**Error**: `copying file ... failed`
**Solution**: The enhanced build script now includes:
- Pre-build environment cleaning
- Retry mechanisms with exponential backoff
- Site-packages conflict prevention
- Proper resource isolation

#### Issue: Memory or disk space issues
**Error**: Build fails with resource exhaustion
**Solution**: 
- Build script monitors system resources
- Implements cleanup between retry attempts
- Uses optimized py2app settings

### Linux Build Failures

#### Issue: Broken pipe errors
**Error**: `find: 'standard output': Broken pipe`
**Solution**: Enhanced script uses:
- Null-terminated find operations
- Proper process handling
- Timeout mechanisms

### Windows Build Failures

#### Issue: Process termination (exit code 141)
**Error**: Build exits with code 141
**Solution**: Improved script includes:
- UTF-8 encoding setup
- Unbuffered Python output
- Better process management

## Build Quality Checks

The enhanced build system includes:
- ✅ Input validation and normalization
- ✅ Comprehensive error handling
- ✅ Retry mechanisms with intelligent backoff
- ✅ Resource monitoring and cleanup
- ✅ Detailed logging and diagnostics
- ✅ Build artifact validation

## Getting Help

If builds continue to fail after applying these fixes:
1. Check the build logs in `build/artifacts/`
2. Review the error logs generated during failures
3. Ensure all dependencies are properly installed
4. Verify the project structure meets requirements

## Build Script Features

### Enhanced macOS Script (build-macos.sh)
- **Conflict Prevention**: Prevents py2app site-packages conflicts
- **Resource Isolation**: Uses `site_packages: False` for clean builds
- **Retry Logic**: Exponential backoff with cleanup between attempts
- **Resource Monitoring**: Tracks disk space and memory usage
- **Optimized Settings**: Uses compression and stripping for smaller builds

### Enhanced Briefcase Script (build-briefcase.sh)
- **Broken Pipe Prevention**: Uses null-terminated find operations
- **Platform-Specific Cleanup**: Tailored cleanup for Linux/Windows
- **Process Management**: Timeout handling and stale process cleanup
- **Validation**: Project structure and configuration validation
- **Enhanced Logging**: Comprehensive build diagnostics

### Enhanced Build Action (action.yml)
- **Input Validation**: Normalizes and validates all inputs
- **Dependency Management**: Intelligent package installation with retries
- **Build Monitoring**: Real-time progress tracking and error capture
- **Artifact Management**: Comprehensive artifact collection and reporting
- **Cross-Platform**: Unified interface for all build methods

## Validation Commands

Before running builds, you can validate your environment:

```bash
# Validate build environment
.github/scripts/validate-build-environment.sh

# Check project structure
python -c "
import os
required = ['server/main.py', 'r2midi_client/main.py', 'pyproject.toml']
missing = [f for f in required if not os.path.exists(f)]
if missing:
    print(f'Missing: {missing}')
    exit(1)
print('✅ Project structure valid')
"
```

## Performance Optimizations

The enhanced build system includes several performance optimizations:

1. **Parallel Processing**: Where possible, operations are parallelized
2. **Incremental Builds**: Reuses valid artifacts from previous builds
3. **Resource Monitoring**: Prevents builds when resources are insufficient
4. **Smart Caching**: Leverages pip and build tool caches effectively

## Troubleshooting Steps

If you encounter build issues:

1. **Check System Resources**:
   ```bash
   df -h .  # Check disk space
   free -h  # Check memory (Linux)
   ```

2. **Validate Dependencies**:
   ```bash
   pip list | grep -E "(briefcase|py2app|setuptools)"
   ```

3. **Clean Build Environment**:
   ```bash
   rm -rf build/ dist/ *.egg-info
   pip cache purge
   ```

4. **Run with Debug Mode**:
   ```bash
   export BUILD_DEBUG=1
   # Then run your build
   ```

5. **Check Logs**:
   - macOS: Look in `build/artifacts/build-info.txt`
   - Linux/Windows: Check briefcase logs in `build/*/logs/`

## Version Compatibility

These enhanced scripts are tested with:
- Python 3.9+
- py2app 0.28.8
- Briefcase 0.3.21+
- setuptools 65.0+

## Contributing

If you find additional issues or have improvements:
1. Document the issue in detail
2. Test the proposed solution
3. Update this troubleshooting guide
4. Submit changes for review
