# R2MIDI Build Instructions

This document provides instructions for building the R2MIDI server and client applications on macOS, Linux, and Windows.

## Prerequisites

- Python 3.12 or higher
- pip (Python package manager)
- Git (for cloning the repository)

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/tirans/r2midi.git
   cd r2midi
   ```

2. Install Briefcase:
   ```bash
   pip install briefcase
   ```

3. Install project dependencies:
   ```bash
   pip install -r requirements.txt
   pip install -r r2midi_client/requirements.txt
   ```

## Building on macOS

### Server Application

```bash
# Create the application
briefcase create macOS app -a server

# Build the application
briefcase build macOS app -a server

# Package the application (creates a .dmg, .pkg, or .app bundle)
briefcase package macOS app -a server --no-sign
```

### Client Application

```bash
# Create the application
briefcase create macOS app -a r2midi-client

# Build the application
briefcase build macOS app -a r2midi-client

# Package the application (creates a .dmg, .pkg, or .app bundle)
briefcase package macOS app -a r2midi-client --no-sign
```

## Building on Linux

### Server Application

```bash
# Create the application
briefcase create linux app -a server

# Build the application
briefcase build linux app -a server --target system

# Package the application (creates an AppImage or .deb package)
briefcase package linux app -a server
```

### Client Application

```bash
# Create the application
briefcase create linux app -a r2midi-client

# Build the application
briefcase build linux app -a r2midi-client --target system

# Package the application (creates an AppImage or .deb package)
briefcase package linux app -a r2midi-client
```

## Building on Windows

### Server Application

```bash
# Create the application
briefcase create windows app -a server

# Build the application
briefcase build windows app -a server

# Package the application (creates an .msi installer)
briefcase package windows app -a server
```

### Client Application

```bash
# Create the application
briefcase create windows app -a r2midi-client

# Build the application
briefcase build windows app -a r2midi-client

# Package the application (creates an .msi installer)
briefcase package windows app -a r2midi-client
```

## Running the Applications

### Running the Server

```bash
# macOS
briefcase run macOS app -a server

# Linux
briefcase run linux app -a server

# Windows
briefcase run windows app -a server
```

### Running the Client

```bash
# macOS
briefcase run macOS app -a r2midi-client

# Linux
briefcase run linux app -a r2midi-client

# Windows
briefcase run windows app -a r2midi-client
```

## Automated Build Script

You can also use the included `test_briefcase_builds.sh` script to build both applications:

```bash
# For macOS
./test_briefcase_builds.sh macOS

# For Linux
./test_briefcase_builds.sh linux

# For Windows
./test_briefcase_builds.sh windows
```

## Troubleshooting

- If you encounter errors related to missing dependencies, make sure you have installed all required system libraries.
- For Linux builds, you may need additional system packages depending on your distribution.
- For macOS builds, you may need to install Xcode Command Line Tools.
- For Windows builds, you may need to install Visual Studio Build Tools.

## Output Files

The built applications can be found in the following locations:

- macOS: `build/server/macOS/app` and `build/r2midi-client/macOS/app`
- Linux: `build/server/linux/app` and `build/r2midi-client/linux/app`
- Windows: `build/server/windows/app` and `build/r2midi-client/windows/app`

The packaged applications can be found in:

- macOS: Look for `.dmg`, `.pkg` files or `.app` bundles in the build directory
- Linux: Look for `.AppImage` or `.deb` files in the build directory
- Windows: Look for `.msi` or `.exe` files in the build directory
