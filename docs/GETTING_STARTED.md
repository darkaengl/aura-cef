# Getting Started with CEF Browser

This guide will help you quickly get up and running with the CEF Browser project.

## Prerequisites

- macOS 11.0+ (Big Sur or later)
- Xcode Command Line Tools (`xcode-select --install`)

The setup script will automatically install other dependencies.

## Setup

1. Clone the repository:
```bash
git clone <your-repo-url>
cd cef_browser_project
```

2. Make all scripts executable:
```bash
chmod +x scripts/*.sh
```

3. Run the setup script to download and configure CEF:
```bash
./scripts/setup_cef.sh
```
This will:
- Download the CEF binary distribution (~112MB)
- Build the CEF wrapper library
- Install any missing dependencies

4. Build the browser:
```bash
./scripts/build.sh
```

5. Run the browser:
```bash
./scripts/run_browser.sh
```

## Using the Browser

- The browser will open with Google as the homepage
- Navigation works as expected in any modern browser
- Close the window to exit the application

## Project Structure

- **src/** - Source code files
  - **main.cpp** - Application entry point
  - **browser_app.cpp/.h** - CEF application implementation
  - **browser_client.cpp/.h** - Browser client implementation

- **scripts/** - Automation scripts
  - **setup_cef.sh** - Downloads and sets up CEF
  - **build.sh** - Builds the browser
  - **run_browser.sh** - Runs the built browser

- **docs/** - Documentation
  - **TECHNICAL_GUIDE.md** - Detailed technical information
  - **GETTING_STARTED.md** - This file

## Troubleshooting

- **"CEF not found" error**: Run `./scripts/setup_cef.sh` to download and set up CEF
- **Build fails**: Ensure Xcode Command Line Tools are installed
- **Permission denied**: Run `chmod +x scripts/*.sh` to make scripts executable
- **Browser crashes**: Try adding `--disable-gpu` flag in the run script

## Next Steps

After getting the browser running:

1. Read the [Technical Guide](TECHNICAL_GUIDE.md) for detailed implementation information
2. Explore the source code to understand how it works
3. Try modifying `src/main.cpp` to change the homepage or window size
4. Add new features like browser tabs or a URL bar