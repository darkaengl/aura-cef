# CEF Browser Project Summary

## Issue Overview

This project faced a significant challenge: the CEF browser would crash with `GPU process launch failed: error_code=1003` on macOS due to code signing requirements. This issue occurs because:

1. CEF uses a multi-process architecture where the main process launches helper processes
2. On macOS, process launching is restricted and requires proper code signing and entitlements
3. Without code signing, the GPU process fails to launch, crashing the browser

## Solutions Implemented

We've created two distinct solutions to address this issue:

### 1. Development Mode Solution (No Code Signing Required)

We created `scripts/run_dev_browser.sh` that:
- Forces CEF to run in single-process mode (`CEF_SINGLE_PROCESS=1`)
- Disables the sandbox (`CEF_USE_SANDBOX=0`)
- Uses command-line switches to disable GPU acceleration (`--disable-gpu`, etc.)
- Bypasses the need for helper processes

This approach allows the browser to run without code signing, making it ideal for development and testing. The browser will have some stability limitations but remains functional for basic browsing.

### 2. Production Mode Solution (With Code Signing)

For production use, we've implemented a proper code signing solution:
- Created `scripts/sign_app.sh` to sign all application components
- Included `resources/cef_browser.entitlements` with necessary permissions
- Updated `scripts/run_browser.sh` with a `--sign` option
- Added comprehensive documentation about code signing requirements

## Documentation

We've added detailed documentation to explain these approaches:

1. `docs/KNOWN_ISSUES.md` - Explains the GPU process crash issue and solutions
2. `docs/DEVELOPMENT_MODE.md` - Details the special development mode approach
3. `docs/CODE_SIGNING.md` - Explains code signing requirements for production
4. Updated `README.md` with instructions for both development and production use

## Technical Implementation

Key technical components:

1. Environment variables to control CEF behavior:
   - `CEF_SINGLE_PROCESS=1` - Forces single-process mode
   - `CEF_USE_SANDBOX=0` - Disables the sandbox

2. Command-line switches to disable GPU features:
   - `--disable-gpu` - Disables GPU hardware acceleration
   - `--single-process` - Reinforces the single-process mode

3. Code signing tools:
   - Proper signing order (helpers → framework → main executable)
   - Entitlements for library validation and JIT compilation

## Usage Instructions

### For Development (No Code Signing)

```bash
./scripts/run_dev_browser.sh
```

### For Production (With Code Signing)

```bash
./scripts/run_browser.sh --sign "Developer ID Application: Your Name (TEAM_ID)"
```

## Conclusion

By implementing these dual solutions, we've created a CEF browser that works in both development and production environments. The development mode allows for quick testing without the complexities of code signing, while the production mode provides a proper long-term solution with full functionality.

This approach balances practical development needs with proper security requirements, making the project more accessible while still providing a path to proper production deployment.