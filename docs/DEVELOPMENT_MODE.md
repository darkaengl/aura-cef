# Development Mode Solution for CEF Browser

This document explains the special development mode that allows running the CEF browser without code signing on macOS.

## The Challenge

On macOS, CEF applications normally require:

1. Proper code signing with developer certificates
2. Correct entitlements
3. Multiple helper processes (browser, GPU, renderer)
4. Properly structured application bundle

Without these, the application typically crashes with `GPU process launch failed: error_code=1003`.

## Our Solution

We've implemented a special development mode through the `run_dev_browser.sh` script that works without code signing. Here's how it works:

### 1. Single Process Mode

Instead of using CEF's multi-process architecture (which requires launching signed helper processes), we force everything to run in a single process:

```bash
export CEF_SINGLE_PROCESS=1
```

This means the browser, renderer, and GPU processes all run in the same process space, avoiding the need for launching helpers.

### 2. Environment Variable Control

We set specific environment variables that modify how CEF operates:

```bash
export DYLD_PRINT_LIBRARIES=1
export DYLD_PRINT_LIBRARIES_POST_LAUNCH=1
export CEF_USE_SANDBOX=0
export GOOGLE_LOGINS_ENABLED=0
```

These variables help with debugging, disable sandboxing (which would require entitlements), and disable features that might cause additional security checks.

### 3. Command-Line Switches

We apply multiple command-line switches to disable features that would normally require helper processes or GPU acceleration:

```bash
--single-process
--disable-gpu
--disable-software-rasterizer
--disable-extensions
--disable-gpu-compositing
--disable-gpu-sandbox
--no-sandbox
```

These switches ensure CEF doesn't attempt to use features that would require code signing or additional processes.

## Limitations

This development mode has some limitations:

1. **Stability**: The browser may crash after extended use or when visiting complex websites. This is expected behavior in single-process mode, where one component crash affects the entire application.

2. **Performance**: Single-process mode is slower than the multi-process architecture.

3. **Security**: Disabling the sandbox reduces security isolation.

4. **Web Compatibility**: Some web features requiring hardware acceleration won't work.

5. **Development Only**: Not suitable for production environments.

When the browser crashes, you'll typically see stack traces related to AppKit or other macOS frameworks. These crashes are related to running Chromium in single-process mode, which it wasn't designed for. However, the browser remains usable for basic development and testing purposes.

## When to Use Production Mode

For production deployments, you should use the proper code signing approach:

```bash
./scripts/run_browser.sh --sign "Developer ID Application: Your Name (TEAM_ID)"
```

This ensures full functionality, better performance, and compatibility with all web features.

## Technical Details

### Why Single-Process Mode Works

CEF is based on Chromium, which normally uses a multi-process architecture for security and stability. Each tab, extension, and major subsystem (like GPU acceleration) runs in its own process. This provides isolation but requires each helper process to be properly signed and have appropriate entitlements.

By running in single-process mode, we avoid the need for macOS to launch these helper processes. This comes at the cost of reduced stability (a crash in any component can bring down the entire browser) and potentially reduced performance (no parallel processing).

### Environment Variables Explained

- `CEF_SINGLE_PROCESS=1`: Forces CEF to run everything in a single process
- `DYLD_PRINT_LIBRARIES=1`: Shows which dynamic libraries are loaded (helpful for debugging)
- `CEF_USE_SANDBOX=0`: Disables the Chromium sandbox, which would normally require entitlements

### Additional Resources

- [CEF Wiki - macOS Notes](https://bitbucket.org/chromiumembedded/cef/wiki/MacOSNotes.md)
- [Chromium Multi-Process Architecture](https://www.chromium.org/developers/design-documents/multi-process-architecture/)