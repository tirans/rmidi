#!/usr/bin/env python3
"""
Script to update pyproject.toml with build metadata and signing configuration.
Used by GitHub Actions workflows to configure Briefcase builds.
"""

import argparse
import re
import sys
from pathlib import Path


def update_pyproject_toml(
    version=None,
    author=None,
    author_email=None,
    server_name=None,
    client_name=None,
    bundle_prefix=None,
    codesign_identity=None,
    app_store=False
):
    """Update pyproject.toml with the provided metadata."""
    
    pyproject_path = Path("pyproject.toml")
    if not pyproject_path.exists():
        print(f"❌ pyproject.toml not found at {pyproject_path.absolute()}")
        sys.exit(1)
    
    print(f"📝 Updating {pyproject_path} with build metadata...")
    
    # Read the current content
    content = pyproject_path.read_text()
    
    # Update version
    if version:
        content = re.sub(
            r'version = "[^"]*"',
            f'version = "{version}"',
            content
        )
        print(f"✅ Updated version to: {version}")
    
    # Update author
    if author:
        content = re.sub(
            r'author = "[^"]*"',
            f'author = "{author}"',
            content
        )
        print(f"✅ Updated author to: {author}")
    
    # Update author email
    if author_email:
        content = re.sub(
            r'author_email = "[^"]*"',
            f'author_email = "{author_email}"',
            content
        )
        print(f"✅ Updated author_email to: {author_email}")
    
    # Update server formal name
    if server_name:
        content = re.sub(
            r'(\[tool\.briefcase\.app\.server\]\s*[\s\S]*?)formal_name = "[^"]*"',
            f'\\1formal_name = "{server_name}"',
            content
        )
        print(f"✅ Updated server formal_name to: {server_name}")
    
    # Update client formal name
    if client_name:
        content = re.sub(
            r'(\[tool\.briefcase\.app\.r2midi-client\]\s*[\s\S]*?)formal_name = "[^"]*"',
            f'\\1formal_name = "{client_name}"',
            content
        )
        print(f"✅ Updated client formal_name to: {client_name}")
    
    # Update bundle prefix for both apps
    if bundle_prefix:
        # Update server bundle ID
        content = re.sub(
            r'(\[tool\.briefcase\.app\.server\]\s*[\s\S]*?)bundle = "[^"]*"',
            f'\\1bundle = "{bundle_prefix}.server"',
            content
        )
        # Update client bundle ID
        content = re.sub(
            r'(\[tool\.briefcase\.app\.r2midi-client\]\s*[\s\S]*?)bundle = "[^"]*"',
            f'\\1bundle = "{bundle_prefix}.client"',
            content
        )
        print(f"✅ Updated bundle prefix to: {bundle_prefix}")
    
    # Handle codesign identity
    if codesign_identity:
        # Determine the platform section to update
        if app_store:
            platform_section = "tool.briefcase.app.server.macOS.app"
            identity_key = "codesign_identity"
        else:
            platform_section = "tool.briefcase.app.server.macOS.app"
            identity_key = "codesign_identity"
        
        # First, try to update existing codesign_identity
        server_pattern = rf'(\[{platform_section}\][\s\S]*?){identity_key} = "[^"]*"'
        if re.search(server_pattern, content):
            content = re.sub(
                server_pattern,
                f'\\1{identity_key} = "{codesign_identity}"',
                content
            )
        else:
            # Add codesign_identity to server macOS section
            server_section_pattern = rf'(\[{platform_section}\])([\s\S]*?)(?=\[|\Z)'
            match = re.search(server_section_pattern, content)
            if match:
                section_start = match.group(1)
                section_content = match.group(2)
                new_section = f'{section_start}\n{identity_key} = "{codesign_identity}"{section_content}'
                content = re.sub(server_section_pattern, new_section, content)
            else:
                # Create the section if it doesn't exist
                server_app_pattern = r'(\[tool\.briefcase\.app\.server\][\s\S]*?)(?=\[tool\.briefcase\.app\.r2midi-client\]|\Z)'
                match = re.search(server_app_pattern, content)
                if match:
                    server_content = match.group(1)
                    new_server_content = f'{server_content}\n[{platform_section}]\n{identity_key} = "{codesign_identity}"\n'
                    content = re.sub(server_app_pattern, new_server_content, content)
        
        # Update client codesign_identity
        client_platform_section = "tool.briefcase.app.r2midi-client.macOS.app"
        client_pattern = rf'(\[{client_platform_section}\][\s\S]*?){identity_key} = "[^"]*"'
        if re.search(client_pattern, content):
            content = re.sub(
                client_pattern,
                f'\\1{identity_key} = "{codesign_identity}"',
                content
            )
        else:
            # Add codesign_identity to client macOS section
            client_section_pattern = rf'(\[{client_platform_section}\])([\s\S]*?)(?=\[|\Z)'
            match = re.search(client_section_pattern, content)
            if match:
                section_start = match.group(1)
                section_content = match.group(2)
                new_section = f'{section_start}\n{identity_key} = "{codesign_identity}"{section_content}'
                content = re.sub(client_section_pattern, new_section, content)
            else:
                # Create the section if it doesn't exist
                client_app_pattern = r'(\[tool\.briefcase\.app\.r2midi-client\][\s\S]*)(\Z)'
                match = re.search(client_app_pattern, content)
                if match:
                    client_content = match.group(1)
                    new_client_content = f'{client_content}\n[{client_platform_section}]\n{identity_key} = "{codesign_identity}"\n'
                    content = re.sub(client_app_pattern, new_client_content, content)
        
        print(f"✅ Updated codesign_identity to: {codesign_identity}")
        if app_store:
            print("✅ Configured for App Store distribution")
    
    # Write the updated content back
    pyproject_path.write_text(content)
    print(f"✅ Successfully updated {pyproject_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Update pyproject.toml with build metadata and signing configuration"
    )
    
    parser.add_argument("--version", help="App version")
    parser.add_argument("--author", help="Author name")
    parser.add_argument("--author-email", help="Author email")
    parser.add_argument("--server-name", help="Server app formal name")
    parser.add_argument("--client-name", help="Client app formal name")
    parser.add_argument("--bundle-prefix", help="Bundle ID prefix")
    parser.add_argument("--codesign-identity", help="Code signing identity")
    parser.add_argument("--app-store", action="store_true", help="Configure for App Store")
    
    args = parser.parse_args()
    
    try:
        update_pyproject_toml(
            version=args.version,
            author=args.author,
            author_email=args.author_email,
            server_name=args.server_name,
            client_name=args.client_name,
            bundle_prefix=args.bundle_prefix,
            codesign_identity=args.codesign_identity,
            app_store=args.app_store
        )
    except Exception as e:
        print(f"❌ Error updating pyproject.toml: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
