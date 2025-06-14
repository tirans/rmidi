#!/bin/bash
set -euo pipefail

# Update version numbers across the project
# Usage: update-version.sh <version_type>
# version_type: patch, minor, major, none

VERSION_TYPE="${1:-patch}"

echo "🔄 Updating project version..."
echo "Version Type: $VERSION_TYPE"

# Configure Git
git config --local user.name "GitHub Action"
git config --local user.email "action@github.com"

# Function to get current version from server/version.py
get_current_version() {
    if [ -f "server/version.py" ]; then
        grep -o '__version__ = "[^"]*"' server/version.py | cut -d'"' -f2
    else
        echo "❌ Error: server/version.py not found"
        exit 1
    fi
}

# Function to increment version
increment_version() {
    local current_version="$1"
    local increment_type="$2"
    
    # Parse version parts
    IFS='.' read -r MAJOR MINOR PATCH <<< "$current_version"
    
    case "$increment_type" in
        major)
            NEW_VERSION="$((MAJOR + 1)).0.0"
            ;;
        minor)
            NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
            ;;
        patch)
            NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
            ;;
        none)
            NEW_VERSION="$current_version"
            ;;
        *)
            echo "❌ Error: Invalid version type '$increment_type'"
            echo "Valid types: major, minor, patch, none"
            exit 1
            ;;
    esac
    
    echo "$NEW_VERSION"
}

# Function to update version in a file
update_version_in_file() {
    local file="$1"
    local old_version="$2"
    local new_version="$3"
    local pattern="$4"
    
    if [ -f "$file" ]; then
        echo "📝 Updating version in $file: $old_version -> $new_version"
        
        # Create backup
        cp "$file" "${file}.bak"
        
        # Update version using the specified pattern
        if sed -i.tmp "$pattern" "$file" 2>/dev/null; then
            rm -f "${file}.tmp"
            echo "✅ Updated $file"
        else
            # Restore backup if sed failed
            mv "${file}.bak" "$file"
            echo "❌ Failed to update $file"
            return 1
        fi
        
        # Remove backup
        rm -f "${file}.bak"
    else
        echo "⚠️ Warning: $file not found, skipping"
    fi
}

# Function to update CHANGELOG.md
update_changelog() {
    local new_version="$1"
    local version_type="$2"
    
    if [ -f "CHANGELOG.md" ]; then
        echo "📝 Updating CHANGELOG.md..."
        
        local today=$(date +%Y-%m-%d)
        local temp_file=$(mktemp)
        
        # Create new changelog entry
        cat > "$temp_file" << EOF
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [$new_version] - $today

### Changed
- Version increment: $version_type

EOF
        
        # Append existing content (skip the header)
        if grep -q "## \[Unreleased\]" CHANGELOG.md; then
            sed -n '/## \[Unreleased\]/,$p' CHANGELOG.md | tail -n +2 >> "$temp_file"
        else
            # If no existing unreleased section, append everything after the header
            tail -n +4 CHANGELOG.md >> "$temp_file"
        fi
        
        # Replace the original file
        mv "$temp_file" CHANGELOG.md
        
        echo "✅ Updated CHANGELOG.md"
    else
        echo "📝 Creating CHANGELOG.md..."
        cat > CHANGELOG.md << EOF
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [$new_version] - $(date +%Y-%m-%d)

### Changed
- Version increment: $version_type
- Initial release

EOF
        echo "✅ Created CHANGELOG.md"
    fi
}

# Main version update workflow
echo "🔍 Getting current version..."
CURRENT_VERSION=$(get_current_version)
echo "Current version: $CURRENT_VERSION"

if [ "$VERSION_TYPE" = "none" ]; then
    echo "📋 No version change requested"
    echo "new_version=$CURRENT_VERSION" >> $GITHUB_OUTPUT
    echo "changed=false" >> $GITHUB_OUTPUT
    exit 0
fi

# Calculate new version
NEW_VERSION=$(increment_version "$CURRENT_VERSION" "$VERSION_TYPE")
echo "New version: $NEW_VERSION"

# Update version in various files
echo "📝 Updating version in project files..."

# Update server/version.py
update_version_in_file \
    "server/version.py" \
    "$CURRENT_VERSION" \
    "$NEW_VERSION" \
    "s/__version__ = \"$CURRENT_VERSION\"/__version__ = \"$NEW_VERSION\"/"

# Update pyproject.toml (project version)
update_version_in_file \
    "pyproject.toml" \
    "$CURRENT_VERSION" \
    "$NEW_VERSION" \
    "s/version = \"$CURRENT_VERSION\"/version = \"$NEW_VERSION\"/"

# Update pyproject.toml (tool.briefcase version)
update_version_in_file \
    "pyproject.toml" \
    "$CURRENT_VERSION" \
    "$NEW_VERSION" \
    "s/^version = \"$CURRENT_VERSION\"/version = \"$NEW_VERSION\"/g"

# Update CHANGELOG.md
update_changelog "$NEW_VERSION" "$VERSION_TYPE"

# Commit changes
echo "📝 Committing version changes..."
git add server/version.py pyproject.toml CHANGELOG.md

if git diff --staged --quiet; then
    echo "⚠️ No changes to commit"
else
    git commit -m "chore: bump version to $NEW_VERSION [skip ci]

- Version increment: $VERSION_TYPE
- Updated version in server/version.py
- Updated version in pyproject.toml  
- Updated CHANGELOG.md"

    echo "✅ Committed version changes"
fi

# Push changes
echo "📤 Pushing version changes..."
git push origin HEAD

# Create Git tag
echo "🏷️ Creating Git tag..."
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION

Version: $NEW_VERSION
Type: $VERSION_TYPE release
Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

Changes:
- Version increment: $VERSION_TYPE
- See CHANGELOG.md for details"

git push origin "v$NEW_VERSION"

echo "✅ Created and pushed tag: v$NEW_VERSION"

# Set GitHub Actions outputs
echo "new_version=$NEW_VERSION" >> $GITHUB_OUTPUT
echo "changed=true" >> $GITHUB_OUTPUT

# Generate version summary
cat > version_summary.txt << EOF
Version Update Summary
=====================

Previous Version: $CURRENT_VERSION
New Version: $NEW_VERSION
Increment Type: $VERSION_TYPE
Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

Files Updated:
- server/version.py
- pyproject.toml
- CHANGELOG.md

Git Actions:
- Committed changes
- Created tag: v$NEW_VERSION
- Pushed to remote repository

Next Steps:
- Build and package applications
- Create GitHub release
- Publish to PyPI (if configured)
EOF

echo ""
echo "✅ Version update complete!"
echo "📋 Summary:"
cat version_summary.txt