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

# Set CEF directory
set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/cef/current")

# Check if CEF is available
if(EXISTS "${CEF_ROOT}")
    message(STATUS "Found CEF at: ${CEF_ROOT}")
    
    # Add CEF include directories
    include_directories("${CEF_ROOT}")
    include_directories("${CEF_ROOT}/include")
    
    # Create the real CEF browser with modular sources
    add_executable(cef_browser 
        src/main.cpp
        src/browser_app.cpp
        src/browser_client.cpp
    )
    
    # Set up the app bundle for macOS
    if(APPLE)
        set_target_properties(cef_browser PROPERTIES
            MACOSX_BUNDLE TRUE
        )
        
        # Link CEF framework and system libraries
        target_link_libraries(cef_browser
            "${CEF_ROOT}/Release/Chromium Embedded Framework.framework/Chromium Embedded Framework"
            "${CEF_ROOT}/build_cef/libcef_dll_wrapper/libcef_dll_wrapper.a"
            "-framework Cocoa"
            "-framework AppKit"
        )
        
        # Copy CEF framework to app bundle
        add_custom_command(TARGET cef_browser POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_ROOT}/Release/Chromium Embedded Framework.framework"
            "$<TARGET_BUNDLE_DIR:cef_browser>/Contents/Frameworks/Chromium Embedded Framework.framework"
        )
        
        # Copy resources directory to app bundle
        add_custom_command(TARGET cef_browser POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory
            "$<TARGET_BUNDLE_DIR:cef_browser>/Contents/Resources"
        )
        
        # Copy and rename Info.plist
        set(INFO_PLIST_SRC "${CMAKE_CURRENT_SOURCE_DIR}/resources/Info.plist")
        set(INFO_PLIST_DST "$<TARGET_BUNDLE_DIR:cef_browser>/Contents/Info.plist")
        if(EXISTS "${INFO_PLIST_SRC}")
            add_custom_command(TARGET cef_browser POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy
                "${INFO_PLIST_SRC}"
                "${INFO_PLIST_DST}"
            )
        endif()
        
        # Make the scripts executable after build
        add_custom_command(TARGET cef_browser POST_BUILD
            COMMAND chmod +x "${CMAKE_CURRENT_SOURCE_DIR}/scripts/sign_app.sh"
            COMMENT "Making sign_app.sh executable"
        )
        
        # NOTE: Removed automatic code signing from build process to avoid keychain prompts
    endif()
    
else()
    message(STATUS "CEF not found. Please run: scripts/setup_cef.sh")
    message(FATAL_ERROR "CEF binary distribution required")
endif()

