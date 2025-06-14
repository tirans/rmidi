# GitHub Actions Workflow Reference Fixes

## Summary of Issues Fixed

The GitHub Actions workflows were failing due to incorrect workflow reference syntax. The main issue was using invalid `@ref` syntax for local workflows and missing `./` prefixes.

## Fixes Applied

### 1. Fixed `ci.yml` (Line 174)
**Before:**
```yaml
uses: ./.github/workflows/reusable-build.yml@v1
```

**After:**
```yaml
uses: ./.github/workflows/reusable-build.yml
```

### 2. Fixed `release.yml` (Line 95)
**Before:**
```yaml
uses: .github/workflows/reusable-test.yml@main
```

**After:**
```yaml
uses: ./.github/workflows/reusable-test.yml
```

### 3. Fixed `release.yml` (Line 159)
**Before:**
```yaml
uses: .github/workflows/reusable-build.yml@main
```

**After:**
```yaml
uses: ./.github/workflows/reusable-build.yml
```

## GitHub Actions Reference Rules

### ✅ Correct Syntax

**Local Reusable Workflows:**
```yaml
uses: ./.github/workflows/workflow-name.yml  # NO @ref allowed
```

**Local Custom Actions:**
```yaml
uses: ./.github/actions/action-name
```

**External Workflows/Actions:**
```yaml
uses: owner/repository@ref
uses: owner/repository/path/to/workflow.yml@ref
uses: actions/checkout@v4
```

### ❌ Incorrect Syntax

**Local workflows with @ref (INVALID):**
```yaml
uses: ./.github/workflows/workflow.yml@main    # ❌ Invalid
uses: .github/workflows/workflow.yml@v1        # ❌ Invalid
```

**Local actions without ./ prefix:**
```yaml
uses: .github/actions/action-name              # ❌ Missing ./
```

## Verification

1. **Run the updated verification script:**
   ```bash
   bash verify-workflow-references.sh
   ```

2. **Test the workflows:**
   ```bash
   # Push changes to trigger CI
   git add .github/
   git commit -m "fix: correct GitHub workflow references"
   git push
   ```

3. **Check Actions tab** in GitHub to verify workflows run without reference errors.

## Why These Fixes Work

- **Local workflows** (in the same repository) cannot use `@ref` syntax - they must reference the current repository state
- **Local workflows** must use `./` prefix to indicate they are local to the repository
- **External workflows** require `owner/repo@ref` format to specify which version to use
- GitHub Actions validates these references at runtime and fails with "invalid workflow reference" if the syntax is incorrect

## Expected Outcomes

After these fixes:
1. ✅ No more "invalid workflow reference" errors
2. ✅ No more "references to workflows must be prefixed with format" errors  
3. ✅ CI workflows will run successfully
4. ✅ Release workflows will be able to call reusable workflows
5. ✅ All workflow references will follow GitHub Actions best practices

## Files Modified

1. `.github/workflows/ci.yml` - Fixed reusable workflow reference
2. `.github/workflows/release.yml` - Fixed two reusable workflow references  
3. `verify-workflow-references.sh` - Updated verification logic to catch these issues

The workflows should now run without reference errors. Test by pushing these changes and monitoring the Actions tab for successful execution.
