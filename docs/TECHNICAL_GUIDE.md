# CEF Browser Technical Guide

This document provides detailed technical information about the CEF Browser implementation.

## CEF Overview

The Chromium Embedded Framework (CEF) provides a framework for embedding Chromium-based browsers in other applications. This project uses CEF to create a standalone web browser application.

## Key Components

### 1. Main Application Entry Point (`src/main.cpp`)

The main application entry point is responsible for:

- Initializing the CEF framework
- Setting up command-line arguments
- Creating the browser window
- Running the message loop
- Shutting down the CEF framework when done

Key initialization code:

```cpp
// Initialize CEF
CefMainArgs main_args(argc, argv);
CefRefPtr<SimpleBrowserApp> app(new SimpleBrowserApp);
    
int exit_code = CefExecuteProcess(main_args, app, nullptr);
if (exit_code >= 0)
    return exit_code;

// CEF settings
CefSettings settings;
settings.no_sandbox = true;
settings.log_severity = LOGSEVERITY_INFO;
settings.multi_threaded_message_loop = false;
    
// Initialize CEF
CefInitialize(main_args, settings, app, nullptr);

// Create browser window
CefRefPtr<SimpleBrowserClient> client(new SimpleBrowserClient);
CefWindowInfo window_info;
CefBrowserSettings browser_settings;
window_info.x = 0;
window_info.y = 0;
window_info.width = 1200;
window_info.height = 800;
CefBrowserHost::CreateBrowser(window_info, client, "https://www.google.com", 
                            browser_settings, nullptr, nullptr);

// Run message loop
CefRunMessageLoop();

// Shutdown
CefShutdown();
```

### 2. Browser Application (`src/browser_app.h/cpp`)

The `SimpleBrowserApp` class extends `CefApp` and handles application-level callbacks from CEF:

```cpp
class SimpleBrowserApp : public CefApp {
public:
    SimpleBrowserApp() {}

    // CefApp methods
    CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override { 
        return nullptr; 
    }

    // More application-level handlers can be implemented here

private:
    IMPLEMENT_REFCOUNTING(SimpleBrowserApp);
    DISALLOW_COPY_AND_ASSIGN(SimpleBrowserApp);
};
```

For more advanced implementations, you might add:
- Custom render process handlers
- Browser process handlers
- Resource bundle handlers
- Custom schemes

### 3. Browser Client (`src/browser_client.h/cpp`)

The `SimpleBrowserClient` class extends `CefClient` and handles browser-level events:

```cpp
class SimpleBrowserClient : public CefClient,
                           public CefDisplayHandler,
                           public CefLifeSpanHandler,
                           public CefLoadHandler {
public:
    SimpleBrowserClient() {}

    // CefClient methods
    CefRefPtr<CefDisplayHandler> GetDisplayHandler() override { 
        return this; 
    }
    CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override { 
        return this; 
    }
    CefRefPtr<CefLoadHandler> GetLoadHandler() override { 
        return this; 
    }

    // CefLifeSpanHandler methods
    void OnAfterCreated(CefRefPtr<CefBrowser> browser) override {
        browser_list_.push_back(browser);
    }
    
    bool DoClose(CefRefPtr<CefBrowser> browser) override {
        // Allow the close. For windowed browsers this will result in the OS close
        // event being sent.
        return false;
    }
    
    void OnBeforeClose(CefRefPtr<CefBrowser> browser) override {
        // Remove from the list of browsers.
        for (auto it = browser_list_.begin(); it != browser_list_.end(); ++it) {
            if ((*it)->IsSame(browser)) {
                browser_list_.erase(it);
                break;
            }
        }

        if (browser_list_.empty()) {
            // All browser windows have closed. Quit the message loop.
            CefQuitMessageLoop();
        }
    }

    // CefLoadHandler methods
    void OnLoadError(CefRefPtr<CefBrowser> browser,
                    CefRefPtr<CefFrame> frame,
                    ErrorCode errorCode,
                    const CefString& errorText,
                    const CefString& failedUrl) override {
        // Display a load error message.
        std::string html = "<html><body><h2>Failed to load URL: " +
                          std::string(failedUrl) +
                          "</h2><p>Error: " +
                          std::string(errorText) +
                          " (" + std::to_string(errorCode) + ")</p></body></html>";
        frame->LoadString(html, failedUrl);
    }

private:
    // List of browser windows.
    typedef std::list<CefRefPtr<CefBrowser>> BrowserList;
    BrowserList browser_list_;

    IMPLEMENT_REFCOUNTING(SimpleBrowserClient);
    DISALLOW_COPY_AND_ASSIGN(SimpleBrowserClient);
};
```

## Build System

### CMakeLists.txt

The build system uses CMake to find and link against the CEF libraries:

```cmake
cmake_minimum_required(VERSION 3.21)
project(CEFBrowser)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# For macOS
if(APPLE)
    set(CMAKE_OSX_ARCHITECTURES "arm64")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
endif()

# Add source directory to include path
include_directories(src)

# Find CEF - try a few common locations
find_path(CEF_ROOT
    NAMES
        include/cef_version.h
    PATHS
        ${CMAKE_CURRENT_SOURCE_DIR}/cef_binary_*
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/cef_binary_*
    NO_DEFAULT_PATH
)

if(CEF_ROOT)
    message(STATUS "Found CEF at: ${CEF_ROOT}")
    
    # Add CEF include directories
    include_directories(${CEF_ROOT})
    
    # Find the required libraries
    find_library(CEF_LIB_PATH
        NAMES cef libcef cef.lib
        PATHS
            ${CEF_ROOT}/Release
            ${CEF_ROOT}/build/Release
        NO_DEFAULT_PATH
    )
    
    find_library(CEF_WRAPPER_PATH
        NAMES libcef_dll_wrapper.a cef_dll_wrapper.lib
        PATHS
            ${CEF_ROOT}/build/libcef_dll_wrapper
            ${CEF_ROOT}/build/libcef_dll_wrapper/Release
        NO_DEFAULT_PATH
    )
    
    message(STATUS "CEF library: ${CEF_LIB_PATH}")
    message(STATUS "CEF wrapper: ${CEF_WRAPPER_PATH}")

    # Create the real CEF browser with modular sources
    add_executable(cef_browser 
        src/main.cpp
        src/browser_app.cpp
        src/browser_client.cpp
    )
    
    # Link with CEF
    target_link_libraries(cef_browser ${CEF_LIB_PATH} ${CEF_WRAPPER_PATH})
    
    # Include CEF headers
    target_include_directories(cef_browser PRIVATE ${CEF_ROOT})
    
    # macOS specific settings
    if(APPLE)
        # Create app bundle
        set_target_properties(cef_browser PROPERTIES
            MACOSX_BUNDLE TRUE
            MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
        )
        
        # Copy CEF framework to app bundle
        add_custom_command(TARGET cef_browser POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${CEF_ROOT}/Release/Chromium\ Embedded\ Framework.framework
                ${CMAKE_BINARY_DIR}/CEFBrowser.app/Contents/Frameworks/Chromium\ Embedded\ Framework.framework
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${CEF_ROOT}/Resources
                ${CMAKE_BINARY_DIR}/CEFBrowser.app/Contents/Frameworks/Chromium\ Embedded\ Framework.framework/Resources
        )
        
        # Create helper app if needed for CEF sandbox
        # (not included in this basic implementation)
    endif()
else()
    message(STATUS "CEF not found. Please run: scripts/setup_cef.sh")
    message(FATAL_ERROR "CEF binary distribution required")
endif()
```

## CEF Setup Script (`scripts/setup_cef.sh`)

The setup script automates downloading and configuring CEF:

```bash
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

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Homebrew. Please install it manually.${NC}"
        exit 1
    fi
fi

# Check for CMake
if ! command -v cmake &> /dev/null; then
    echo -e "${YELLOW}CMake not found. Installing...${NC}"
    brew install cmake
fi

# Check for Ninja
if ! command -v ninja &> /dev/null; then
    echo -e "${YELLOW}Ninja not found. Installing...${NC}"
    brew install ninja
fi

# Check for curl
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}curl not found. Installing...${NC}"
    brew install curl
fi

# Query CEF builds API for latest stable version
echo -e "\n${BLUE}Finding latest stable CEF version...${NC}"
CEF_API_URL="https://cef-builds.spotifycdn.com/api/cef_binary_builds"
LATEST_VERSION=$(curl -s "$CEF_API_URL" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Failed to query CEF API. Using fallback version.${NC}"
    LATEST_VERSION="138.0.50"
fi

echo -e "${GREEN}Found CEF version: $LATEST_VERSION${NC}"

# Determine platform
PLATFORM="macosarm64"
DISTRIBUTION="minimal"

# Generate download URL
DOWNLOAD_URL="https://cef-builds.spotifycdn.com/cef_binary_${LATEST_VERSION}_${PLATFORM}_${DISTRIBUTION}.tar.bz2"
DOWNLOAD_FILE="cef_binary_${LATEST_VERSION}_${PLATFORM}_${DISTRIBUTION}.tar.bz2"

echo -e "\n${BLUE}Downloading CEF binary distribution...${NC}"
echo "URL: $DOWNLOAD_URL"

if [ -f "$DOWNLOAD_FILE" ]; then
    echo -e "${YELLOW}Download file already exists. Skipping download.${NC}"
else
    curl -L -o "$DOWNLOAD_FILE" "$DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Download failed. Please check your internet connection and try again.${NC}"
        exit 1
    fi
fi

# Extract the archive
echo -e "\n${BLUE}Extracting CEF binary distribution...${NC}"
mkdir -p cef_binary_extract
tar -xjf "$DOWNLOAD_FILE" -C cef_binary_extract --strip-components=1
if [ $? -ne 0 ]; then
    echo -e "${RED}Extraction failed.${NC}"
    exit 1
fi

# Move to final location
CEF_DIR="cef_binary_${LATEST_VERSION}_${PLATFORM}_${DISTRIBUTION}"
if [ -d "$CEF_DIR" ]; then
    echo -e "${YELLOW}CEF directory already exists. Removing...${NC}"
    rm -rf "$CEF_DIR"
fi

mv cef_binary_extract "$CEF_DIR"

echo -e "\n${BLUE}Building CEF wrapper library...${NC}"

# Enter CEF directory and build the wrapper library
cd "$CEF_DIR" || exit 1
mkdir -p build
cd build || exit 1

# Configure and build
echo "Configuring with CMake..."
cmake -G "Ninja" -DPROJECT_ARCH="arm64" -DCMAKE_BUILD_TYPE=Release ..

if [ $? -ne 0 ]; then
    echo -e "${RED}CMake configuration failed.${NC}"
    exit 1
fi

echo "Building libcef_dll_wrapper..."
ninja libcef_dll_wrapper

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed.${NC}"
    exit 1
fi

# Go back to main directory
cd ../..

echo -e "\n${GREEN}CEF setup complete!${NC}"
echo "CEF binary distribution: $CEF_DIR"
echo -e "\n${YELLOW}You can now build the CEF browser:${NC}"
echo "1. ./scripts/build.sh"
echo "2. ./scripts/run_browser.sh"
```

## Extending the Browser

### Adding JavaScript Integration

To enable JavaScript callbacks from the browser to your native code:

1. Create a V8 handler class:
```cpp
class JSHandler : public CefV8Handler {
public:
    JSHandler() {}

    bool Execute(const CefString& name,
                 CefRefPtr<CefV8Value> object,
                 const CefV8ValueList& arguments,
                 CefRefPtr<CefV8Value>& retval,
                 CefString& exception) override {
        if (name == "myNativeFunction") {
            // Handle the JavaScript call
            std::string message = arguments[0]->GetStringValue();
            std::cout << "Called from JavaScript: " << message << std::endl;
            
            // Return a value to JavaScript
            retval = CefV8Value::CreateString("Response from native code");
            return true;
        }
        return false;
    }

    IMPLEMENT_REFCOUNTING(JSHandler);
};
```

2. Register the handler in your `RenderProcessHandler`:
```cpp
void OnContextCreated(CefRefPtr<CefBrowser> browser,
                     CefRefPtr<CefFrame> frame,
                     CefRefPtr<CefV8Context> context) override {
    // Retrieve the context's window object
    CefRefPtr<CefV8Value> window = context->GetGlobal();
    
    // Create a new V8 handler
    CefRefPtr<JSHandler> handler = new JSHandler();
    
    // Create a function
    CefRefPtr<CefV8Value> func = CefV8Value::CreateFunction("myNativeFunction", handler);
    
    // Add the function to the window object
    window->SetValue("myNativeFunction", func, V8_PROPERTY_ATTRIBUTE_NONE);
}
```

### Adding Custom Schemes

To handle custom URL schemes:

1. Register the scheme in your `SimpleBrowserApp`:
```cpp
void OnRegisterCustomSchemes(CefRawPtr<CefSchemeRegistrar> registrar) override {
    // Register "app" as a standard scheme
    registrar->AddCustomScheme("app", CEF_SCHEME_OPTION_STANDARD);
}
```

2. Create a scheme handler:
```cpp
class AppSchemeHandler : public CefResourceHandler {
public:
    AppSchemeHandler() {}

    bool ProcessRequest(CefRefPtr<CefRequest> request,
                       CefRefPtr<CefCallback> callback) override {
        // Parse the URL
        CefString url = request->GetURL();
        
        // Handle the request (example: app://page)
        if (url == "app://page") {
            data_ = "<html><body><h1>Custom App Page</h1></body></html>";
            mime_type_ = "text/html";
            callback->Continue();
            return true;
        }
        
        return false;
    }

    // Implement other required methods
    // ...

    IMPLEMENT_REFCOUNTING(AppSchemeHandler);
};
```

3. Register the handler factory in your `SimpleBrowserApp`:
```cpp
void OnRegisterSchemeHandlerFactory() override {
    CefRegisterSchemeHandlerFactory("app", "", new AppSchemeHandlerFactory());
}
```

## Advanced Features

### Handling File Downloads

To handle file downloads, implement the `CefDownloadHandler` interface:

```cpp
class DownloadHandler : public CefDownloadHandler {
public:
    DownloadHandler() {}

    void OnBeforeDownload(CefRefPtr<CefBrowser> browser,
                         CefRefPtr<CefDownloadItem> download_item,
                         const CefString& suggested_name,
                         CefRefPtr<CefBeforeDownloadCallback> callback) override {
        // Show save dialog or use default path
        callback->Continue("/path/to/downloads/" + suggested_name, false);
    }

    void OnDownloadUpdated(CefRefPtr<CefBrowser> browser,
                          CefRefPtr<CefDownloadItem> download_item,
                          CefRefPtr<CefDownloadItemCallback> callback) override {
        // Update progress UI
        if (download_item->IsComplete()) {
            std::cout << "Download complete: " << download_item->GetFullPath() << std::endl;
        } else if (download_item->IsCanceled()) {
            std::cout << "Download canceled" << std::endl;
        } else {
            int percent = static_cast<int>(download_item->GetPercentComplete());
            std::cout << "Download progress: " << percent << "%" << std::endl;
        }
    }

    IMPLEMENT_REFCOUNTING(DownloadHandler);
};
```

### Cookie Management

To manage cookies, use the `CefCookieManager`:

```cpp
// Get the global cookie manager
CefRefPtr<CefCookieManager> cookie_manager = CefCookieManager::GetGlobalManager(nullptr);

// Set a cookie
CefCookie cookie;
CefString(&cookie.name) = "name";
CefString(&cookie.value) = "value";
CefString(&cookie.domain) = "example.com";
CefString(&cookie.path) = "/";
cookie.has_expires = true;
cookie.expires.year = 2025;
cookie.expires.month = 1;
cookie.expires.day_of_month = 1;

cookie_manager->SetCookie("https://example.com", cookie, nullptr);

// Delete cookies
cookie_manager->DeleteCookies("https://example.com", "", nullptr);
```

## Performance Optimization

### Memory Management

CEF uses reference counting for memory management. Always ensure:

1. Every `CefRefPtr<>` object is properly created and destroyed
2. Use `IMPLEMENT_REFCOUNTING()` macro in your classes
3. Use `DISALLOW_COPY_AND_ASSIGN()` to prevent accidental copying

### Process Isolation

CEF uses multiple processes for security and stability:

1. **Browser process**: Main application process
2. **Renderer processes**: Web content rendering
3. **GPU process**: Hardware acceleration
4. **Utility processes**: Various tasks

Communication between processes happens via the `CefProcessMessage` API:

```cpp
// Send a message from browser to renderer
CefRefPtr<CefProcessMessage> msg = CefProcessMessage::Create("message_name");
msg->GetArgumentList()->SetString(0, "Hello renderer!");
browser->GetMainFrame()->SendProcessMessage(PID_RENDERER, msg);

// In the renderer process, handle the message:
bool OnProcessMessageReceived(CefRefPtr<CefBrowser> browser,
                            CefRefPtr<CefFrame> frame,
                            CefProcessId source_process,
                            CefRefPtr<CefProcessMessage> message) override {
    if (message->GetName() == "message_name") {
        std::string text = message->GetArgumentList()->GetString(0);
        // Process the message
        return true;
    }
    return false;
}
```

## Debugging CEF Applications

### Common Issues

1. **GPU Acceleration Issues**: On some systems, GPU acceleration can cause crashes. To disable:
   ```cpp
   CefCommandLine::CreateCommandLine()->AppendSwitch("disable-gpu");
   ```

2. **Framework Loading**: On macOS, ensure the CEF framework is in the correct location in the app bundle.

3. **Missing Resources**: CEF requires specific resources. Make sure `Resources/` folder is properly copied.

### Debug Logging

Enable detailed logging:

```cpp
settings.log_severity = LOGSEVERITY_VERBOSE;
```

Run with command-line flags:
```bash
./cef_browser --enable-logging --log-level=0
```

## References

- [CEF Project](https://bitbucket.org/chromiumembedded/cef)
- [CEF Forum](https://magpcss.org/ceforum/)
- [CEF API Documentation](https://cef-builds.spotifycdn.com/docs/index.html)