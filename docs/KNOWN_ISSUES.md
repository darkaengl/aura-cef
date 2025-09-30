# Known Issues in CEF Browser

This document details known issues with the CEF Browser implementation and provides troubleshooting steps and workarounds.

## GPU Process Crashes

### Symptom

When running the browser, you may encounter errors like this:

```
[ERROR:content/browser/gpu/gpu_process_host.cc:951] GPU process launch failed: error_code=1003
[FATAL:content/browser/gpu/gpu_data_manager_impl_private.cc:415] GPU process isn't usable. Goodbye.
```

This indicates that the browser's Graphics Processing Unit (GPU) process failed to initialize, causing the browser to crash.

### Cause

This issue occurs when your CEF application repeatedly fails to launch its dedicated GPU process on macOS. After several failed attempts, the main browser process gives up and triggers a fatal crash.

The key error messages reveal the sequence of failures:

* `GPU process launch failed: error_code=1003`: This is the root cause. The main application process cannot start the helper process responsible for hardware-accelerated rendering.
* `Network service crashed`: This is a secondary effect. Core services like networking often depend on the successful initialization of other components. The GPU failure destabilizes the environment, causing the network service to crash as well.
* `FATAL: ... GPU process isn't usable. Goodbye.`: This is the final result. After failing to launch the GPU process multiple times, the application determines it cannot function correctly and terminates itself.

#### Why This Happens on macOS

On macOS, this problem is most frequently related to the operating system's security and sandboxing rules, especially regarding how applications are signed and structured:

1. **Code Signing & Entitlements:** macOS is very strict about allowing one process to launch another. For your main application to launch the CEF helper process (which acts as the GPU process), it needs to be properly code-signed with the correct entitlements. A missing or incorrect entitlement can cause the OS to block the launch, leading to `error_code=1003`.

2. **Application Bundle Structure:** A CEF-based application on macOS requires a specific structure. The main app executable and the `Chromium Embedded Framework.framework` must be correctly placed. Inside the framework, there is a helper executable that gets launched for different roles (GPU, network, etc.). If this helper is missing, corrupted, or not signed correctly, the launch will fail.

3. **Software Incompatibility:** There might be an incompatibility between the version of CEF you are using and your version of macOS. Apple often introduces new security restrictions in OS updates that can break older versions of frameworks.

4. **GPU Driver Compatibility**: Issues between CEF's expectations and the actual GPU drivers installed.

5. **Apple Silicon Transition**: For ARM64 (Apple Silicon) systems, additional compatibility layers may cause issues.

## Solutions

### Working Solution for Development

We've created a special development script that successfully runs the browser without code signing:

```bash
./scripts/run_dev_browser.sh
```

This script uses the following techniques:
- Forces CEF to run in single-process mode using environment variables
- Disables all GPU acceleration and hardware rendering
- Bypasses the need for helper processes that require code signing
- Uses special environment flags to enable proper library loading

This approach is recommended for development and testing only. It may have limitations with some web features that require GPU acceleration or multi-process architecture.

### Other Temporary Workarounds

1. **Disable GPU Acceleration** (Default behavior now):
   The browser now automatically disables GPU acceleration on macOS to avoid crash issues.
   
   To force enable GPU (requires code signing):
   ```bash
   ./scripts/run_browser.sh --enable-gpu
   ```

2. **Use a More Permissive Cache Path**:
   ```cpp
   settings.cache_path = "/tmp/cef_cache";  // Use a globally writable location
   ```

3. **Try Running with Verbose Logging**:
   ```bash
   ./scripts/run_browser.sh --debug
   ```
   This might provide more insight into what's failing.

### Proper Fix: Code Signing and Entitlements

For production applications, the proper solution is to correctly sign your application and its components:

1. **Sign the Application Bundle**:
   ```bash
   ./scripts/run_browser.sh --sign "Developer ID Application: Your Name (TEAM_ID)"
   ```
   
   This will:
   - Sign all helper executables in the app bundle
   - Sign the Chromium Embedded Framework
   - Sign the main application executable
   - Add proper entitlements

2. **Required Entitlements**:
   The following entitlements have been included in `resources/cef_browser.entitlements`:
   - `com.apple.security.cs.disable-library-validation`: Allows loading of libraries that aren't signed by you
   - `com.apple.security.cs.allow-dyld-environment-variables`: Allows setting dynamic linker environment variables
   - `com.apple.security.cs.allow-jit`: Allows Just-In-Time compilation (needed for JavaScript)
   - `com.apple.security.cs.allow-unsigned-executable-memory`: Allows execution of dynamically generated code

   > **Note**: For production apps, only use the minimum necessary entitlements.

#### 2. The Correct Fix: Verify Code Signing and Entitlements

This is the proper long-term solution. You need to ensure your application bundle and the CEF framework are signed correctly.

* **Sign the Helper:** The helper executable inside the `Chromium Embedded Framework.framework/Versions/A/Helpers/` directory must be signed.
* **Sign the Framework:** The `Chromium Embedded Framework.framework` itself must be signed.
* **Sign the Main App:** Your main application executable must be signed.
* **Check Entitlements:** Your application's `.entitlements` file should contain keys that permit it to function correctly. For debugging, you can use more permissive entitlements, like disabling library validation, but be careful with these for production releases.
  * `com.apple.security.cs.disable-library-validation` can help if there are issues with loading the signed framework.
  * `com.apple.security.cs.allow-dyld-environment-variables` might also be needed.

#### 3. Update Your CEF Version

Check if you are using an older version of CEF. This issue is sometimes fixed in newer releases that are better aligned with the latest macOS updates. Upgrading to a more recent stable version of CEF can often resolve these kinds of environment-specific problems.

```bash
# Modify the setup_cef.sh script to download a specific version:
SPECIFIC_VERSION="138.0.49"  # Try various versions
```

#### 4. Update Your System

Ensure your system is fully up to date:

1. Update macOS to the latest version
2. Install any available system firmware updates
3. Check for GPU driver updates (particularly relevant for Intel Macs)

#### 6. Check for Interfering Software

Some software can interfere with CEF's GPU process:

1. Temporarily disable antivirus or security software
2. Close any GPU-intensive applications
3. Check for browser extensions or plugins that might be conflicting

#### 7. Build CEF with Custom Flags

For advanced users, building CEF from source with custom flags may resolve the issue:

```bash
# This requires downloading and building the full CEF source code
# See the CEF wiki for detailed instructions
```

### Alternative Approach: CEF Headless Mode

If you don't need a visible browser window and are primarily using CEF for web content processing:

```cpp
// In main.cpp:
settings.windowless_rendering_enabled = true;

// Then create an off-screen browser:
CefWindowInfo window_info;
window_info.SetAsWindowless(nullptr);  // No parent window
```

### Advanced Troubleshooting

#### Debugging the Process Launch Failure

To get more insight into why the GPU process launch is failing:

1. **Enable Verbose Logging**:
   ```cpp
   settings.log_severity = LOGSEVERITY_VERBOSE;
   ```

2. **Check for Helper Processes**:
   When running your application, monitor for any helper processes in Activity Monitor.
   If they briefly appear and then disappear, this confirms a launch issue.

3. **Examine Code Signing**:
   ```bash
   # Check code signing on the main app
   codesign -vvv ./build/cef_browser.app
   
   # Check code signing on the framework
   codesign -vvv ./build/cef_browser.app/Contents/Frameworks/Chromium\ Embedded\ Framework.framework
   
   # Check code signing on the helper
   codesign -vvv ./build/cef_browser.app/Contents/Frameworks/Chromium\ Embedded\ Framework.framework/Versions/A/Helpers/cef_helper.app
   ```

4. **Inspect Bundle Structure**:
   Ensure that your application bundle has the correct structure:
   ```bash
   # Check application bundle structure
   find ./build/cef_browser.app -type f | grep -v "\.dSYM" | sort
   ```

5. **Enable Environment Variables for Debugging**:
   ```bash
   DYLD_PRINT_LIBRARIES=1 ./build/cef_browser.app/Contents/MacOS/cef_browser
   ```

### Understanding the Error Codes

- **error_code=1003**: This specifically indicates a process launch failure due to macOS security restrictions, incorrect code signing, or missing entitlements.

- **Network service crashed**: This secondary error occurs because services depend on each other, and the GPU process failure causes a cascade of failures.

- **GPU process isn't usable**: This means that CEF attempted to launch the GPU process multiple times but failed consistently, leading to the decision to terminate the browser.

## Platform-Specific Notes

### macOS (Apple Silicon/ARM64)

Apple Silicon Macs have the most reported issues with CEF's GPU process due to:

1. Relatively new architecture with ongoing compatibility work
2. Changes in how Metal (Apple's graphics API) interacts with applications
3. Translation layers when running x86 code on ARM architecture

### macOS (Intel/x86_64)

Intel Macs generally have fewer issues but can still experience GPU process crashes if:

1. Using older macOS versions with newer CEF builds
2. Running with outdated GPU drivers
3. Using integrated Intel graphics with certain CEF versions

## Other Known Issues

### 1. Slow Startup

CEF initialization can be slow, particularly on first run as it sets up various caches and processes.

### 2. Memory Usage

CEF browsers use significant memory as they create multiple processes. This is expected behavior for Chromium-based browsers.

### 3. Missing GUI Elements

This minimal implementation doesn't include:
- URL bar
- Navigation buttons
- Menu
- Status bar

These would need to be implemented separately using platform-native UI toolkits or HTML-based UI.