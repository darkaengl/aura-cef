// CEF Browser - Main Application Entry Point
// This is the main entry point for the CEF browser application

#include "browser_app.h"
#include "browser_client.h"
#include <iostream>
#include <string>
#include <unistd.h>
#include <limits.h>  // For PATH_MAX

int main(int argc, char* argv[]) {
    std::cout << "🚀 Starting CEF Browser..." << std::endl;
    
    // Initialize CEF with original command line arguments
    CefMainArgs main_args(argc, argv);
    
    CefRefPtr<SimpleBrowserApp> app(new SimpleBrowserApp);
    
    /* 
     * IMPORTANT NOTE ON CODE SIGNING:
     * For production use on macOS, this application and all its components 
     * must be properly code signed with appropriate entitlements.
     * 
     * If you experience GPU process crashes with error_code=1003, it's likely
     * due to macOS security restrictions preventing the launch of unsigned 
     * helper processes.
     * 
     * Solutions:
     * 1. For development: Use --disable-gpu flag
     * 2. For production: Sign all components with:
     *    ./scripts/run_browser.sh --sign "Developer ID Application: Your Name"
     */
    
    // Execute the secondary process, if any
    int exit_code = CefExecuteProcess(main_args, app, nullptr);
    if (exit_code >= 0) {
        std::cout << "👶 Secondary process exiting with code: " << exit_code << std::endl;
        return exit_code;
    }
    
    // Parse command line arguments
    CefRefPtr<CefCommandLine> command_line = CefCommandLine::CreateCommandLine();
    #if defined(OS_WIN)
        command_line->InitFromString(::GetCommandLineW());
    #else
        command_line->InitFromArgv(argc, argv);
    #endif

    // Apply extreme GPU disabling for macOS to avoid code signing requirements
    std::cout << "🔧 Applying CEF workarounds for macOS unsigned development..." << std::endl;
    
    // Check if GPU should be explicitly enabled (only when properly code signed)
    bool enable_gpu = command_line->HasSwitch("enable-gpu");
    
    // Apply command line switches
    if (!enable_gpu) {
        // These flags completely disable GPU usage to avoid the process launch failures
        std::cout << "  → Disabling GPU processes and hardware acceleration" << std::endl;
        
        // GPU process disabling
        command_line->AppendSwitch("disable-gpu");
        command_line->AppendSwitch("disable-gpu-compositing");
        command_line->AppendSwitch("disable-gpu-sandbox");
        command_line->AppendSwitch("disable-gpu-vsync");
        
        // Acceleration disabling
        command_line->AppendSwitch("disable-accelerated-video-decode");
        command_line->AppendSwitch("disable-accelerated-2d-canvas");
        command_line->AppendSwitch("disable-accelerated-painting");
        command_line->AppendSwitch("disable-webgl");
        command_line->AppendSwitch("disable-software-rasterizer");
        
        // Additional process disabling
        command_line->AppendSwitch("single-process");
        command_line->AppendSwitch("disable-gpu-process-for-dx12-info-collection");
        command_line->AppendSwitch("disable-features=UseSkiaRenderer,CanvasOopRasterization");
    } else {
        std::cout << "⚠️  Running with GPU enabled - REQUIRES proper code signing" << std::endl;
    }
    
    // CEF settings
    CefSettings settings;
    
    // Disable sandbox for development builds - required on macOS
    settings.no_sandbox = true;
    
    // Configure graphics settings based on GPU mode
    if (!enable_gpu) {
        // Use software rendering and single process mode where possible
        settings.windowless_rendering_enabled = true;
        
        // Explicitly disable the GPU process and hardware acceleration
        settings.background_color = 0xFFFFFFFF;  // Opaque white background
        
        // Set additional command-line switches directly
        // Note: command_line_args_disabled is not a string parameter in newer CEF
    }
    
    // Set a cache path to avoid warnings - use absolute path
    char current_dir[PATH_MAX];
    if (getcwd(current_dir, sizeof(current_dir))) {
        std::string cache_path = std::string(current_dir) + "/browser_cache";
        CefString(&settings.root_cache_path).FromASCII(cache_path.c_str());
    }
    
    // Set logging level based on debug flag
    if (command_line->HasSwitch("debug")) {
        settings.log_severity = LOGSEVERITY_VERBOSE;
        std::cout << "🐞 Debug logging enabled" << std::endl;
    } else {
        // Disable logging to reduce console spam
        settings.log_severity = LOGSEVERITY_ERROR;
    }
    
    std::cout << "⚙️  Initializing CEF..." << std::endl;
    
    // Initialize CEF
    if (!CefInitialize(main_args, settings, app, nullptr)) {
        std::cout << "❌ Failed to initialize CEF!" << std::endl;
        return 1;
    }
    
    // Create browser window info
    CefWindowInfo window_info;
    
#ifdef __APPLE__
    // For macOS, create a windowed browser
    CefRect bounds(0, 0, 1200, 800);
    window_info.SetAsChild(nullptr, bounds);
#else
    window_info.SetAsPopup(nullptr, "Simple CEF Browser");
#endif
    
    // Browser settings
    CefBrowserSettings browser_settings;
    
    // Create the browser client
    CefRefPtr<SimpleBrowserClient> client(new SimpleBrowserClient);
    
    std::cout << "🪟 Creating browser window..." << std::endl;
    
    // Create the browser - start with a simple HTML page
    CefBrowserHost::CreateBrowser(window_info, client, "data:text/html,<h1>🎉 CEF Browser Works!</h1><p>This is a real browser powered by Chromium Embedded Framework.</p><p>Try visiting: <a href='https://www.google.com'>Google</a></p>", browser_settings, nullptr, nullptr);
    
    std::cout << "🔄 Running message loop..." << std::endl;
    std::cout << "💡 The browser window should appear now. Close it to exit." << std::endl;
    
    // Run the message loop
    CefRunMessageLoop();
    
    std::cout << "🔚 Shutting down CEF..." << std::endl;
    
    // Shutdown CEF
    CefShutdown();
    
    std::cout << "✅ Browser closed successfully." << std::endl;
    
    // No need to clean up new_argv as it was removed
    
    return 0;
}