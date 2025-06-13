# Git Hooks for R2MIDI

This document explains the Git hooks used in the R2MIDI project and how to install them.

## Overview

Git hooks are scripts that Git executes before or after events such as commit, push, and receive. They are useful for enforcing certain policies and workflows.

In the R2MIDI project, we use Git hooks to:

1. Prevent committing the `/server/midi-presets` directory itself
2. Prevent committing files from the `/server/midi-presets` directory (except for `.gitkeep` and `README.md` files)
3. Prevent committing the `.gitmodules` file with references to the midi-presets submodule

This ensures that the midi-presets submodule and its files are not included in the Git repository, which is important for keeping the repository clean and avoiding issues with the build process.

## Available Hooks

### pre-commit

The `pre-commit` hook runs before a commit is created. It checks for three conditions:

1. If the `/server/midi-presets` directory itself is being committed
2. If any files in the staging area are from the `/server/midi-presets` directory (except for `.gitkeep` and `README.md` files)
3. If the `.gitmodules` file contains a reference to the midi-presets submodule

If any of these conditions are true, the commit is prevented.

**Note:** The hook specifically allows committing `.gitkeep` and `README.md` files in the `/server/midi-presets` directory, as these files are needed for the repository structure and documentation.

## Installation

To install the Git hooks, run the following command from the repository root:

```bash
./install-hooks.sh
```

This script will:

1. Make the hooks executable
2. Create symbolic links from `.git/hooks/` to the hooks in the `hooks/` directory

## Manual Installation

If you prefer to install the hooks manually, you can:

1. Make the hooks executable:
   ```bash
   chmod +x hooks/pre-commit
   ```

2. Create a symbolic link to the pre-commit hook:
   ```bash
   ln -sf "$(pwd)/hooks/pre-commit" .git/hooks/pre-commit
   ```

## Troubleshooting

If you encounter issues with the Git hooks:

1. Make sure the hooks are executable:
   ```bash
   chmod +x hooks/pre-commit
   ```

2. Check if the symbolic links are correctly set up:
   ```bash
   ls -la .git/hooks/
   ```

3. Try reinstalling the hooks:
   ```bash
   ./install-hooks.sh
   ```

## Bypassing Hooks

In some cases, you may need to bypass the hooks (e.g., for testing). You can do this by using the `--no-verify` flag with Git commands:

```bash
git commit --no-verify -m "Your commit message"
```

However, this should be used sparingly and only when necessary.
