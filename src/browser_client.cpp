// CEF Browser - Browser Client Implementation
// This file contains the main browser client classes and handlers

#include "browser_client.h"
#include <iostream>

SimpleBrowserClient::SimpleBrowserClient() {}

// CefClient methods
CefRefPtr<CefLifeSpanHandler> SimpleBrowserClient::GetLifeSpanHandler() {
    return this;
}

CefRefPtr<CefLoadHandler> SimpleBrowserClient::GetLoadHandler() {
    return this;
}

// CefLifeSpanHandler methods
void SimpleBrowserClient::OnAfterCreated(CefRefPtr<CefBrowser> browser) {
    std::cout << "🌐 Browser window created!" << std::endl;
    browser_list_.push_back(browser);
}

bool SimpleBrowserClient::DoClose(CefRefPtr<CefBrowser> browser) {
    return false;
}

void SimpleBrowserClient::OnBeforeClose(CefRefPtr<CefBrowser> browser) {
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
void SimpleBrowserClient::OnLoadEnd(CefRefPtr<CefBrowser> browser,
                      CefRefPtr<CefFrame> frame,
                      int httpStatusCode) {
    std::cout << "✅ Page loaded successfully (Status: " << httpStatusCode << ")" << std::endl;
}

void SimpleBrowserClient::OnLoadError(CefRefPtr<CefBrowser> browser,
                       CefRefPtr<CefFrame> frame,
                       ErrorCode errorCode,
                       const CefString& errorText,
                       const CefString& failedUrl) {
    std::cout << "❌ Load error: " << errorText.ToString() 
              << " (URL: " << failedUrl.ToString() << ")" << std::endl;
}