# CI Skip Options

This document explains the simple skip mechanisms available for bypassing pytest and code quality checks while keeping all the code intact.

## 🎯 **Skip Methods Available**

### **Method 1: Manual Workflow Dispatch (GUI)**
1. Go to **Actions** tab in GitHub
2. Click **CI** workflow
3. Click **Run workflow** 
4. Choose options:
   - ☑️ **Skip pytest execution** - Skips all tests
   - ☑️ **Skip code quality checks** - Skips lint/formatting
5. Click **Run workflow**

### **Method 2: Commit Message Tags**
Add these tags anywhere in your commit message:

**Skip Tests:**
```bash
git commit -m "Quick fix [skip tests]"
```

**Skip Code Quality:**
```bash
git commit -m "WIP changes [skip lint]"
```

**Skip Both:**
```bash
git commit -m "Fast deploy [skip tests] [skip lint]"
```

## 📋 **What Gets Skipped**

### **Skip Tests (`[skip tests]`)**
- ❌ Python unit tests across all platforms (Ubuntu, Windows, macOS)
- ❌ Coverage reporting
- ❌ PyQt6 tests
- ✅ Security scans still run
- ✅ Build tests still run
- ✅ Code quality still runs (unless also skipped)

### **Skip Code Quality (`[skip lint]`)**
- ❌ Black code formatting checks
- ❌ isort import sorting checks
- ❌ flake8 linting
- ❌ mypy type checking
- ✅ Tests still run (unless also skipped)
- ✅ Security scans still run
- ✅ Build tests still run

## 🔄 **Job Dependencies**

The CI workflow has these jobs:
- **test** - Can be skipped
- **lint** - Can be skipped  
- **security** - Always runs
- **build-test** - Always runs
- **summary** - Always runs, shows skip status

## 📊 **Summary Reports**

When jobs are skipped, the CI summary will show:
- ⏭️ **Tests**: Skipped (manual skip or [skip tests] in commit message)
- ⏭️ **Code Quality**: Skipped (manual skip or [skip lint] in commit message)

Skipped jobs are considered "OK" for overall merge status.

## 🚀 **Quick Examples**

**Deploy without running tests:**
```bash
git add .
git commit -m "Hotfix: Critical bug repair [skip tests]"
git push
```

**Work in progress (skip everything):**
```bash
git add .
git commit -m "WIP: Refactoring code [skip tests] [skip lint]"
git push
```

**Skip only linting for quick iteration:**
```bash
git add .
git commit -m "Adding new feature [skip lint]"
git push
```

## ⚙️ **Technical Details**

### Skip Conditions
```yaml
# Test job condition
if: ${{ !inputs.skip_tests && !contains(github.event.head_commit.message, '[skip tests]') }}

# Lint job condition  
if: ${{ !inputs.skip_lint && !contains(github.event.head_commit.message, '[skip lint]') }}
```

### Workflow Inputs
```yaml
inputs:
  skip_tests:
    description: 'Skip pytest execution'
    type: boolean
    default: false
  skip_lint:
    description: 'Skip code quality checks'  
    type: boolean
    default: false
```

## 💡 **Best Practices**

- 🎯 **Use sparingly** - Skips should be for urgent fixes or WIP branches
- 🔍 **Run locally first** - Use `python test_qt_local.py` before skipping CI tests
- 📝 **Clear commit messages** - Explain why you're skipping checks
- 🔄 **Re-enable for final commits** - Don't skip on production merges

## 🛠️ **All Code Remains Intact**

The skip mechanism only affects **when** jobs run, not the code itself:
- ✅ All PyQt6 CI configuration preserved
- ✅ All test code remains functional
- ✅ All lint configurations stay active
- ✅ Re-enabling skips works immediately

**This gives you flexibility for development while maintaining code quality standards!** 🎉
