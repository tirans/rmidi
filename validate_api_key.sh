#!/bin/bash

# Simple script to validate App Store Connect API Key
# This script helps diagnose issues with the API key authentication method

echo "🔑 App Store Connect API Key Validation"
echo "========================================"
echo ""
echo "This script will validate your App Store Connect API Key"
echo "and help diagnose issues with the API key authentication method."
echo ""

# Read values from app_config.json
CONFIG_FILE="apple_credentials/config/app_config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Configuration file not found: $CONFIG_FILE"
  exit 1
fi

# Extract values using grep and sed (more portable than jq)
KEY_ID=$(grep -o '"app_store_connect_key_id": "[^"]*"' "$CONFIG_FILE" | sed 's/"app_store_connect_key_id": "\(.*\)"/\1/')
ISSUER_ID=$(grep -o '"app_store_connect_issuer_id": "[^"]*"' "$CONFIG_FILE" | sed 's/"app_store_connect_issuer_id": "\(.*\)"/\1/')
KEY_PATH=$(grep -o '"app_store_connect_api_key_path": "[^"]*"' "$CONFIG_FILE" | sed 's/"app_store_connect_api_key_path": "\(.*\)"/\1/')

# Handle relative paths for the API key
if [[ "$KEY_PATH" != /* ]]; then
  # Path is relative, prepend the repository root
  # Determine the repository root based on the location of the config file
  REPO_ROOT="$(pwd)"

  # Check if the path already starts with apple_credentials to avoid duplication
  if [[ "$KEY_PATH" == apple_credentials/* ]]; then
    # If it already starts with apple_credentials, just prepend the repository root
    KEY_PATH="$REPO_ROOT/$KEY_PATH"
  else
    # Otherwise, assume it's a path relative to apple_credentials
    KEY_PATH="$REPO_ROOT/apple_credentials/$KEY_PATH"
  fi
fi

echo "Using configuration from: $CONFIG_FILE"
echo "Key ID: $KEY_ID"
echo "Issuer ID: $ISSUER_ID"
echo "API Key Path: $KEY_PATH"

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
  TEST_RESULT=$(xcrun notarytool history --keychain-profile temp-api-profile 2>&1)

  # Check for specific error messages
  if [[ "$TEST_RESULT" == *"No submissions found"* ]] || [[ "$TEST_RESULT" == *"[]"* ]] || [[ "$TEST_RESULT" == *"Successfully received submission history"* ]] || [[ "$TEST_RESULT" == *"history"* && "$TEST_RESULT" == *"createdDate"* ]]; then
    echo "✅ API connection successful"
    echo ""
    if [[ "$TEST_RESULT" == *"Successfully received submission history"* ]] || [[ "$TEST_RESULT" == *"history"* && "$TEST_RESULT" == *"createdDate"* ]]; then
      echo "Your API key is working correctly. Submission history was retrieved successfully."
    else
      echo "Your API key is working correctly. The 'no submissions' response is expected"
      echo "if you haven't submitted any apps for notarization yet."
    fi
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
