# CEF Browser User Guide

## Overview

CEF Browser is a simple web browser built using the Chromium Embedded Framework (CEF). It provides a clean, native browsing experience with the full power of Chromium's rendering engine.

## Features

- Full Chromium browser engine
- Clean, native window interface
- Fast page loading
- Standard web navigation
- Modern web standards support

## Getting Started

### Installation

1. Download the latest release from the project repository
2. Extract the archive to a location of your choice
3. Make the scripts executable:
   ```bash
   chmod +x scripts/*.sh
   ```

### First Run

Run the browser using the run script:
```bash
./scripts/run_browser.sh
```

Alternatively, you can directly run the application:
```bash
./build/CEFBrowser.app/Contents/MacOS/cef_browser
```

### Navigation

CEF Browser includes standard navigation features:
- Back and forward navigation via keyboard shortcuts
- Address entry via the OS keyboard shortcuts
- Link selection with mouse

## Keyboard Shortcuts

- **⌘+L**: Focus address bar
- **⌘+T**: Open new window (if supported)
- **⌘+W**: Close window
- **⌘+R**: Reload page
- **⌘+[**: Go back
- **⌘+]**: Go forward
- **⌘+0**: Reset zoom
- **⌘++**: Zoom in
- **⌘+-**: Zoom out

## Customization

The browser can be customized by editing the source code:

1. Open `src/main.cpp` to modify:
   - Default URL
   - Window size
   - Browser settings

2. Rebuild the browser:
   ```bash
   ./scripts/build.sh
   ```

## Troubleshooting

### Common Issues

**Browser crashes on startup**
- Try running with GPU acceleration disabled:
  ```bash
  ./build/CEFBrowser.app/Contents/MacOS/cef_browser --disable-gpu
  ```

**"CEF not found" error**
- Run the setup script:
  ```bash
  ./scripts/setup_cef.sh
  ```

**Permission denied errors**
- Make scripts executable:
  ```bash
  chmod +x scripts/*.sh
  ```

## Support

For support, please file an issue on the project repository or contact the maintainers.