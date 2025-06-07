#!/usr/bin/env python3
"""
Script to update pyproject.toml with code signing identity and other metadata.
Usage: 
  - For regular builds: python update_pyproject.py --codesign-identity "Developer ID Application: Name (TEAM_ID)"
  - For App Store: python update_pyproject.py --app-store --codesign-identity "3rd Party Mac Developer Application: Name (TEAM_ID)"
"""

import argparse
import re
import sys
from pathlib import Path

def update_pyproject(file_path, **kwargs):
    """Update pyproject.toml with provided parameters."""
    with open(file_path, 'r') as f:
        content = f.read()

    # Update bundle ID if provided
    if kwargs.get('bundle_prefix'):
        content = re.sub(
            r'bundle\s*=\s*"com\.r2midi"', 
            f'bundle = "{kwargs["bundle_prefix"]}"', 
            content
        )

    # Update version if provided
    if kwargs.get('version'):
        content = re.sub(
            r'version\s*=\s*"[^"]*"', 
            f'version = "{kwargs["version"]}"', 
            content
        )

    # Update author if provided
    if kwargs.get('author'):
        content = re.sub(
            r'author\s*=\s*"[^"]*"', 
            f'author = "{kwargs["author"]}"', 
            content
        )

    # Update author email if provided
    if kwargs.get('author_email'):
        content = re.sub(
            r'author_email\s*=\s*"[^"]*"', 
            f'author_email = "{kwargs["author_email"]}"', 
            content
        )

    # Update formal names if provided
    if kwargs.get('server_name'):
        content = re.sub(
            r'formal_name\s*=\s*"R2MIDI Server"', 
            f'formal_name = "{kwargs["server_name"]}"', 
            content
        )

    if kwargs.get('client_name'):
        content = re.sub(
            r'formal_name\s*=\s*"R2MIDI Client"', 
            f'formal_name = "{kwargs["client_name"]}"', 
            content
        )

    # Update codesign identity if provided
    if kwargs.get('codesign_identity'):
        # Escape any special characters in the codesign identity
        escaped_identity = kwargs['codesign_identity'].replace('"', '\\"')

        # Check if codesign_identity already exists
        if re.search(r'codesign_identity\s*=\s*"[^"]*"', content) or re.search(r"codesign_identity\s*=\s*'[^']*'", content):
            # Update existing codesign_identity - handle both single and double quotes
            content = re.sub(
                r'codesign_identity\s*=\s*"[^"]*"', 
                f'codesign_identity = "{escaped_identity}"', 
                content
            )
            content = re.sub(
                r"codesign_identity\s*=\s*'[^']*'", 
                f'codesign_identity = "{escaped_identity}"', 
                content
            )
        else:
            # Add codesign_identity to macOS sections
            for section in ['[tool.briefcase.app.server.macOS]', '[tool.briefcase.app.r2midi-client.macOS]']:
                section_pos = content.find(section)
                if section_pos != -1:
                    # Find the end of the section header line
                    section_end = content.find('\n', section_pos)
                    if section_end != -1:
                        # Insert after the section header
                        insert_pos = section_end + 1
                        content = (
                            content[:insert_pos] + 
                            f'codesign_identity = "{escaped_identity}"\n' + 
                            content[insert_pos:]
                        )

    # Write the updated content back to the file
    with open(file_path, 'w') as f:
        f.write(content)

    print(f"Updated {file_path} with provided parameters")

def main():
    parser = argparse.ArgumentParser(description='Update pyproject.toml with code signing identity and other metadata')
    parser.add_argument('--codesign-identity', help='Code signing identity to use')
    parser.add_argument('--app-store', action='store_true', help='Update for App Store submission')
    parser.add_argument('--bundle-prefix', help='Bundle ID prefix')
    parser.add_argument('--version', help='App version')
    parser.add_argument('--author', help='Author name')
    parser.add_argument('--author-email', help='Author email')
    parser.add_argument('--server-name', help='Server app formal name')
    parser.add_argument('--client-name', help='Client app formal name')

    args = parser.parse_args()

    pyproject_path = Path('pyproject.toml')
    if not pyproject_path.exists():
        print(f"Error: {pyproject_path} not found", file=sys.stderr)
        sys.exit(1)

    # Convert args to dictionary for update_pyproject function
    kwargs = {
        'codesign_identity': args.codesign_identity,
        'bundle_prefix': args.bundle_prefix,
        'version': args.version,
        'author': args.author,
        'author_email': args.author_email,
        'server_name': args.server_name,
        'client_name': args.client_name,
    }

    # Filter out None values
    kwargs = {k: v for k, v in kwargs.items() if v is not None}

    update_pyproject(pyproject_path, **kwargs)

if __name__ == '__main__':
    main()
