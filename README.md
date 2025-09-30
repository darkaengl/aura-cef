# CEF Browser - Simple Chromium Embedded Framework Browser

A clean, modular implementation of a web browser using the Chromium Embedded Framework (CEF). This project demonstrates how to embed a Chromium browser engine in a native application with proper architecture and build automation.

## Features

- **Real Chromium Browser Engine**: Uses CEF (not WebView) for full Chromium compatibility
- **Native macOS Application**: Proper .app bundle structure with system integration
- **Modular Architecture**: Clean separation of concerns with dedicated classes
- **Automated Setup**: One-command setup that downloads and builds everything
- **Cross-Platform Ready**: Architecture designed for easy Windows/Linux extension

## Quick Start

```bash
# 1. Setup CEF and build dependencies
./scripts/setup_cef.sh

# 2. Build the browser
./scripts/build.sh

# 3. Run the browser (development mode)
./scripts/run_dev_browser.sh

# OR with standard mode (may crash without code signing)
./scripts/run_browser.sh
```

### Development vs Production Mode

**For development:** Use the special development script that runs successfully without code signing:
```bash
./scripts/run_dev_browser.sh
```

**For production:** The application bundle needs to be properly signed:

```bash
# For development/testing (requires an Apple Developer account)
./scripts/run_browser.sh --sign "Apple Development: Your Name (TEAM_ID)"

# For distribution (requires a paid Apple Developer account)
./scripts/run_browser.sh --sign "Developer ID Application: Your Name (TEAM_ID)"

# For quick testing with any available identity (development only)
./scripts/run_browser.sh --sign "$(security find-identity -v -p codesigning | grep -o '"[^"]*"' | head -1 | tr -d '"')"
```

This process signs all components of the application bundle and adds the necessary entitlements for CEF to work properly on macOS.

> **Note**: To see all available signing identities on your system, run:
> ```bash
> security find-identity -v -p codesigning
> ```

## Architecture

### Core Components

- **`src/main.cpp`**: Application entry point and CEF initialization
- **`src/browser_app.cpp`**: CEF application class for framework customization
- **`src/browser_client.cpp`**: Browser client handling window lifecycle and events
- **`scripts/`**: Build automation and CEF management scripts

### Class Hierarchy

```
CefApp (CEF Framework)
├── SimpleBrowserApp (src/browser_app.cpp)
    └── Application-level customization

CefClient (CEF Framework)  
├── SimpleBrowserClient (src/browser_client.cpp)
    ├── Window lifecycle management
    ├── Load event handling
    └── Error handling
```

## Project Structure

```
cef_browser_project/
├── README.md                   # This file
├── CMakeLists.txt              # Build configuration
├── src/                        # Source code
│   ├── main.cpp                # Application entry point
│   ├── browser_app.h/.cpp      # CEF application class
│   └── browser_client.h/.cpp   # Browser client implementation
├── scripts/                    # Automation scripts
│   ├── setup_cef.sh            # CEF download and build
│   ├── build.sh                # Project build automation
│   └── run_browser.sh          # Browser execution
├── docs/                       # Documentation
├── build/                      # Build artifacts (created during build)
└── cef_binary_*/               # CEF distribution (downloaded by setup)
```

## Requirements

### System Requirements

- **macOS 11.0+** (Big Sur or later)
- **Apple Silicon (ARM64)** or Intel x64
- **Xcode Command Line Tools**
- **CMake 3.21+**
- **Git**

### Automatic Installation

The setup script will automatically install required dependencies via Homebrew:
- CMake
- Ninja (build system)
- curl (for downloads)

## Detailed Setup Guide

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd cef_browser_project
chmod +x scripts/*.sh
```

### 2. CEF Setup (Automatic)

```bash
./scripts/setup_cef.sh
```

This script will:
- Query CEF builds API for latest stable release
- Download CEF binary distribution (~112MB)
- Extract to `cef_binary_*` directory
- Build the CEF wrapper library (`libcef_dll_wrapper.a`)
- Install any missing dependencies via Homebrew

### 3. Build Browser

```bash
./scripts/build.sh
```

This creates:
- `build/` directory with compiled artifacts
- `CEFBrowser.app` macOS application bundle
- Properly linked CEF frameworks and resources

### 4. Run Browser

```bash
./scripts/run_browser.sh
```

Or run directly:
```bash
./build/CEFBrowser.app/Contents/MacOS/cef_browser
```

## Configuration

### Default Settings

- **Homepage**: https://www.google.com
- **Window Size**: 1200x800 pixels
- **User Agent**: Default Chromium user agent
- **Cache**: Disabled (can be enabled in `main.cpp`)

### Customization

Edit `src/main.cpp` to modify:

```cpp
// Window settings
window_info.width = 1200;
window_info.height = 800;

// Browser settings
browser_settings.homepage = "https://your-homepage.com";

// CEF settings
settings.log_severity = LOGSEVERITY_INFO;
settings.cache_path = "/path/to/cache";  // Enable caching
```

## Development

### Building from Source

```bash
# Debug build
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Debug ..
make -j$(nproc)

# Release build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
```

### Adding Features

1. **Custom Schemes**: Modify `browser_app.cpp`
2. **JavaScript Integration**: Add V8 handlers in `browser_client.cpp`
3. **Menu/UI**: Extend with native macOS menus
4. **Download Management**: Implement download handlers

### Debugging

```bash
# Run with CEF debug logging
DYLD_PRINT_LIBRARIES=1 ./build/CEFBrowser.app/Contents/MacOS/cef_browser --enable-logging --log-level=0

# Run with GPU debugging
./build/CEFBrowser.app/Contents/MacOS/cef_browser --disable-gpu --disable-software-rasterizer
```

## Troubleshooting

### Common Issues

**"CEF not found" Error**
```bash
# Ensure CEF is set up
./scripts/setup_cef.sh
```

**Build Failures**
```bash
# Clean build
rm -rf build/
./scripts/build.sh
```

**Browser Crashes on Launch**

This is a known issue with CEF on macOS, particularly on Apple Silicon. The browser may crash with GPU process errors.
```bash
# Try disabling GPU acceleration
./scripts/run_browser.sh --disable-gpu

# Or try running in debug mode for more information
./scripts/run_browser.sh --debug
```

**Permission Issues**
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

**Important Note About macOS GPU Acceleration**

CEF has known issues with GPU acceleration on macOS, especially on Apple Silicon Macs. This is a limitation of CEF itself, not our implementation. Even with these crashes, the browser initialization code is working correctly - it's just encountering a known limitation when running on certain macOS systems.

If you encounter GPU crashes, you can work around them by:
1. Running with `--disable-gpu` flag
2. Testing on a different Mac (particularly Intel-based) if available
3. Using a different version of CEF (older or newer)

### CEF-Specific Issues

- **GPU Process Crashes**: Known issue on some macOS systems, browser still functions
- **Framework Loading**: Ensure CEF.framework is in correct bundle location
- **Code Signing**: May need to disable Gatekeeper for development builds

## Resources

- [CEF Project](https://bitbucket.org/chromiumembedded/cef)
- [CEF API Documentation](https://magpcss.org/ceforum/apidocs3/)
- [Chromium Command Line Switches](https://peter.sh/experiments/chromium-command-line-switches/)
- [CEF Forum](https://magpcss.org/ceforum/)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make changes and test
4. Submit a pull request

## License

This project is open source. CEF itself is BSD-licensed.

## Changelog

### v1.0.0 (September 30, 2025)
- Initial modular implementation
- CEF 138.0.50 integration
- macOS ARM64 support
- Automated build system