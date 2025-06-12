# MIDI Presets Directory

This directory can contain MIDI preset files for the R2MIDI server.

## Usage

Place your MIDI preset files (`.mid`, `.json`, etc.) in this directory.
The server will automatically detect and load them.

## Original Presets

The original MIDI presets were previously managed as a Git submodule.
If you need those presets, you can download them from:
https://github.com/tirans/midi-presets

## Adding Presets

You can add presets in several ways:

1. **Direct copy**: Copy `.mid` files directly into this directory
2. **Download**: Download presets from the original repository
3. **Create**: Create your own preset files

## File Structure

```
server/midi-presets/
├── README.md          # This file
├── .gitkeep          # Ensures directory is tracked by Git
└── your-presets.mid  # Your MIDI preset files
```
