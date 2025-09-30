#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}CEF Browser Launcher${NC}"
echo -e "${YELLOW}Starting the CEF browser application...${NC}\n"

# Check if the browser exists
if [ ! -d "build/cef_browser.app" ]; then
  echo -e "${RED}Error: Browser application not found.${NC}"
  echo -e "Please build the browser first using:"
  echo -e "${YELLOW}./scripts/build.sh${NC}"
  
  # Check if CEF is set up
  if [ ! -d "cef" ] && [ ! -d "cef_binary_"* ]; then
    echo -e "\n${RED}CEF binary distribution not found.${NC}"
    echo -e "Please run the setup script first:"
    echo -e "${YELLOW}./scripts/setup_cef.sh${NC}"
  fi
  
  exit 1
fi

# Prepare any command line arguments
ARGS=""

# Handle command line arguments
if [ "$1" == "--enable-gpu" ]; then
  ARGS="--enable-gpu"
  echo -e "${YELLOW}Starting browser with GPU acceleration enabled${NC}"
  echo -e "${RED}Warning: This may crash without proper code signing${NC}"
elif [ "$1" == "--sign" ]; then
  echo -e "${YELLOW}Signing the application bundle before launch...${NC}"
  
  # Check for --no-prompt flag
  NO_PROMPT=false
  if [[ "$2" == "--no-prompt" || "$3" == "--no-prompt" ]]; then
    NO_PROMPT=true
  fi
  
  # Ask for confirmation unless --no-prompt is specified
  if [ "$NO_PROMPT" != true ]; then
    echo -e "${YELLOW}This will attempt to access your keychain for code signing certificates.${NC}"
    read -p "Do you want to continue? (y/n): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo -e "${RED}Signing canceled.${NC}"
      exit 0
    fi
  fi
  
  # Check if a custom identity is provided
  if [[ -n "$2" && "$2" != "--no-prompt" ]]; then
    ./scripts/sign_app.sh "$2"
  else
    ./scripts/sign_app.sh
  fi
  
  # Check if signing succeeded
  if [ $? -ne 0 ]; then
    echo -e "${RED}Signing failed. Please check the error messages above.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Application signed successfully.${NC}"
  
  # Check if any additional arguments were provided
  if [[ -n "$3" && "$3" != "--no-prompt" ]]; then
    ARGS="$3"
  fi
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  echo -e "Usage: ./scripts/run_browser.sh [options]"
  echo -e ""
  echo -e "Options:"
  echo -e "  --disable-gpu      Start browser with GPU acceleration disabled"
  echo -e "  --debug            Start with detailed logging"
  echo -e "  --sign [identity]  Sign the application bundle before launch (optional: specify signing identity)"
  echo -e "  --help, -h         Show this help message"
  exit 0
elif [ "$1" == "--debug" ]; then
  ARGS="--enable-logging --log-level=0"
  echo -e "${YELLOW}Starting browser with detailed logging enabled${NC}"
fi

echo -e "${GREEN}Launching CEF Browser...${NC}"
echo -e "Look for a browser window to appear!"
echo -e "Press Ctrl+C in this terminal to force close the browser if needed.\n"

# Change to the directory containing the executable
cd build

# Run the browser
./cef_browser.app/Contents/MacOS/cef_browser $ARGS

# Check exit status
STATUS=$?
if [ $STATUS -ne 0 ]; then
  echo -e "\n${RED}Browser exited with error status: $STATUS${NC}"
  
  # Provide troubleshooting tips
  echo -e "\nTroubleshooting tips:"
  echo -e "1. Try running with GPU acceleration disabled:"
  echo -e "   ${YELLOW}./scripts/run_browser.sh --disable-gpu${NC}"
  echo -e "2. Check for detailed logs with:"
  echo -e "   ${YELLOW}./scripts/run_browser.sh --debug${NC}"
  echo -e "3. Ensure your macOS version is 11.0 or later"
  echo -e "4. Rebuild the browser with:"
  echo -e "   ${YELLOW}./scripts/build.sh${NC}"
else
  echo -e "\n${GREEN}Browser session ended normally.${NC}"
fi

# Return to original directory
cd ..