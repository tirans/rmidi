#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# The following block is Python code that will only run when executed with Python
# It's enclosed in a bash comment block so bash will ignore it
: '
This is a Bash script, not a Python script.
If you are seeing this message as an error, you are trying to run this script with Python.
Please run it with bash instead: bash ./scripts/debug_certificates.sh
'

# Python detection and early exit
if command -v python3 >/dev/null 2>&1 && [[ "$(basename -- "$0")" != "bash" && "$0" != "-bash" && "$0" != "/bin/bash" ]]; then
  # This is a bash comment but the following is valid Python code that bash will ignore
  # because it's inside an if-condition that evaluates to false for bash
  if [[ "$(basename -- "$0")" == *"python"* || "$(ps -o comm= $PPID 2>/dev/null)" == *"python"* ]]; then
    python3 - <<'PYTHON_EOF'
import sys
print("\n⚠️ ERROR: This is a Bash script, not a Python script!")
print("Please run it with: bash ./scripts/debug_certificates.sh [keychain] [password]\n")
sys.exit(1)
PYTHON_EOF
    exit 1
  fi
fi

# The actual bash script starts here
# Debug script to help troubleshoot macOS code signing certificate issues
# Usage: ./scripts/debug_certificates.sh [keychain_name] [keychain_password]

# ⚠️⚠️⚠️ IMPORTANT: THIS IS A BASH SCRIPT, NOT A PYTHON SCRIPT ⚠️⚠️⚠️
# If you're seeing a syntax error about "unmatched ')'", you're running this with Python.
# Please run it with bash instead.

# Python detection - this will prevent the script from being executed with Python
if [[ -n "$PYTHON_VERSION" ]] || [[ "$0" == *python* ]] || [[ "$(ps -o comm= $PPID 2>/dev/null)" == *python* ]] || [[ "$0" == *python3* ]] || [[ "$(basename $0)" == "python"* ]]; then
    echo ""
    echo "⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️"
    echo "⚠️                   ERROR: INCORRECT EXECUTION                   ⚠️"
    echo "⚠️                                                                ⚠️"
    echo "⚠️  This is a BASH script and CANNOT be run with Python/Python3.  ⚠️"
    echo "⚠️                                                                ⚠️"
    echo "⚠️  You tried to run:                                             ⚠️"
    echo "⚠️  python3 ./scripts/debug_certificates.sh [arguments]           ⚠️"
    echo "⚠️                                                                ⚠️"
    echo "⚠️  Instead, please run it with:                                  ⚠️"
    echo "⚠️  bash ./scripts/debug_certificates.sh [keychain] [password]    ⚠️"
    echo "⚠️                                                                ⚠️"
    echo "⚠️  Or make it executable first with:                             ⚠️"
    echo "⚠️  chmod +x ./scripts/debug_certificates.sh                      ⚠️"
    echo "⚠️                                                                ⚠️"
    echo "⚠️  Then run:                                                     ⚠️"
    echo "⚠️  ./scripts/debug_certificates.sh [keychain] [password]         ⚠️"
    echo "⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️"
    echo ""
    exit 1
fi

set -e

KEYCHAIN_NAME="${1:-briefcase.keychain}"
KEYCHAIN_PASSWORD="${2:-briefcase}"

echo "🔍 macOS Code Signing Certificate Debug Tool"
echo "============================================="
echo "Usage: $0 [keychain_name] [keychain_password]"
echo "Default: keychain_name=briefcase.keychain, keychain_password=briefcase"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script requires macOS"
    exit 1
fi

# Check if keychain exists
if ! security list-keychains | grep -q "$KEYCHAIN_NAME"; then
    echo "⚠️ Keychain '$KEYCHAIN_NAME' not found in keychain list"
    echo ""
    echo "Available keychains:"
    security list-keychains
    echo ""
    echo "💡 Tip: Create a keychain first with:"
    echo "   security create-keychain -p password \"$KEYCHAIN_NAME\""
    exit 1
fi

echo "✅ Found keychain: $KEYCHAIN_NAME"
echo ""

# List all identities in the keychain
echo "🔍 All identities in keychain:"
echo "------------------------------"
security find-identity -v "$KEYCHAIN_NAME" || {
    echo "❌ Failed to list identities in keychain"
    exit 1
}
echo ""

# List only code signing identities
echo "🔍 Code signing identities:"
echo "---------------------------"
CODESIGN_IDENTITIES=$(security find-identity -v -p codesigning "$KEYCHAIN_NAME" 2>/dev/null || true)
if [ -z "$CODESIGN_IDENTITIES" ]; then
    echo "❌ No code signing identities found!"
else
    echo "$CODESIGN_IDENTITIES"
fi
echo ""

# Look specifically for Developer ID Application certificates
echo "🔍 Developer ID Application certificates:"
echo "-----------------------------------------"
DEV_ID_CERTS=$(security find-identity -v -p codesigning "$KEYCHAIN_NAME" 2>/dev/null | grep "Developer ID Application" || true)
if [ -z "$DEV_ID_CERTS" ]; then
    echo "❌ No Developer ID Application certificates found!"
    echo ""
    echo "💡 You need a 'Developer ID Application' certificate for distribution outside the Mac App Store"
    echo "   Get one from: https://developer.apple.com/account/resources/certificates/list"
else
    echo "$DEV_ID_CERTS"
    echo ""

    # Test different parsing methods
    echo "🧪 Testing identity parsing methods:"
    echo "------------------------------------"

    echo "Method 1 (sed name extraction):"
    METHOD1=$(echo "$DEV_ID_CERTS" | head -1 | sed -n 's/.*"\([^"]*\)".*/\1/p')
    echo "  Result: '$METHOD1'"
    echo "  Length: ${#METHOD1}"

    echo ""
    echo "Method 2 (awk SHA-1 extraction):"
    METHOD2=$(echo "$DEV_ID_CERTS" | head -1 | awk '{print $2}')
    echo "  Result: '$METHOD2'"
    echo "  Length: ${#METHOD2}"

    echo ""
    echo "Method 3 (original awk with quotes):"
    METHOD3=$(echo "$DEV_ID_CERTS" | head -1 | awk -F'"' '{print $2}')
    echo "  Result: '$METHOD3'"
    echo "  Length: ${#METHOD3}"

    # Test which method works for codesign
    echo ""
    echo "🧪 Testing methods with codesign:"
    echo "---------------------------------"

    # Create a test file
    TEST_FILE="test_signing_$$.txt"
    if ! echo "test content" > "$TEST_FILE"; then
        echo "❌ Failed to create test file"
        echo ""
    elif [ ! -f "$TEST_FILE" ]; then
        echo "❌ Test file was not created properly"
        echo ""
    else
        for i in 1 2 3; do
            METHOD_VAR="METHOD$i"
            IDENTITY=${!METHOD_VAR}

            if [ -n "$IDENTITY" ]; then
                echo "Testing Method $i: '$IDENTITY'"
                if codesign -s "$IDENTITY" "$TEST_FILE" 2>/dev/null; then
                    echo "  ✅ SUCCESS - Method $i works!"
                    WORKING_IDENTITY="$IDENTITY"
                    WORKING_METHOD="$i"
                else
                    echo "  ❌ FAILED - Method $i doesn't work"
                fi
            else
                echo "Testing Method $i: (empty)"
                echo "  ❌ FAILED - Method $i returned empty string"
            fi
            echo ""
        done

        # Clean up test file
        rm -f "$TEST_FILE"
    fi

    # Show recommendation
    if [ -n "$WORKING_IDENTITY" ]; then
        echo "🎉 RECOMMENDATION:"
        echo "=================="
        echo "Use Method $WORKING_METHOD with identity: '$WORKING_IDENTITY'"
        echo ""
        echo "For GitHub Actions, use this in your workflow:"
        case $WORKING_METHOD in
            1)
                echo "SIGNING_IDENTITY=\$(security find-identity -v -p codesigning \$KEYCHAIN | grep \"Developer ID Application\" | head -1 | sed -n 's/.*\"\([^\"]*\)\".*/\1/p')"
                ;;
            2)
                echo "SIGNING_IDENTITY=\$(security find-identity -v -p codesigning \$KEYCHAIN | grep \"Developer ID Application\" | head -1 | awk '{print \$2}')"
                ;;
            3)
                echo "SIGNING_IDENTITY=\$(security find-identity -v -p codesigning \$KEYCHAIN | grep \"Developer ID Application\" | head -1 | awk -F'\"' '{print \$2}')"
                ;;
        esac
    else
        echo "❌ PROBLEM:"
        echo "==========="
        echo "None of the parsing methods produced a working identity!"
        echo "This suggests an issue with the certificate or keychain setup."
    fi
fi
echo ""

# Look for App Store certificates
echo "🔍 Mac App Store certificates:"
echo "------------------------------"
APP_STORE_CERTS=$(security find-identity -v -p codesigning "$KEYCHAIN_NAME" 2>/dev/null | grep "3rd Party Mac Developer Application" || true)
if [ -z "$APP_STORE_CERTS" ]; then
    echo "ℹ️ No App Store certificates found (this is normal if you only need Developer ID)"
else
    echo "$APP_STORE_CERTS"
fi
echo ""

# Check keychain status
echo "🔍 Keychain status:"
echo "------------------"
echo "Default keychain:"
security default-keychain
echo ""

echo "Keychain info for $KEYCHAIN_NAME:"
security show-keychain-info "$KEYCHAIN_NAME" 2>/dev/null || {
    echo "❌ Could not get keychain info (might be locked)"
}
echo ""

# Check if keychain is unlocked
echo "🔍 Testing keychain access:"
echo "---------------------------"
if security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME" 2>/dev/null; then
    echo "✅ Keychain can be unlocked"
else
    echo "❌ Keychain cannot be unlocked (check password)"
fi
echo ""

# Summary
echo "📋 SUMMARY:"
echo "==========="
if [ -n "$WORKING_IDENTITY" ]; then
    echo "✅ Found working signing identity"
    echo "✅ Recommended identity: '$WORKING_IDENTITY'"
    echo "✅ Use Method $WORKING_METHOD for parsing"
else
    echo "❌ No working signing identity found"
    echo ""
    echo "🔧 TROUBLESHOOTING STEPS:"
    echo "========================"
    echo "1. Verify you have a valid Developer ID Application certificate"
    echo "2. Check that the certificate was imported correctly:"
    echo "   security import cert.p12 -k \"$KEYCHAIN_NAME\" -P \"your-p12-password\" -T /usr/bin/codesign"
    echo "3. Set keychain partition list:"
    echo "   security set-key-partition-list -S apple-tool:,apple: -s -k \"$KEYCHAIN_PASSWORD\" \"$KEYCHAIN_NAME\""
    echo "4. Ensure keychain is unlocked:"
    echo "   security unlock-keychain -p \"$KEYCHAIN_PASSWORD\" \"$KEYCHAIN_NAME\""
    echo "5. Make it the default keychain:"
    echo "   security default-keychain -s \"$KEYCHAIN_NAME\""
fi

echo ""
echo "🏁 Debug complete!"
