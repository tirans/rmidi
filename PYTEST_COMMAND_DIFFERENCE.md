# Why `pytest` Failed But `python -m pytest -v` Succeeded

## Issue Summary

Previously, running `pytest` directly would fail, while running `python -m pytest -v` would succeed. This document explains the root cause and the solution implemented.

## Root Cause Analysis

The issue was caused by a combination of factors:

1. **Missing pytest-qt dependency**: The project uses PyQt6 for GUI components and requires pytest-qt for testing them. This dependency was:
   - Not included in `setup.py` test extras
   - Not included in `pyproject.toml` test dependencies
   - Missing from `tests/requirements.txt`
   - Had a duplicate pytest entry in `tests/requirements.txt`

2. **Qt backend configuration**: pytest-qt was defaulting to PySide6 instead of PyQt6, causing compatibility issues.

3. **Python path differences**: When running `pytest` directly vs `python -m pytest`:
   - `python -m pytest` runs pytest as a module, which automatically adds the current directory to sys.path
   - `pytest` runs the pytest executable directly, which might handle imports differently

## Solution Implemented

The following changes were made to fix the issue:

1. **Added pytest-qt to all dependency configurations**:
   - Added to `tests/requirements.txt`
   - Added to `setup.py` test extras
   - Added to `pyproject.toml` test dependencies

2. **Removed duplicate pytest entry** from `tests/requirements.txt`

3. **Configured pytest-qt to use PyQt6** by adding to `conftest.py`:
   ```python
   # Force pytest-qt to use PyQt6
   os.environ.setdefault('PYTEST_QT_API', 'pyqt6')
   ```

## Verification

After implementing these changes:
- Both `pytest` and `python -m pytest -v` commands run successfully
- All 83 tests pass with both commands
- The Qt tests using the `qtbot` fixture work correctly

## Best Practices

To avoid similar issues in the future:

1. Keep dependency specifications consistent across:
   - `setup.py`
   - `pyproject.toml`
   - `requirements.txt` files

2. Use explicit configuration for plugins that have multiple backends (like pytest-qt)

3. When adding new test dependencies, add them to all relevant configuration files