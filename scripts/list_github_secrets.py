#!/usr/bin/env python3
"""
GitHub Secrets Lister for R2MIDI
================================

This script lists all the actual GitHub secrets used in the R2MIDI project.
It stores the list of secrets in JSON format and prints them to the console.

IMPORTANT: This script can only access actual GitHub secrets when run within a GitHub Actions workflow.
When run locally, it will display environment variables with the same names if they exist.

Usage:
    # In a GitHub Actions workflow:
    - name: List GitHub Secrets
      run: python scripts/list_github_secrets.py
      env:
        APPLE_APP_STORE_CERTIFICATE_P12: ${{ secrets.APPLE_APP_STORE_CERTIFICATE_P12 }}
        APPLE_APP_STORE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_APP_STORE_CERTIFICATE_PASSWORD }}
        # ... other secrets ...
"""

import json
import sys
import os


class Colors:
    """ANSI color codes for terminal output."""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


def print_header(text: str):
    """Print a formatted header."""
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}")
    print(f"{text}")
    print(f"{'='*60}{Colors.ENDC}")


def get_github_secrets():
    """Return a dictionary of GitHub secrets from environment variables."""
    # List of GitHub secrets categorized by usage
    used_secrets = [
        # App Store workflow
        "APPLE_APP_STORE_CERTIFICATE_P12",
        "APPLE_APP_STORE_CERTIFICATE_PASSWORD",
        "APP_STORE_CONNECT_API_KEY",
        "APP_STORE_CONNECT_ISSUER_ID",
        "APP_STORE_CONNECT_KEY_ID",
        # Release workflow
        "GITHUB_TOKEN",
        "PYPI_API_TOKEN",
        # Reusable build workflow
        "APPLE_CERTIFICATE_P12",
        "APPLE_CERTIFICATE_PASSWORD",
        "APPLE_ID",
        "APPLE_ID_PASSWORD",
        "APPLE_TEAM_ID",
        "WINDOWS_CERTIFICATE_P12",
        "WINDOWS_CERTIFICATE_PASSWORD",
        "APP_BUNDLE_ID_PREFIX",
        "APP_DISPLAY_NAME_SERVER",
        "APP_DISPLAY_NAME_CLIENT",
        "APP_AUTHOR_NAME",
        "APP_AUTHOR_EMAIL"
    ]

    unused_secrets = [
        "ENABLE_APP_STORE_BUILD",
        "ENABLE_APP_STORE_SUBMISSION",
        "ENABLE_NOTARIZATION"
    ]

    # Get actual values from environment variables
    used_secrets_dict = {}
    for secret in used_secrets:
        value = os.environ.get(secret)
        if value:
            # Truncate very long values for display purposes
            if len(value) > 100 and ('P12' in secret or 'CERTIFICATE' in secret or 'KEY' in secret):
                display_value = value[:50] + "..." + value[-10:]
                used_secrets_dict[secret] = display_value
            else:
                used_secrets_dict[secret] = value
        else:
            used_secrets_dict[secret] = f"<{secret}_NOT_FOUND>"

    unused_secrets_dict = {}
    for secret in unused_secrets:
        value = os.environ.get(secret)
        if value:
            # Truncate very long values for display purposes
            if len(value) > 100 and ('P12' in secret or 'CERTIFICATE' in secret or 'KEY' in secret):
                display_value = value[:50] + "..." + value[-10:]
                unused_secrets_dict[secret] = display_value
            else:
                unused_secrets_dict[secret] = value
        else:
            unused_secrets_dict[secret] = f"<{secret}_NOT_FOUND>"

    return {"used": used_secrets_dict, "unused": unused_secrets_dict}


def print_github_secrets(secrets):
    """Print the GitHub secrets to the console."""
    print_header("R2MIDI GitHub Secrets")

    # Print used secrets
    print(f"{Colors.BOLD}Used Project Secrets:{Colors.ENDC}\n")

    used_secrets = secrets["used"]
    found_used_secrets = False

    for key, value in used_secrets.items():
        if not value.endswith("_NOT_FOUND>"):
            found_used_secrets = True
            # Highlight sensitive values
            if ('PASSWORD' in key or 'P12' in key or 'TOKEN' in key or 
                'KEY' in key or 'SECRET' in key or 'CERTIFICATE' in key):
                print(f"{Colors.WARNING}{key}{Colors.ENDC} = {value}")
            else:
                print(f"{Colors.GREEN}{key}{Colors.ENDC} = {value}")
        else:
            print(f"{Colors.FAIL}{key}{Colors.ENDC} = {value}")

    if not found_used_secrets:
        print(f"{Colors.FAIL}No used secrets found in environment variables.{Colors.ENDC}")

    # Print unused secrets
    print(f"\n{Colors.BOLD}Unused Project Secrets:{Colors.ENDC}\n")

    unused_secrets = secrets["unused"]
    found_unused_secrets = False

    for key, value in unused_secrets.items():
        if not value.endswith("_NOT_FOUND>"):
            found_unused_secrets = True
            # Highlight sensitive values
            if ('PASSWORD' in key or 'P12' in key or 'TOKEN' in key or 
                'KEY' in key or 'SECRET' in key or 'CERTIFICATE' in key):
                print(f"{Colors.WARNING}{key}{Colors.ENDC} = {value}")
            else:
                print(f"{Colors.GREEN}{key}{Colors.ENDC} = {value}")
        else:
            print(f"{Colors.FAIL}{key}{Colors.ENDC} = {value}")

    if not found_unused_secrets:
        print(f"{Colors.FAIL}No unused secrets found in environment variables.{Colors.ENDC}")

    # Overall status
    found_secrets = found_used_secrets or found_unused_secrets
    if not found_secrets:
        print(f"\n{Colors.FAIL}❌ No GitHub secrets found in environment variables.{Colors.ENDC}")
        print(f"{Colors.BOLD}This script can only access actual GitHub secrets when run within a GitHub Actions workflow.{Colors.ENDC}")
        print("To use this script in a GitHub Actions workflow, add the following to your workflow YAML:")
        print("""
    - name: List GitHub Secrets
      run: python scripts/list_github_secrets.py
      env:
        APPLE_APP_STORE_CERTIFICATE_P12: ${{ secrets.APPLE_APP_STORE_CERTIFICATE_P12 }}
        APPLE_APP_STORE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_APP_STORE_CERTIFICATE_PASSWORD }}
        # ... other secrets ...
        """)
    else:
        print(f"\n{Colors.GREEN}✅ Successfully retrieved GitHub secrets from environment variables.{Colors.ENDC}")


def save_to_json(secrets, filename="github_secrets.json"):
    """Save the secrets to a JSON file."""
    try:
        with open(filename, 'w') as f:
            json.dump(secrets, f, indent=4)
        print(f"\n{Colors.GREEN}✅ Secrets saved to {filename}{Colors.ENDC}")

        # Count found secrets
        used_found = sum(1 for v in secrets["used"].values() if not v.endswith("_NOT_FOUND>"))
        unused_found = sum(1 for v in secrets["unused"].values() if not v.endswith("_NOT_FOUND>"))
        total_found = used_found + unused_found
        total_secrets = len(secrets["used"]) + len(secrets["unused"])

        print(f"{Colors.BLUE}Found {total_found}/{total_secrets} secrets ({used_found} used, {unused_found} unused){Colors.ENDC}")
    except Exception as e:
        print(f"\n{Colors.FAIL}❌ Error saving secrets to file: {e}{Colors.ENDC}")


def main():
    """Main entry point."""
    print_header("R2MIDI GitHub Secrets Lister")

    # Check if running in GitHub Actions
    if os.environ.get('GITHUB_ACTIONS') == 'true':
        print(f"{Colors.GREEN}Running in GitHub Actions environment.{Colors.ENDC}")
    else:
        print(f"{Colors.WARNING}Not running in GitHub Actions environment.{Colors.ENDC}")
        print("This script can only access actual GitHub secrets when run within a GitHub Actions workflow.")
        print("When run locally, it will display environment variables with the same names if they exist.")

    # Get the GitHub secrets
    secrets = get_github_secrets()

    # Print the secrets to the console
    print_github_secrets(secrets)

    # Save the secrets to a JSON file
    save_to_json(secrets)

    return 0


if __name__ == "__main__":
    sys.exit(main())
