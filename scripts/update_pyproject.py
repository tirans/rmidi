#!/usr/bin/env python3
"""
Update pyproject.toml with build configuration.

This script updates the pyproject.toml file with version information,
metadata, and platform-specific settings for Briefcase builds.
"""

import argparse
import re
import platform
import sys
from pathlib import Path


def safe_print(message, success=None):
    """Print messages with platform-safe symbols."""
    # Check if we're on Windows
    is_windows = platform.system() == "Windows"

    # Replace Unicode symbols with ASCII alternatives on Windows
    if is_windows:
        message = message.replace("✅", "[OK]").replace("❌", "[ERROR]").replace("⚠️", "[WARN]")

    # Add success/failure/warning prefix if specified
    if success is not None:
        if success is True:
            prefix = "[OK] " if is_windows else "✅ "
        elif success is False:
            prefix = "[ERROR] " if is_windows else "❌ "
        else:  # None or any other value is treated as a warning
            prefix = "[WARN] " if is_windows else "⚠️ "
        message = prefix + message

    # Force UTF-8 encoding on Windows to handle any remaining Unicode
    if is_windows:
        try:
            # Try to print with UTF-8 encoding without replacing sys.stdout
            print(message)
        except UnicodeEncodeError:
            # Fallback: encode to ASCII with replacement
            print(message.encode('ascii', 'replace').decode('ascii'))
    else:
        try:
            print(message)
        except UnicodeEncodeError:
            # Fallback: encode to ASCII with replacement
            print(message.encode('ascii', 'replace').decode('ascii'))


def update_pyproject(
    version=None,
    author=None,
    author_email=None,
    server_name=None,
    client_name=None,
    bundle_prefix=None,
    codesign_identity=None,
    app_store=False
):
    """Update pyproject.toml with the provided configuration."""

    # Read the current pyproject.toml
    pyproject_path = Path("pyproject.toml")
    if not pyproject_path.exists():
        safe_print("pyproject.toml not found", False)
        return False

    content = pyproject_path.read_text()

    # Update version
    if version:
        content = re.sub(r'version = "[^"]*"', f'version = "{version}"', content)
        safe_print(f"Updated version to: {version}", True)

    # Update author
    if author:
        content = re.sub(r'author = "[^"]*"', f'author = "{author}"', content)
        safe_print(f"Updated author to: {author}", True)

    # Update author email
    if author_email:
        content = re.sub(r'author_email = "[^"]*"', f'author_email = "{author_email}"', content)
        safe_print(f"Updated author_email to: {author_email}", True)

    # Update bundle prefix
    if bundle_prefix:
        content = re.sub(r'bundle = "[^"]*"', f'bundle = "{bundle_prefix}"', content)
        safe_print(f"Updated bundle to: {bundle_prefix}", True)

    # Update formal names
    if server_name:
        # Update server formal name
        content = re.sub(
            r'(formal_name = "R2MIDI Server[^"]*")',
            f'formal_name = "{server_name}"',
            content
        )
        safe_print(f"Updated server name to: {server_name}", True)

    if client_name:
        # Update client formal name  
        content = re.sub(
            r'(formal_name = "R2MIDI Client[^"]*")',
            f'formal_name = "{client_name}"',
            content
        )
        safe_print(f"Updated client name to: {client_name}", True)

    # Update code signing identity for macOS
    if codesign_identity:
        # Add or update codesign_identity in macOS sections
        if 'codesign_identity = ' in content:
            content = re.sub(
                r'codesign_identity = "[^"]*"',
                f'codesign_identity = "{codesign_identity}"',
                content
            )
        else:
            # Add codesign_identity after [tool.briefcase.app.server.macOS]
            content = re.sub(
                r'(\[tool\.briefcase\.app\.server\.macOS\])',
                f'\\1\ncodesign_identity = "{codesign_identity}"',
                content
            )
            content = re.sub(
                r'(\[tool\.briefcase\.app\.r2midi-client\.macOS\])',
                f'\\1\ncodesign_identity = "{codesign_identity}"',
                content
            )
        safe_print(f"Updated codesign_identity", True)

    # Update for App Store
    if app_store:
        # Enable app sandboxing
        content = re.sub(r'app-sandbox = false', 'app-sandbox = true', content)
        safe_print("Enabled app sandboxing for App Store", True)

        # Update entitlements for App Store
        content = re.sub(
            r'com\.apple\.security\.network\.server</key>\s*<false/>',
            'com.apple.security.network.server</key>\n    <true/>',
            content
        )
        content = re.sub(
            r'com\.apple\.security\.network\.client</key>\s*<false/>',
            'com.apple.security.network.client</key>\n    <true/>',
            content
        )

    # Write the updated content
    pyproject_path.write_text(content)
    safe_print("pyproject.toml updated successfully", True)

    return True


def main():
    parser = argparse.ArgumentParser(description="Update pyproject.toml for builds")

    parser.add_argument("--version", help="Application version")
    parser.add_argument("--author", help="Author name")
    parser.add_argument("--author-email", help="Author email")
    parser.add_argument("--server-name", help="Server application name")
    parser.add_argument("--client-name", help="Client application name")
    parser.add_argument("--bundle-prefix", help="Bundle ID prefix")
    parser.add_argument("--codesign-identity", help="macOS code signing identity")
    parser.add_argument("--app-store", action="store_true", help="Configure for App Store")

    args = parser.parse_args()

    # Update pyproject.toml
    success = update_pyproject(
        version=args.version,
        author=args.author,
        author_email=args.author_email,
        server_name=args.server_name,
        client_name=args.client_name,
        bundle_prefix=args.bundle_prefix,
        codesign_identity=args.codesign_identity,
        app_store=args.app_store
    )

    return 0 if success else 1


if __name__ == "__main__":
    exit(main())
