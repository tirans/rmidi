# R2MIDI MIDI Presets Management

This document explains how the `server/midi-presets` directory is managed in the R2MIDI project.

## Overview

The R2MIDI server automatically manages the [midi-presets](https://github.com/tirans/midi-presets.git) repository. For most users, no manual setup is required as the server will automatically clone the repository on startup if it doesn't exist.

The server has two modes for managing the midi-presets repository:
1. **Clone mode** (default): The server automatically clones the repository if it doesn't exist, or pulls the latest changes if it does.
2. **Submodule mode** (for developers): The server uses the Git submodule if it exists, which is useful for development environments.

## Automatic Management (For Most Users)

For most users, no manual setup is required. The server will automatically:

1. Check if the `server/midi-presets` directory exists
2. If it doesn't exist, clone the repository from https://github.com/tirans/midi-presets.git
3. If it exists, pull the latest changes

This happens automatically when the server starts, so you don't need to do anything special.

## Setting Up the Submodule (For Developers Only)

Developers who want to contribute to both the R2MIDI project and the midi-presets repository may prefer to use the submodule mode. To enable this mode:

1. Set the environment variable `R2MIDI_ROLE` to `dev`:
   ```bash
   export R2MIDI_ROLE=dev
   ```

2. Clone the R2MIDI repository (if you haven't already):
   ```bash
   git clone https://github.com/tirans/r2midi.git
   cd r2midi
   ```

3. Run the provided script to set up the submodule:
   ```bash
   ./fix_git_submodule.sh
   ```

   This script will:
   - Remove any existing submodule configuration
   - Add the submodule at the correct location
   - Initialize the submodule
   - Check out the main branch of the submodule

4. Verify that the submodule was set up correctly:
   ```bash
   git submodule status
   ```

   You should see something like:
   ```
   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx server/midi-presets (main)
   ```

## Manual Submodule Setup (For Developers Only)

If you prefer to set up the submodule manually instead of using the provided script, you can use the following commands:

1. First, ensure you've set the environment variable to use developer mode:
   ```bash
   export R2MIDI_ROLE=dev
   ```

2. Remove any existing submodule configuration:
   ```bash
   git submodule deinit -f server/midi-presets 2>/dev/null || true
   rm -rf .git/modules/server/midi-presets 2>/dev/null || true
   git rm -rf server/midi-presets 2>/dev/null || true
   ```

3. Add the submodule:
   ```bash
   git submodule add https://github.com/tirans/midi-presets.git server/midi-presets
   ```

4. Initialize and update the submodule:
   ```bash
   git submodule init
   git submodule update
   ```

5. Check out the main branch of the submodule:
   ```bash
   cd server/midi-presets
   git fetch origin
   git checkout main
   git pull origin main
   cd ../..
   ```

## Updating the MIDI Presets

### In Clone Mode (Default)

In the default clone mode, the server will automatically pull the latest changes from the midi-presets repository when it starts. You can also manually trigger a sync through the API:

```bash
curl http://localhost:7777/git/sync?sync_enabled=true
```

### In Submodule Mode (For Developers)

If you're using the submodule mode (with `R2MIDI_ROLE=dev`), you can update the submodule to the latest version:

```bash
git submodule update --remote server/midi-presets
cd server/midi-presets
git checkout main
git pull origin main
cd ../..
git add server/midi-presets
git commit -m "Update midi-presets submodule to latest version"
```

## Switching Between Modes

### From Clone to Submodule Mode

1. Set the environment variable:
   ```bash
   export R2MIDI_ROLE=dev
   ```

2. Run the fix script:
   ```bash
   ./fix_git_submodule.sh
   ```

### From Submodule to Clone Mode

1. Remove the submodule:
   ```bash
   ./remove-submodule.sh
   ```

2. Set the environment variable (or remove it to use the default):
   ```bash
   unset R2MIDI_ROLE
   # or
   export R2MIDI_ROLE=release
   ```

3. Start the server, which will automatically clone the repository

## Build Process and GitHub Actions

The build process has been configured to exclude the `server/midi-presets` directory from the built artifacts/packages. This is achieved through:

1. Modifications to the `pyproject.toml` file to exclude the directory from Briefcase builds:
   ```toml
   [tool.briefcase.app.server]
   # ...
   excludes = [
       "server/midi-presets",
       "server/logs",
   ]
   ```

2. Modifications to the build scripts to exclude the directory when copying files.

This ensures that the submodule is available in the development environment but not included in the built artifacts/packages.

## Troubleshooting

### Clone Mode Issues

If you encounter issues with the automatic cloning:

1. Check the server logs for error messages.
2. Ensure you have internet access to reach GitHub.
3. Try manually cloning the repository:
   ```bash
   rm -rf server/midi-presets
   git clone https://github.com/tirans/midi-presets.git server/midi-presets
   ```
4. If you still have issues, you can try the API endpoint:
   ```bash
   curl http://localhost:7777/git/sync?sync_enabled=true
   ```

### Submodule Mode Issues

If you encounter issues with the submodule (in developer mode):

1. Make sure you have the latest version of Git installed.
2. Ensure the `R2MIDI_ROLE` environment variable is set to `dev`.
3. Try running the `fix_git_submodule.sh` script again.
4. If the script fails, try the manual setup steps.
5. If you still have issues, you can remove the submodule completely using the `cleanup-submodules.sh` script and then try setting it up again.
