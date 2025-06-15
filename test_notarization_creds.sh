#!/bin/bash

# Test script to verify notarization credentials
# Run this locally before updating GitHub secrets

echo "🧪 Testing Apple notarization credentials..."
echo ""

# Ask which authentication method to use
echo "Select authentication method:"
echo "1) Apple ID with app-specific password (traditional)"
echo "2) App Store Connect API Key (recommended for CI/CD)"
read -p "Enter choice (1 or 2): " AUTH_METHOD

if [ "$AUTH_METHOD" == "1" ]; then
  # Apple ID authentication
  read -p "Enter your Apple ID (email): " APPLE_ID
  read -s -p "Enter your app-specific password: " APPLE_ID_PASSWORD
  echo ""
  read -p "Enter your Team ID: " APPLE_TEAM_ID

  echo ""
  echo "🔐 Testing notarization credential storage with Apple ID..."

  # Try to store credentials with Apple ID
  echo "$APPLE_ID_PASSWORD" | xcrun notarytool store-credentials "test-profile" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password -

elif [ "$AUTH_METHOD" == "2" ]; then
  # App Store Connect API Key authentication
  read -p "Enter your App Store Connect Key ID: " ASC_KEY_ID
  read -p "Enter your App Store Connect Issuer ID: " ASC_ISSUER_ID
  read -p "Enter path to your .p8 API key file: " ASC_KEY_PATH

  if [ ! -f "$ASC_KEY_PATH" ]; then
    echo "❌ API key file not found at: $ASC_KEY_PATH"
    exit 1
  fi

  echo ""
  echo "🔐 Testing notarization credential storage with API key..."

  # Try to store credentials with API key
  xcrun notarytool store-credentials "test-profile" \
    --key "$ASC_KEY_PATH" \
    --key-id "$ASC_KEY_ID" \
    --issuer "$ASC_ISSUER_ID"

else
  echo "❌ Invalid choice. Please run the script again and select 1 or 2."
  exit 1
fi

if [ $? -eq 0 ]; then
  echo "✅ Credentials are valid!"
  echo "🧹 Cleaning up test profile..."
  xcrun notarytool credentials delete "test-profile"
  echo "✅ Test completed successfully"
else
  echo "❌ Credentials are invalid"
  echo ""
  echo "📋 Troubleshooting tips:"

  if [ "$AUTH_METHOD" == "1" ]; then
    # Apple ID troubleshooting
    echo "For Apple ID authentication:"
    echo "1. Make sure you're using an app-specific password (not your regular Apple ID password)"
    echo "2. Generate a new app-specific password at https://appleid.apple.com"
    echo "3. Verify your Team ID at https://developer.apple.com/account/#!/membership"
    echo "4. Make sure your Apple ID has Developer Program access"
    echo ""
    echo "Note: Apple may have restricted Apple ID authentication for notarization."
    echo "Consider using App Store Connect API Key authentication instead (option 2)."
  else
    # API Key troubleshooting
    echo "For App Store Connect API Key authentication:"
    echo "1. Verify your Key ID and Issuer ID at https://appstoreconnect.apple.com/access/api"
    echo "2. Make sure your API key has the 'Developer' role assigned"
    echo "3. Check that your .p8 file is valid and not corrupted"
    echo "4. Create a new API key if necessary (you can't download the .p8 file again)"
  fi
fi
