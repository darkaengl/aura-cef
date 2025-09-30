# CEF Browser Project Information

## Overview

CEF Browser is a clean, modular implementation of a web browser using the Chromium Embedded Framework. This document provides information about the project's organization, architecture, and development approach.

## Version Information

- **Project Version**: 1.0.0
- **CEF Version**: 138.0.50 (or latest downloaded by setup script)
- **Last Updated**: September 30, 2025

## Architecture

The project follows a modular architecture with clean separation of concerns:

1. **Main Application (main.cpp)**
   - CEF initialization and shutdown
   - Command line parsing
   - Window creation
   - Message loop

2. **Browser Application (browser_app.h/cpp)**
   - Implements CefApp interface
   - Handles application-level callbacks
   - Can be extended for custom schemes, process handling

3. **Browser Client (browser_client.h/cpp)**
   - Implements CefClient interface
   - Handles browser window events
   - Manages browser lifecycle
   - Processes navigation events

## Design Goals

1. **Modularity**: Clean separation of concerns with well-defined interfaces
2. **Simplicity**: Focus on core functionality without unnecessary complexity
3. **Maintainability**: Easy-to-understand code structure with clear documentation
4. **Automation**: One-command setup, build, and run processes
5. **Extensibility**: Easy to add new features and customize

## Platform Support

Currently, the project is optimized for:
- macOS 11.0+ on ARM64 architecture (Apple Silicon)

Future versions may add support for:
- macOS Intel (x86_64)
- Windows
- Linux

## Technology Stack

- **CEF**: Chromium Embedded Framework for browser functionality
- **C++17**: Modern C++ features for better code quality
- **CMake**: Cross-platform build system
- **Ninja**: Fast build tool
- **Shell Scripts**: For automation

## Project Structure Rationale

### Source Organization (`src/`)

The source code is organized to separate the main application logic from the browser-specific components:
- **main.cpp**: Single responsibility of initializing and running the application
- **browser_app.h/cpp**: Handles application-level CEF integration
- **browser_client.h/cpp**: Handles browser-specific behavior and events

### Script Organization (`scripts/`)

Scripts are provided to automate common tasks:
- **setup_cef.sh**: Downloads and configures CEF dependencies
- **build.sh**: Builds the browser application
- **run_browser.sh**: Runs the built application

### Documentation Organization (`docs/`)

Documentation is separated by audience:
- **GETTING_STARTED.md**: For new users to quickly get up and running
- **USER_GUIDE.md**: For end users of the browser
- **TECHNICAL_GUIDE.md**: For developers who want to understand or extend the code

## Coding Standards

The project follows these coding standards:
1. Use modern C++ features where appropriate
2. Follow CEF naming conventions for consistency
3. Use clear, descriptive names for classes and methods
4. Include comments for non-obvious code sections
5. Separate interface from implementation

## Future Development

Planned features for future versions:
1. Tab-based browsing
2. Bookmarks management
3. Download manager
4. Custom UI elements
5. Cross-platform support
6. Extension system

## Contributing

Contributors should:
1. Follow existing coding style
2. Add tests for new functionality
3. Update documentation
4. Ensure cross-platform compatibility when possible

## License

This project is open source and available under permissive licensing. See LICENSE file for details.

## Acknowledgments

This project builds upon:
- Chromium Embedded Framework (CEF)
- The Chromium project
- Various open source tools and libraries