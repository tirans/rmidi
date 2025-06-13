# Testing the Git Hooks

This document provides instructions for testing the Git hooks to ensure they work as expected.

## Prerequisites

1. Make sure you have installed the Git hooks:
   ```bash
   ./install-hooks.sh
   ```

2. Verify that the pre-commit hook is installed:
   ```bash
   ls -la .git/hooks/pre-commit
   ```
   You should see a symbolic link to the hook in the hooks directory.

## Test Case 1: Preventing Commits of midi-presets Files

1. Create a test file in the server/midi-presets directory:
   ```bash
   mkdir -p server/midi-presets
   echo "test" > server/midi-presets/test.txt
   ```

2. Try to stage and commit the file:
   ```bash
   git add server/midi-presets/test.txt
   git commit -m "Test commit with midi-presets file"
   ```

3. Expected result:
   - The commit should be prevented
   - You should see an error message explaining that files from the server/midi-presets directory cannot be committed
   - The commit should not be created

## Test Case 2: Preventing Commits of the midi-presets Directory Itself

1. Create the server/midi-presets directory if it doesn't exist:
   ```bash
   mkdir -p server/midi-presets
   ```

2. Try to stage and commit the directory itself:
   ```bash
   git add server/midi-presets
   git commit -m "Test commit with midi-presets directory"
   ```

3. Expected result:
   - The commit should be prevented
   - You should see an error message explaining that the server/midi-presets directory itself cannot be committed
   - The commit should not be created

## Test Case 3: Preventing Commits of .gitmodules with midi-presets References

1. Create or modify the .gitmodules file to include a reference to the midi-presets submodule:
   ```bash
   echo "[submodule \"server/midi-presets\"]
   path = server/midi-presets
   url = https://github.com/tirans/midi-presets.git" > .gitmodules
   ```

2. Try to stage and commit the file:
   ```bash
   git add .gitmodules
   git commit -m "Test commit with .gitmodules file"
   ```

3. Expected result:
   - The commit should be prevented
   - You should see an error message explaining that the .gitmodules file with a reference to server/midi-presets cannot be committed
   - The commit should not be created

## Test Case 4: Allowing Commits of .gitkeep and README.md in midi-presets Directory

1. Create .gitkeep and README.md files in the server/midi-presets directory:
   ```bash
   mkdir -p server/midi-presets
   touch server/midi-presets/.gitkeep
   echo "# MIDI Presets Directory" > server/midi-presets/README.md
   ```

2. Try to stage and commit these files:
   ```bash
   git add server/midi-presets/.gitkeep server/midi-presets/README.md
   git commit -m "Test commit with allowed midi-presets files"
   ```

3. Expected result:
   - The commit should be allowed
   - The commit should be created successfully
   - You should not see any error messages about files from the server/midi-presets directory

## Test Case 5: Allowing Commits of Other Files

1. Create a test file in another directory:
   ```bash
   echo "test" > test.txt
   ```

2. Try to stage and commit the file:
   ```bash
   git add test.txt
   git commit -m "Test commit with other file"
   ```

3. Expected result:
   - The commit should be allowed
   - The commit should be created successfully

## Bypassing the Hook (For Testing Only)

If you need to bypass the hook for testing purposes, you can use the `--no-verify` flag:

```bash
git commit --no-verify -m "Test commit bypassing the hook"
```

This will skip the pre-commit hook and allow the commit to be created.

## Cleanup

After testing, you can clean up the test files:

```bash
rm -f test.txt
rm -rf server/midi-presets/test.txt
rm -f server/midi-presets/.gitkeep
rm -f server/midi-presets/README.md
rm -f .gitmodules
```

## Troubleshooting

If the hook doesn't work as expected:

1. Make sure the hook is executable:
   ```bash
   chmod +x hooks/pre-commit
   ```

2. Make sure the symbolic link is correctly set up:
   ```bash
   ls -la .git/hooks/pre-commit
   ```

3. Try reinstalling the hook:
   ```bash
   ./install-hooks.sh
   ```

4. Check the hook script for errors:
   ```bash
   cat hooks/pre-commit
   ```
