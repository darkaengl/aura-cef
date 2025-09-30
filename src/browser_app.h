// CEF Browser - Browser Application Header
// This file contains the CEF application class declaration

#ifndef BROWSER_APP_H
#define BROWSER_APP_H

#include "cef_app.h"

class SimpleBrowserApp : public CefApp {
public:
    SimpleBrowserApp();

private:
    IMPLEMENT_REFCOUNTING(SimpleBrowserApp);
};

#endif // BROWSER_APP_H