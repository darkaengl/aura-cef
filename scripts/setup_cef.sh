#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}CEF Browser Setup Script${NC}"
echo -e "${YELLOW}This script will download and set up CEF for macOS ARM64${NC}\n"

# Check for required tools
echo "Checking dependencies..."
MISSING_DEPS=0

# Query available CEF builds and download the first working one
echo "📋 Querying available CEF builds..."

AVAILABLE_FILES=$(curl -s "https://cef-builds.spotifycdn.com/index.json" | \
    grep -o '"cef_binary_[^"]*macosarm64_minimal\.tar\.bz2"' | \
    tr -d '"' | head -5)

if [ -z "$AVAILABLE_FILES" ]; then
    echo "❌ No macOS ARM64 minimal builds found"
    exit 1
fi

echo "📋 Found these builds:"
echo "$AVAILABLE_FILES" | nl

BASE_URL="https://cef-builds.spotifycdn.com"

# Try each available file
for CEF_ARCHIVE in $AVAILABLE_FILES; do
    echo ""
    echo "📦 Trying to download $CEF_ARCHIVE..."
    
    if curl -f -L -o "$CEF_ARCHIVE" "$BASE_URL/$CEF_ARCHIVE"; then
        echo "✅ Successfully downloaded $CEF_ARCHIVE ($(du -h "$CEF_ARCHIVE" | cut -f1))"
        
        echo "📂 Extracting CEF binary..."
        if tar -xjf "$CEF_ARCHIVE"; then
            echo "✅ Successfully extracted CEF"
            
            # Get the extracted directory name
            CEF_DIR=$(find . -maxdepth 1 -type d -name "cef_binary_*" | head -1)
            
            if [ -n "$CEF_DIR" ]; then
                echo "📁 CEF extracted to: $CEF_DIR"
                
                # Create symlink for easier access
                ln -sf "$CEF_DIR" current
                
                echo ""
                echo "🔧 Building CEF wrapper library..."
                cd "$CEF_DIR"
                mkdir -p build_cef
                cd build_cef
                cmake .. > /dev/null 2>&1
                make libcef_dll_wrapper > /dev/null 2>&1
                
                if [ -f "libcef_dll_wrapper/libcef_dll_wrapper.a" ]; then
                    echo "✅ CEF wrapper library built successfully"
                else
                    echo "❌ Failed to build CEF wrapper library"
                    exit 1
                fi
                
                cd ../../..
                
                echo ""
                echo "🎉 CEF setup complete!"
                echo "CEF directory: $(pwd)/cef/$CEF_DIR"
                echo "Symlink: $(pwd)/cef/current"
                
                # Clean up archive
                rm -f "cef/$CEF_ARCHIVE"
                
                echo ""
                echo "✅ Ready to build the CEF browser!"
                echo "   Run: mkdir -p build && cd build && cmake .. && make"
                
                exit 0
            else
                echo "❌ Could not find extracted CEF directory"
            fi
        else
            echo "❌ Failed to extract $CEF_ARCHIVE"
        fi
        
        # Clean up failed download
        rm -f "$CEF_ARCHIVE"
    else
        echo "❌ Failed to download $CEF_ARCHIVE"
    fi
done

echo "❌ All downloads failed"
exit 1