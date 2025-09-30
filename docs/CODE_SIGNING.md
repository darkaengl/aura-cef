# Code Signing & CEF on macOS

This document explains how code signing and entitlements work with CEF on macOS, why they're necessary, and how to implement them properly.

## Why Code Signing Is Necessary

CEF utilizes multiple processes to isolate web content and enhance security:

```
+---------------------+
|   Main Process      |
| (browser process)   |
+----------+----------+
           |
           | spawns
           v
+----------+----------+     +---------------------+
|   Renderer Process  |     |   GPU Process       |
| (web content)       |<--->| (graphics accel.)   |
+---------------------+     +---------------------+
           |
           | may spawn
           v
+---------------------+
|   Plugin Process    |
| (e.g., Flash)       |
+---------------------+
```

On macOS, due to security restrictions, an unsigned application cannot launch helper processes from inside application bundles. This results in the common `error_code=1003` when the GPU process tries to launch.

## Application Bundle Structure

For CEF to work properly on macOS, the bundle structure must be properly organized and signed:

```
cef_browser.app/
├── Contents/
│   ├── Frameworks/
│   │   ├── Chromium Embedded Framework.framework/  [SIGNED]
│   │   │   └── Versions/A/Helpers/
│   │   │       ├── cef_helper.app/                [SIGNED]
│   │   │       └── cef_gpu_helper.app/            [SIGNED]
│   │   └── [other frameworks]                     [SIGNED]
│   ├── MacOS/
│   │   └── cef_browser                            [SIGNED]
│   ├── Resources/
│   │   ├── app.icns
│   │   └── [other resources]
│   └── Info.plist
```

## Required Entitlements

The following entitlements are typically needed for CEF on macOS:

| Entitlement | Purpose |
|-------------|---------|
| `com.apple.security.cs.disable-library-validation` | Allows loading libraries not signed by the same team |
| `com.apple.security.cs.allow-dyld-environment-variables` | Allows environment variables to affect dynamic loading |
| `com.apple.security.cs.allow-jit` | Permits just-in-time compilation (needed for JavaScript) |
| `com.apple.security.cs.allow-unsigned-executable-memory` | Allows execution of dynamically generated code |

## Signing Process

1. Sign from the inside out:
   - Sign helper executables first
   - Then sign the framework
   - Finally sign the main app

2. Use the same identity for all components

3. Include proper entitlements at each level

## Testing vs. Production

For development and testing, self-signed certificates and more permissive entitlements are acceptable. For production, use a Developer ID certificate from Apple and limit entitlements to only what's necessary.

## Debugging Code Signing Issues

- Use `codesign -vvv` to verify signatures
- Use `spctl -a -v` to check if macOS will accept the app
- Check Console.app for system log messages about code signing

## References

- [Apple Code Signing Documentation](https://developer.apple.com/documentation/security/code_signing_services)
- [CEF Wiki - macOS Notes](https://bitbucket.org/chromiumembedded/cef/wiki/MacOSNotes.md)