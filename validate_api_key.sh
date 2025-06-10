#!/bin/bash

# Simple script to validate App Store Connect API Key
# This script helps diagnose issues with the API key authentication method

echo "🔑 App Store Connect API Key Validation"
echo "========================================"
echo ""
echo "This script will validate your App Store Connect API Key"
echo "and help diagnose issues with the API key authentication method."
echo ""

# Prompt for API key information
read -p "Enter your App Store Connect Key ID: " KEY_ID
read -p "Enter your App Store Connect Issuer ID: " ISSUER_ID
read -p "Enter path to your .p8 API key file: " KEY_PATH

# Validate inputs
if [ -z "$KEY_ID" ] || [ -z "$ISSUER_ID" ] || [ -z "$KEY_PATH" ]; then
  echo "❌ All fields are required"
  exit 1
fi

# Check if API key file exists
if [ ! -f "$KEY_PATH" ]; then
  echo "❌ API key file not found at: $KEY_PATH"
  exit 1
fi

echo ""
echo "🔍 Validating API key..."

# Create a temporary profile for testing
echo "Creating temporary credential profile..."
RESULT=$(xcrun notarytool store-credentials "temp-api-profile" \
  --key "$KEY_PATH" \
  --key-id "$KEY_ID" \
  --issuer "$ISSUER_ID" 2>&1)

if [ $? -eq 0 ]; then
  echo "✅ API key is valid!"
  
  # Test a simple API call
  echo ""
  echo "🔍 Testing API connection..."
  TEST_RESULT=$(xcrun notarytool info --apple-id doesnotexist@example.com --profile temp-api-profile 2>&1)
  
  # Check for specific error messages
  if [[ "$TEST_RESULT" == *"Unable to find the requested resource"* ]]; then
    echo "✅ API connection successful (expected resource not found error)"
    echo ""
    echo "Your API key is working correctly. The 'resource not found' error is expected"
    echo "since we used a non-existent Apple ID for the test."
  elif [[ "$TEST_RESULT" == *"401"* ]] || [[ "$TEST_RESULT" == *"authentication"* ]]; then
    echo "❌ API authentication failed"
    echo ""
    echo "Error details:"
    echo "$TEST_RESULT"
    echo ""
    echo "Possible issues:"
    echo "1. The API key doesn't have the 'Developer' role assigned"
    echo "2. The Key ID or Issuer ID is incorrect"
    echo "3. The API key has been revoked or expired"
  else
    echo "⚠️ Unexpected response from API"
    echo ""
    echo "Response details:"
    echo "$TEST_RESULT"
  fi
  
  # Clean up
  echo ""
  echo "🧹 Cleaning up temporary profile..."
  xcrun notarytool credentials delete "temp-api-profile" > /dev/null 2>&1
else
  echo "❌ API key validation failed"
  echo ""
  echo "Error details:"
  echo "$RESULT"
  echo ""
  echo "Possible issues:"
  echo "1. The .p8 file is invalid or corrupted"
  echo "2. The Key ID or Issuer ID is incorrect"
  echo "3. The API key doesn't have the 'Developer' role assigned"
  echo "4. The API key has been revoked or expired"
fi

echo ""
echo "📋 Next steps:"
echo "1. If validation succeeded, update your app_config.json with the API key information"
echo "2. Run 'python scripts/setup_apple_store.py phase2' to update GitHub secrets"
echo "3. If validation failed, create a new API key in App Store Connect and try again"