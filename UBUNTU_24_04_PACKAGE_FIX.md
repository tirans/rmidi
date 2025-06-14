# Ubuntu 24.04 Package Compatibility Fix

## 🐛 **Issue Identified**

The CI was failing with this error:
```
Package libgl1-mesa-glx is not available, but is referred to by another package.
This may mean that the package is missing, has been obsoleted, or
is only available from another source

E: Package 'libgl1-mesa-glx' has no installation candidate
```

## 🔍 **Root Cause**

- **Problem**: `libgl1-mesa-glx` package has been **obsoleted in Ubuntu 24.04 (Noble)**
- **Context**: GitHub Actions `ubuntu-latest` now uses Ubuntu 24.04
- **Impact**: CI builds were failing during system dependency installation

## ✅ **Solution Applied**

### Package Replacement
**Old (obsolete):** `libgl1-mesa-glx`  
**New (compatible):** `libgl1-mesa-dri`

### Files Updated
1. **`.github/workflows/ci.yml`** - Test job system dependencies
2. **`.github/workflows/ci.yml`** - Build-test job system dependencies

### Updated Package List
```bash
sudo apt-get install -y \
  libasound2-dev \
  portaudio19-dev \
  build-essential \
  pkg-config \
  libegl1-mesa-dev \
  libgl1-mesa-dri \        # ← Fixed: was libgl1-mesa-glx
  libglib2.0-0 \
  libxkbcommon-x11-0 \
  libxcb-icccm4 \
  libxcb-image0 \
  libxcb-keysyms1 \
  libxcb-randr0 \
  libxcb-render-util0 \
  libxcb-xinerama0 \
  libxcb-xfixes0 \
  xvfb
```

## 🧪 **Technical Details**

### Ubuntu Package Evolution
- **Ubuntu 20.04/22.04**: `libgl1-mesa-glx` available
- **Ubuntu 24.04**: `libgl1-mesa-glx` → `libgl1-mesa-dri`
- **Functionality**: Both provide OpenGL libraries for Qt/GUI applications

### PyQt6 Requirements
The `libgl1-mesa-dri` package provides:
- OpenGL library support for PyQt6 rendering
- Hardware acceleration capabilities
- Mesa driver integration
- Compatible with headless (xvfb) environments

## 🚀 **Expected Results**

After this fix, the CI should:
- ✅ Successfully install all system dependencies
- ✅ PyQt6 imports work without `libEGL.so.1` errors
- ✅ Qt tests run properly in headless environment
- ✅ Complete CI pipeline passes on Ubuntu

## 📋 **Verification Commands**

To test locally on Ubuntu 24.04:
```bash
# Check if old package exists (should fail)
apt-cache search libgl1-mesa-glx

# Check if new package exists (should succeed)
apt-cache search libgl1-mesa-dri

# Install new package
sudo apt-get install libgl1-mesa-dri
```

## 🔄 **Backward Compatibility**

This change:
- ✅ **Compatible** with Ubuntu 24.04 (current `ubuntu-latest`)
- ✅ **Compatible** with Ubuntu 22.04 (if needed)
- ✅ **No impact** on Windows/macOS CI jobs
- ✅ **Maintains** all PyQt6 functionality

## 📝 **Related Changes**

This fix complements the previous PyQt6 CI setup:
1. **System dependencies**: Fixed package names for Ubuntu 24.04
2. **Virtual display**: Using `xvfb-run` for headless testing
3. **Test framework**: `pytest-qt` for proper Qt testing
4. **Qt configuration**: Offscreen platform for headless environments

The CI should now work seamlessly with PyQt6 on the latest Ubuntu runner! 🎉
