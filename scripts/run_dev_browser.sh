#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}CEF Browser Development Mode${NC}"
echo -e "${YELLOW}This script runs a special build of CEF browser optimized for unsigned development${NC}\n"

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
  echo -e "${RED}Error: This script is designed for macOS only.${NC}"
  exit 1
fi

# Check if the binary exists
if [ ! -d "build/cef_browser.app" ]; then
  echo -e "${RED}Error: Browser application not found.${NC}"
  echo -e "Please build the browser first using:"
  echo -e "${YELLOW}./scripts/build.sh${NC}"
  exit 1
fi

# Create a local wrapper for the app that sets environment variables
echo -e "${YELLOW}Preparing special launcher for unsigned development mode...${NC}"

# Create a temp directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create the wrapper script
cat > "$TEMP_DIR/cef_unsigned_wrapper.sh" << 'EOL'
#!/bin/bash

# Print informative message about what we're doing
echo "🔧 Configuring CEF development environment:"
echo "  → Enabling single-process mode (avoids helper process requirements)"
echo "  → Disabling sandbox (avoids entitlements requirements)"
echo "  → Disabling GPU features (avoids hardware acceleration issues)"
echo ""
echo "⚠️  Note: This is a special development mode with reduced functionality"
echo "    Some websites may not display correctly due to disabled features"
echo "    For production use, code signing is recommended"
echo ""

# Set critical environment variables to force single-process mode
export CEF_SINGLE_PROCESS=1
export CEF_USE_SANDBOX=0
export GOOGLE_LOGINS_ENABLED=0

# Only print libraries in debug mode
if [[ "$*" == *"--debug"* ]]; then
  export DYLD_PRINT_LIBRARIES=1
  export DYLD_PRINT_LIBRARIES_POST_LAUNCH=1
fi

# Force command-line switches that disable GPU and multi-process architecture
exec "$@" \
  --single-process \
  --disable-gpu \
  --disable-software-rasterizer \
  --disable-extensions \
  --disable-gpu-compositing \
  --disable-gpu-sandbox \
  --disable-gpu-vsync \
  --disable-accelerated-video-decode \
  --disable-accelerated-2d-canvas \
  --disable-accelerated-painting \
  --disable-webgl \
  --no-sandbox
EOL

# Make the wrapper executable
chmod +x "$TEMP_DIR/cef_unsigned_wrapper.sh"

echo -e "${GREEN}Launching CEF Browser in single-process mode...${NC}"
echo -e "${YELLOW}This is a special development mode that avoids helper processes.${NC}"
echo -e "${YELLOW}Note: Some web features may not work in this mode.${NC}"
echo -e "Press Ctrl+C to exit.\n"

# Run the browser with the wrapper
"$TEMP_DIR/cef_unsigned_wrapper.sh" ./build/cef_browser.app/Contents/MacOS/cef_browser "$@"

# Check exit status
STATUS=$?
if [ $STATUS -ne 0 ]; then
  echo -e "\n${RED}Browser exited with error status: $STATUS${NC}"
  
  echo -e "\n${YELLOW}Important: For production use, the app must be properly code signed.${NC}"
  echo -e "See the docs/CODE_SIGNING.md file for details on properly signing the application."
else
  echo -e "\n${GREEN}Browser session ended normally.${NC}"
fi