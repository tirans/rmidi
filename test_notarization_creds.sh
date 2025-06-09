#!/bin/bash

# Test script to verify notarization credentials
# Run this locally before updating GitHub secrets

echo "🧪 Testing Apple notarization credentials..."
echo ""

# Prompt for credentials (don't store them in the script)
read -p "Enter your Apple ID (email): " APPLE_ID
read -s -p "Enter your app-specific password: " APPLE_ID_PASSWORD
echo ""
read -p "Enter your Team ID: " APPLE_TEAM_ID

echo ""
echo "🔐 Testing notarization credential storage..."

# Try to store credentials
echo "$APPLE_ID_PASSWORD" | xcrun notarytool store-credentials "test-profile" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password -

if [ $? -eq 0 ]; then
  echo "✅ Credentials are valid!"
  echo "🧹 Cleaning up test profile..."
  xcrun notarytool credentials delete "test-profile"
  echo "✅ Test completed successfully"
else
  echo "❌ Credentials are invalid"
  echo ""
  echo "📋 Troubleshooting tips:"
  echo "1. Make sure you're using an app-specific password (not your regular Apple ID password)"
  echo "2. Generate a new app-specific password at https://appleid.apple.com"
  echo "3. Verify your Team ID at https://developer.apple.com/account/#!/membership"
  echo "4. Make sure your Apple ID has Developer Program access"
fi
