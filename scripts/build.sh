#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}CEF Browser Build Script${NC}"
echo -e "${YELLOW}Building the browser application...${NC}\n"

# Check if CEF is set up
if [ ! -d "cef" ] && [ ! -d "cef_binary_"* ]; then
    echo -e "${RED}Error: CEF binary distribution not found.${NC}"
    echo -e "Please run the setup script first:"
    echo -e "${YELLOW}./scripts/setup_cef.sh${NC}"
    exit 1
fi

# Parse build type
BUILD_TYPE="Release"
NINJA_FLAG=""

if [ "$1" == "--debug" ]; then
    BUILD_TYPE="Debug"
    echo -e "${YELLOW}Building in Debug mode${NC}"
elif [ "$1" == "--clean" ]; then
    echo -e "${YELLOW}Performing clean build...${NC}"
    rm -rf build
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo -e "Usage: ./scripts/build.sh [options]"
    echo -e ""
    echo -e "Options:"
    echo -e "  --debug    Build in Debug mode"
    echo -e "  --clean    Perform a clean build"
    echo -e "  --ninja    Use Ninja build system (faster)"
    echo -e "  --help, -h Show this help message"
    exit 0
elif [ "$1" == "--ninja" ]; then
    NINJA_FLAG="-G Ninja"
    echo -e "${YELLOW}Using Ninja build system${NC}"
fi

# Create build directory
mkdir -p build
cd build

# Configure build
echo -e "${BLUE}Configuring build...${NC}"
if [ -n "$NINJA_FLAG" ]; then
    cmake $NINJA_FLAG -DCMAKE_BUILD_TYPE=$BUILD_TYPE ..
else
    cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE ..
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}Configuration failed. Please check the error messages above.${NC}"
    exit 1
fi

# Build the project
echo -e "\n${BLUE}Building the project...${NC}"
if [ -n "$NINJA_FLAG" ]; then
    ninja
else
    make -j$(sysctl -n hw.ncpu)
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed. Please check the error messages above.${NC}"
    exit 1
fi

# Check if we're on macOS and if the app bundle was created
if [ "$(uname)" == "Darwin" ]; then
    if [ -d "cef_browser.app" ]; then
        echo -e "\n${GREEN}Build successful!${NC}"
        echo -e "Application created: ${YELLOW}build/cef_browser.app${NC}"
        echo -e "\nYou can run the browser with:"
        echo -e "${YELLOW}./scripts/run_browser.sh${NC}"
    else
        echo -e "\n${YELLOW}Note: App bundle is named cef_browser.app instead of CEFBrowser.app${NC}"
        echo -e "\n${GREEN}Build successful!${NC}"
        echo -e "Application created: ${YELLOW}build/cef_browser.app${NC}"
        echo -e "\nYou can run the browser with:"
        echo -e "${YELLOW}./scripts/run_browser.sh${NC}"
        exit 0
    fi
else
    echo -e "\n${GREEN}Build successful!${NC}"
    echo -e "Binary created: ${YELLOW}build/cef_browser${NC}"
    echo -e "\nYou can run the browser with:"
    echo -e "${YELLOW}./build/cef_browser${NC}"
fi

cd ..