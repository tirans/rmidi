#!/usr/bin/env python3
"""
GitHub Secrets Setup Generator for R2MIDI
==========================================

This script walks you through setting up all the necessary secrets, certificates,
and configurations needed for the GitHub Actions workflow to properly build and
sign your R2MIDI applications.

Requirements:
- macOS (for certificate management)
- Active Apple Developer Account
- GitHub repository access
- Python 3.8+

Usage:
    python scripts/setup_github_secrets.py
"""

import os
import sys
import subprocess
import base64
import json
import getpass
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple


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


class GitHubSecretsGenerator:
    """Main class for generating GitHub secrets and certificates."""

    def __init__(self):
        self.secrets = {}
        self.github_repo = "tirans/r2midi"

    def print_header(self, text: str):
        """Print a formatted header."""
        print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}")
        print(f"{text}")
        print(f"{'='*60}{Colors.ENDC}")

    def print_step(self, step: int, title: str):
        """Print a step header."""
        print(f"\n{Colors.CYAN}{Colors.BOLD}Step {step}: {title}{Colors.ENDC}")
        print(f"{Colors.CYAN}{'-'*40}{Colors.ENDC}")

    def print_success(self, text: str):
        """Print success message."""
        print(f"{Colors.GREEN}✅ {text}{Colors.ENDC}")

    def print_warning(self, text: str):
        """Print warning message."""
        print(f"{Colors.WARNING}⚠️  {text}{Colors.ENDC}")

    def print_error(self, text: str):
        """Print error message."""
        print(f"{Colors.FAIL}❌ {text}{Colors.ENDC}")

    def print_info(self, text: str):
        """Print info message."""
        print(f"{Colors.BLUE}ℹ️  {text}{Colors.ENDC}")

    def check_prerequisites(self) -> bool:
        """Check if all prerequisites are met."""
        self.print_step(1, "Checking Prerequisites")

        if sys.platform != "darwin":
            self.print_error("This script must be run on macOS for certificate management.")
            return False

        required_commands = [ "git", "openssl"]
        for cmd in required_commands:
            try:
                subprocess.run([cmd, "--version"], capture_output=True, check=True)
                self.print_success(f"{cmd} is available")
            except (subprocess.CalledProcessError, FileNotFoundError):
                self.print_error(f"{cmd} is not available. Please install it.")
                return False

        try:
            subprocess.run(["xcode-select", "--print-path"], capture_output=True, check=True)
            self.print_success("Xcode command line tools are installed")
        except subprocess.CalledProcessError:
            self.print_error("Xcode command line tools not found. Run: xcode-select --install")
            return False

        return True

    def get_basic_info(self):
        """Get basic information from user."""
        self.print_step(2, "Basic Information")

        while True:
            bundle_prefix = input(f"{Colors.BLUE}Bundle ID prefix (e.g., com.yourcompany): {Colors.ENDC}").strip()
            if re.match(r'^[a-z]+\.[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)*$', bundle_prefix):
                self.secrets['APP_BUNDLE_ID_PREFIX'] = bundle_prefix
                break
            self.print_error("Invalid bundle ID format. Use reverse domain notation like: com.yourcompany")

        self.secrets['APP_DISPLAY_NAME_SERVER'] = input(
            f"{Colors.BLUE}Server app display name [R2MIDI Server]: {Colors.ENDC}").strip() or "R2MIDI Server"

        self.secrets['APP_DISPLAY_NAME_CLIENT'] = input(
            f"{Colors.BLUE}Client app display name [R2MIDI Client]: {Colors.ENDC}").strip() or "R2MIDI Client"

        self.secrets['APP_AUTHOR_NAME'] = input(f"{Colors.BLUE}Author name: {Colors.ENDC}").strip()
        self.secrets['APP_AUTHOR_EMAIL'] = input(f"{Colors.BLUE}Author email: {Colors.ENDC}").strip()

        self.print_success("Basic information collected")

    def get_apple_developer_info(self):
        """Get Apple Developer account information."""
        self.print_step(3, "Apple Developer Account Information")

        print("You'll need an active Apple Developer Program membership ($99/year)")
        print("Visit: https://developer.apple.com/programs/")

        if input(f"{Colors.BLUE}Do you have an Apple Developer account? (y/n): {Colors.ENDC}").lower() != 'y':
            self.print_warning("You'll need an Apple Developer account for code signing")
            return

        self.secrets['APPLE_ID'] = input(f"{Colors.BLUE}Apple ID email: {Colors.ENDC}").strip()

        print(f"\n{Colors.BLUE}To find your Team ID:{Colors.ENDC}")
        print("1. Go to https://developer.apple.com/account/")
        print("2. Sign in with your Apple ID")
        print("3. Look for 'Team ID' in the membership section")

        self.secrets['APPLE_TEAM_ID'] = input(f"{Colors.BLUE}Apple Developer Team ID: {Colors.ENDC}").strip()

        print(f"\n{Colors.BLUE}Create an app-specific password:{Colors.ENDC}")
        print("1. Go to https://appleid.apple.com/")
        print("2. Sign in with your Apple ID")
        print("3. Go to 'Security' → 'App-Specific Passwords'")
        print("4. Generate a new password for 'GitHub Actions'")

        self.secrets['APPLE_ID_PASSWORD'] = getpass.getpass(f"{Colors.BLUE}App-specific password: {Colors.ENDC}")

        self.print_success("Apple Developer information collected")

    def check_keychain_certificates(self) -> Dict[str, str]:
        """Check for available certificates in keychain."""
        self.print_step(4, "Checking Keychain Certificates")

        certificates = {}

        try:
            result = subprocess.run([
                "security", "find-identity", "-v", "-p", "codesigning"
            ], capture_output=True, text=True, check=True)

            for line in result.stdout.split('\n'):
                if "Developer ID Application:" in line:
                    match = re.search(r'"([^"]*Developer ID Application[^"]*)"', line)
                    if match:
                        cert_name = match.group(1)
                        certificates['developer_id'] = cert_name
                        self.print_success(f"Found Developer ID certificate: {cert_name}")

                elif "3rd Party Mac Developer Application:" in line:
                    match = re.search(r'"([^"]*3rd Party Mac Developer Application[^"]*)"', line)
                    if match:
                        cert_name = match.group(1)
                        certificates['app_store'] = cert_name
                        self.print_success(f"Found App Store certificate: {cert_name}")

        except subprocess.CalledProcessError:
            self.print_error("Failed to check keychain certificates")

        if not certificates:
            self.print_warning("No signing certificates found in keychain")
            self.print_info("Download certificates from Apple Developer Portal and install them")

        return certificates

    def export_certificate(self, cert_name: str, cert_type: str) -> Optional[Tuple[str, str]]:
        """Export a certificate from keychain."""
        print(f"\n{Colors.BLUE}Exporting {cert_type} certificate...{Colors.ENDC}")

        temp_file = f"/tmp/{cert_type}_cert.p12"

        try:
            password = getpass.getpass(f"Enter password for {cert_type} certificate export: ")

            result = subprocess.run([
                "security", "export", "-k", "login.keychain",
                "-t", "identities", "-f", "pkcs12",
                "-o", temp_file, "-P", password
            ], input=f'"{cert_name}"\n', text=True, capture_output=True)

            if result.returncode != 0:
                self.print_error(f"Failed to export certificate: {result.stderr}")
                return None

            with open(temp_file, 'rb') as f:
                cert_data = f.read()

            os.remove(temp_file)
            encoded_cert = base64.b64encode(cert_data).decode('utf-8')

            self.print_success(f"{cert_type} certificate exported and encoded")
            return encoded_cert, password

        except Exception as e:
            self.print_error(f"Error exporting certificate: {e}")
            if os.path.exists(temp_file):
                os.remove(temp_file)
            return None

    def setup_certificates(self):
        """Set up certificates for code signing."""
        certificates = self.check_keychain_certificates()

        if not certificates:
            return

        # Developer ID certificate
        if 'developer_id' in certificates:
            if input(f"{Colors.BLUE}Export Developer ID certificate? (y/n): {Colors.ENDC}").lower() == 'y':
                result = self.export_certificate(certificates['developer_id'], "developer_id")
                if result:
                    encoded_cert, password = result
                    self.secrets['APPLE_CERTIFICATE_P12'] = encoded_cert
                    self.secrets['APPLE_CERTIFICATE_PASSWORD'] = password

        # App Store certificate
        if 'app_store' in certificates:
            if input(f"{Colors.BLUE}Export App Store certificate? (y/n): {Colors.ENDC}").lower() == 'y':
                result = self.export_certificate(certificates['app_store'], "app_store")
                if result:
                    encoded_cert, password = result
                    self.secrets['APPLE_APP_STORE_CERTIFICATE_P12'] = encoded_cert
                    self.secrets['APPLE_APP_STORE_CERTIFICATE_PASSWORD'] = password

        # Windows certificate (optional)
        if input(f"{Colors.BLUE}Do you have a Windows code signing certificate? (y/n): {Colors.ENDC}").lower() == 'y':
            print(f"\n{Colors.BLUE}Windows certificate setup:{Colors.ENDC}")
            cert_path = input("Path to Windows .p12 certificate file: ").strip()

            if os.path.exists(cert_path):
                cert_password = getpass.getpass("Certificate password: ")
                with open(cert_path, 'rb') as f:
                    cert_data = f.read()
                self.secrets['WINDOWS_CERTIFICATE_P12'] = base64.b64encode(cert_data).decode('utf-8')
                self.secrets['WINDOWS_CERTIFICATE_PASSWORD'] = cert_password
                self.print_success("Windows certificate configured")
            else:
                self.print_error(f"Certificate file not found: {cert_path}")

    def setup_app_store_connect(self):
        """Set up App Store Connect API integration."""
        self.print_step(5, "App Store Connect API Setup")

        print("App Store Connect API keys enable automatic app submission to the Mac App Store.")
        print("This is optional but recommended for automated releases.")

        if input(f"{Colors.BLUE}Set up App Store Connect API? (y/n): {Colors.ENDC}").lower() != 'y':
            self.print_info("App Store Connect API setup skipped")
            return

        print(f"\n{Colors.BLUE}To create an App Store Connect API key:{Colors.ENDC}")
        print("1. Go to https://appstoreconnect.apple.com/access/api")
        print("2. Sign in with your Apple Developer account")
        print("3. Click '+' to create a new API key")
        print("4. Choose 'Developer' role (or higher)")
        print("5. Download the .p8 file")
        print("6. Note the Key ID and Issuer ID")

        self.secrets['APP_STORE_CONNECT_KEY_ID'] = input(
            f"{Colors.BLUE}App Store Connect Key ID (e.g., ABC123DEF4): {Colors.ENDC}").strip()

        self.secrets['APP_STORE_CONNECT_ISSUER_ID'] = input(
            f"{Colors.BLUE}App Store Connect Issuer ID (UUID): {Colors.ENDC}").strip()

        print(f"\n{Colors.BLUE}API Key file (.p8):{Colors.ENDC}")
        api_key_path = input(f"Path to AuthKey_*.p8 file: ").strip()

        if os.path.exists(api_key_path):
            with open(api_key_path, 'rb') as f:
                api_key_data = f.read()
            self.secrets['APP_STORE_CONNECT_API_KEY'] = base64.b64encode(api_key_data).decode('utf-8')
            self.print_success("App Store Connect API key encoded")
        else:
            self.print_error(f"API key file not found: {api_key_path}")
            return

        self.print_success("App Store Connect API configured")

    def configure_build_options(self):
        """Configure build and distribution options."""
        self.print_step(6, "Build Configuration")

        if input(f"{Colors.BLUE}Enable App Store builds? (y/n): {Colors.ENDC}").lower() == 'y':
            self.secrets['ENABLE_APP_STORE_BUILD'] = 'true'

            if input(f"{Colors.BLUE}Enable automatic App Store submission? (y/n): {Colors.ENDC}").lower() == 'y':
                self.secrets['ENABLE_APP_STORE_SUBMISSION'] = 'true'

        if input(f"{Colors.BLUE}Enable notarization? (y/n): {Colors.ENDC}").lower() == 'y':
            self.secrets['ENABLE_NOTARIZATION'] = 'true'

        self.print_success("Build options configured")

    def generate_secrets_file(self):
        """Generate a secrets file for reference."""
        self.print_step(7, "Generating Secrets File")

        secrets_file = "github_secrets.txt"

        with open(secrets_file, 'w') as f:
            f.write("# GitHub Secrets for R2MIDI\n")
            f.write("# Copy these values to your GitHub repository secrets\n")
            f.write("# Repository → Settings → Secrets and variables → Actions\n\n")

            for key, value in self.secrets.items():
                # Don't write any sensitive values to file, even if they're not explicitly marked
                if 'PASSWORD' in key or 'P12' in key or 'TOKEN' in key or 'KEY' in key or 'SECRET' in key or 'CERTIFICATE' in key:
                    f.write(f"{key}=<sensitive_value_hidden>\n")
                else:
                    f.write(f"{key}={value}\n")

        self.print_success(f"Secrets reference saved to {secrets_file}")
        self.print_warning("Remember to securely delete this file after adding secrets to GitHub!")

    def display_setup_instructions(self):
        """Display final setup instructions."""
        self.print_step(8, "GitHub Repository Setup")

        print(f"{Colors.BOLD}To complete the setup:{Colors.ENDC}\n")

        print("1. Go to your GitHub repository:")
        print(f"   https://github.com/{self.github_repo}")

        print("\n2. Navigate to Settings → Secrets and variables → Actions")

        print("\n3. Add the following repository secrets:")

        for key, value in self.secrets.items():
            # Use the same criteria for masking sensitive values as in generate_secrets_file
            if 'PASSWORD' in key or 'P12' in key or 'TOKEN' in key or 'KEY' in key or 'SECRET' in key or 'CERTIFICATE' in key:
                print(f"   {Colors.WARNING}{key}{Colors.ENDC} = <paste the value securely>")
            else:
                print(f"   {Colors.GREEN}{key}{Colors.ENDC} = {value}")

        print(f"\n4. {Colors.BOLD}Security reminders:{Colors.ENDC}")
        print("   - Never commit certificates or passwords to your repository")
        print("   - Use GitHub secrets for all sensitive information")
        print("   - Regularly rotate app-specific passwords")
        print("   - Delete the github_secrets.txt file after use")

        print(f"\n5. {Colors.BOLD}Test the workflow:{Colors.ENDC}")
        print("   - Push to master branch to trigger the build")
        print("   - Check Actions tab for build progress")
        print("   - Verify signed applications in releases")

    def run(self):
        """Run the complete setup process."""
        self.print_header("R2MIDI GitHub Secrets Setup Generator")

        print("This tool will help you set up all the necessary secrets and certificates")
        print("for automated building and code signing of your R2MIDI applications.")

        try:
            if not self.check_prerequisites():
                return False

            self.get_basic_info()
            self.get_apple_developer_info()
            self.setup_certificates()
            self.setup_app_store_connect()
            self.configure_build_options()
            self.generate_secrets_file()
            self.display_setup_instructions()

            self.print_header("Setup Complete!")
            self.print_success("All secrets and certificates have been prepared")
            self.print_info("Follow the instructions above to complete the GitHub setup")

            return True

        except KeyboardInterrupt:
            self.print_error("\nSetup interrupted by user")
            return False
        except Exception as e:
            self.print_error(f"Setup failed: {e}")
            return False


def main():
    """Main entry point."""
    generator = GitHubSecretsGenerator()

    if generator.run():
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
