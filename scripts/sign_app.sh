#!/bin/bash

# Exit on error
set -e

# Display steps as they're executed
set -x

# Default to first available identity if none specified
if [ -z "$1" ]; then
    # Try to find an available identity
    AVAILABLE_IDENTITY=$(security find-identity -v -p codesigning | grep -m 1 -o '"[^"]*"' | tr -d '"')
    
    if [ -z "$AVAILABLE_IDENTITY" ]; then
        echo "Error: No code signing identities found. You must provide a valid identity or create one."
        echo "To create a self-signed certificate, use Keychain Access:"
        echo "Keychain Access -> Certificate Assistant -> Create a Certificate -> Code Signing certificate"
        exit 1
    fi
    
    IDENTITY="$AVAILABLE_IDENTITY"
else
    IDENTITY="$1"
fi
ENTITLEMENTS_FILE="$(pwd)/resources/cef_browser.entitlements"
APP_PATH="$(pwd)/build/cef_browser.app"

# Check if the app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: Application bundle not found at $APP_PATH"
    echo "Please build the application first."
    exit 1
fi

# Check if entitlements file exists
if [ ! -f "$ENTITLEMENTS_FILE" ]; then
    echo "Error: Entitlements file not found at $ENTITLEMENTS_FILE"
    exit 1
fi

echo "=== Signing Process Started ==="
echo "Using identity: $IDENTITY"
echo "Using entitlements: $ENTITLEMENTS_FILE"

# 1. Sign the Helper apps first
echo "Signing CEF Helper apps..."
HELPERS_DIR="$APP_PATH/Contents/Frameworks/Chromium Embedded Framework.framework/Versions/A/Helpers"

find "$HELPERS_DIR" -name "*.app" -type d | while read -r helper_app; do
    echo "Signing helper: $helper_app"
    # Sign the helper app binaries
    helper_bin="$helper_app/Contents/MacOS/"
    helper_name=$(basename "$helper_app" .app)
    
    # Sign any frameworks inside the helper (if they exist)
    if [ -d "$helper_app/Contents/Frameworks" ]; then
        find "$helper_app/Contents/Frameworks" -type f -not -path "*.dSYM*" | while read -r framework_bin; do
            codesign --force --timestamp --options runtime --entitlements "$ENTITLEMENTS_FILE" --sign "$IDENTITY" "$framework_bin"
        done
    fi
    
    # Sign the main helper binary
    codesign --force --timestamp --options runtime --entitlements "$ENTITLEMENTS_FILE" --sign "$IDENTITY" "$helper_bin/$helper_name"
    
    # Sign the helper app
    codesign --force --timestamp --options runtime --entitlements "$ENTITLEMENTS_FILE" --sign "$IDENTITY" "$helper_app"
done

# 2. Sign the CEF Framework
echo "Signing CEF Framework..."
CEF_FRAMEWORK="$APP_PATH/Contents/Frameworks/Chromium Embedded Framework.framework"
codesign --force --timestamp --options runtime --entitlements "$ENTITLEMENTS_FILE" --sign "$IDENTITY" "$CEF_FRAMEWORK"

# 3. Sign any other frameworks
echo "Signing other frameworks and libraries..."
find "$APP_PATH/Contents/Frameworks" -not -path "*Chromium Embedded Framework.framework*" -name "*.framework" -o -name "*.dylib" | while read -r framework; do
    codesign --force --timestamp --options runtime --entitlements "$ENTITLEMENTS_FILE" --sign "$IDENTITY" "$framework"
done

# 4. Sign the main executable
echo "Signing main application executable..."
MAIN_EXECUTABLE="$APP_PATH/Contents/MacOS/cef_browser"
codesign --force --timestamp --options runtime --entitlements "$ENTITLEMENTS_FILE" --sign "$IDENTITY" "$MAIN_EXECUTABLE"

# 5. Finally, sign the .app bundle
echo "Signing the application bundle..."
codesign --force --timestamp --options runtime --deep --entitlements "$ENTITLEMENTS_FILE" --sign "$IDENTITY" "$APP_PATH"

# Verify the signatures
echo "=== Verification ==="
echo "Verifying app signature..."
codesign -vvv --deep "$APP_PATH"

echo "Checking app bundle structure..."
find "$APP_PATH" -type f | grep -v "\.dSYM" | sort

echo "=== Signing Process Completed ==="