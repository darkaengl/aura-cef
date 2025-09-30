// CEF Browser - Browser Client Header
// This file contains the browser client class declarations

#ifndef BROWSER_CLIENT_H
#define BROWSER_CLIENT_H

#include "cef_app.h"
#include "cef_browser.h"
#include "cef_client.h"
#include "cef_life_span_handler.h"
#include "cef_load_handler.h"
#include <vector>

class SimpleBrowserClient : public CefClient,
                           public CefLifeSpanHandler,
                           public CefLoadHandler {
public:
    SimpleBrowserClient();

    // CefClient methods
    virtual CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override;
    virtual CefRefPtr<CefLoadHandler> GetLoadHandler() override;

    // CefLifeSpanHandler methods
    virtual void OnAfterCreated(CefRefPtr<CefBrowser> browser) override;
    virtual bool DoClose(CefRefPtr<CefBrowser> browser) override;
    virtual void OnBeforeClose(CefRefPtr<CefBrowser> browser) override;

    // CefLoadHandler methods
    virtual void OnLoadEnd(CefRefPtr<CefBrowser> browser,
                          CefRefPtr<CefFrame> frame,
                          int httpStatusCode) override;
    virtual void OnLoadError(CefRefPtr<CefBrowser> browser,
                           CefRefPtr<CefFrame> frame,
                           ErrorCode errorCode,
                           const CefString& errorText,
                           const CefString& failedUrl) override;

private:
    std::vector<CefRefPtr<CefBrowser>> browser_list_;

    IMPLEMENT_REFCOUNTING(SimpleBrowserClient);
};

#endif // BROWSER_CLIENT_H