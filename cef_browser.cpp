// Real CEF Browser - A working implementation
#include "cef_app.h"
#include "cef_browser.h"
#include "cef_client.h"
#include "cef_life_span_handler.h"
#include "cef_load_handler.h"
#include <vector>
#include <iostream>

class SimpleBrowserClient : public CefClient,
                           public CefLifeSpanHandler,
                           public CefLoadHandler {
public:
    SimpleBrowserClient() {}

    // CefClient methods
    virtual CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override {
        return this;
    }

    virtual CefRefPtr<CefLoadHandler> GetLoadHandler() override {
        return this;
    }

    // CefLifeSpanHandler methods
    virtual void OnAfterCreated(CefRefPtr<CefBrowser> browser) override {
        std::cout << "🌐 Browser window created!" << std::endl;
        browser_list_.push_back(browser);
    }

    virtual bool DoClose(CefRefPtr<CefBrowser> browser) override {
        return false;
    }

    virtual void OnBeforeClose(CefRefPtr<CefBrowser> browser) override {
        std::cout << "🔒 Browser window closing..." << std::endl;
        // Remove from list
        for (auto it = browser_list_.begin(); it != browser_list_.end(); ++it) {
            if ((*it)->IsSame(browser)) {
                browser_list_.erase(it);
                break;
            }
        }

        if (browser_list_.empty()) {
            CefQuitMessageLoop();
        }
    }

    // CefLoadHandler methods
    virtual void OnLoadEnd(CefRefPtr<CefBrowser> browser,
                          CefRefPtr<CefFrame> frame,
                          int httpStatusCode) override {
        std::cout << "✅ Page loaded successfully (Status: " << httpStatusCode << ")" << std::endl;
    }

    virtual void OnLoadError(CefRefPtr<CefBrowser> browser,
                           CefRefPtr<CefFrame> frame,
                           ErrorCode errorCode,
                           const CefString& errorText,
                           const CefString& failedUrl) override {
        std::cout << "❌ Load error: " << errorText.ToString() 
                  << " (URL: " << failedUrl.ToString() << ")" << std::endl;
    }

private:
    std::vector<CefRefPtr<CefBrowser>> browser_list_;

    IMPLEMENT_REFCOUNTING(SimpleBrowserClient);
};

class SimpleBrowserApp : public CefApp {
public:
    SimpleBrowserApp() {}

private:
    IMPLEMENT_REFCOUNTING(SimpleBrowserApp);
};

int main(int argc, char* argv[]) {
    std::cout << "🚀 Starting CEF Browser..." << std::endl;
    
    // Add command line switches to disable GPU acceleration
    char** new_argv = new char*[argc + 3];
    for (int i = 0; i < argc; i++) {
        new_argv[i] = argv[i];
    }
    new_argv[argc] = (char*)"--disable-gpu";
    new_argv[argc + 1] = (char*)"--disable-gpu-sandbox";
    new_argv[argc + 2] = nullptr;
    
    // Initialize CEF
    CefMainArgs main_args(argc + 2, new_argv);
    
    CefRefPtr<SimpleBrowserApp> app(new SimpleBrowserApp);
    
    // Execute the secondary process, if any
    int exit_code = CefExecuteProcess(main_args, app, nullptr);
    if (exit_code >= 0) {
        std::cout << "👶 Secondary process exiting with code: " << exit_code << std::endl;
        return exit_code;
    }
    
    // CEF settings
    CefSettings settings;
    settings.no_sandbox = true;
    settings.windowless_rendering_enabled = false;
    
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
    
    return 0;
}