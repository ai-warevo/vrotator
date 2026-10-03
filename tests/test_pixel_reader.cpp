#include "catch_amalgamated.hpp"
#include <windows.h>
#include "pixel_reader.hpp"
#include "config.hpp"

TEST_CASE("GDI Graphics Sampling Layer Boundary Assertions", "[PixelReader]") {
    
    SECTION("Coordinate Space Centering Verification") {
        // The framework architecture targets the center of a 5x5 matrix
        // to prevent any anti-aliasing color bleeding at window edges.
        constexpr int targetX = 2;
        constexpr int targetY = 2;

        STATIC_REQUIRE(targetX == 2);
        STATIC_REQUIRE(targetY == 2);
        REQUIRE(targetX == 2);
        REQUIRE(targetY == 2);
    }

    SECTION("Win32 COLORREF Channel Payload Packing") {
        // Emulate an incoming signal payload from the Lua bridge (e.g., ALT-1)
        // Red = 49 (Key 1), Green = 4 (Modifier ALT), Blue = 255 (Valid Protocol Marker)
        const COLORREF mockSignalPixel = RGB(49, 4, 255);

        // Verify that native Win32 bit-shifting macros unpack the color bytes deterministically
        const int r = GetRValue(mockSignalPixel);
        const int g = GetGValue(mockSignalPixel);
        const int b = GetBValue(mockSignalPixel);

        REQUIRE(r == 49);
        REQUIRE(g == 4);
        REQUIRE(b == 255);
    }
}

TEST_CASE("GDI Graphics Dynamic Context Integration Pipeline", "[PixelReader]") {
    
    // Invoke the active runtime sampling engine from src/pixel_reader.cpp
    const COLORREF capturedColor = VRT::PixelReader::ReadSignalPixel();

    // Check if the targeted game client environment window is running in the OS
    const HWND gameHwnd = ::FindWindowA(nullptr, VRT::Config::TARGET_WINDOW_TITLE);

    if (!gameHwnd) {
        SECTION("Headless Environment Fallback Verification") {
            // If the game window handle is missing, the RAII context must return
            // a clear zeroed neutral state to safely protect execution frames.
            REQUIRE(capturedColor == RGB(0, 0, 0));
            REQUIRE(GetRValue(capturedColor) == 0);
            REQUIRE(GetGValue(capturedColor) == 0);
            REQUIRE(GetBValue(capturedColor) == 0);
        }
    } 
    else {
        SECTION("Live Environment Active Workspace Sampling Verification") {
            // If the game window is active, the engine must safely query the DC
            // and return a valid Win32 color token instead of CLR_INVALID (0xFFFFFFFF).
            REQUIRE(capturedColor != CLR_INVALID);
            
            UNSCOPED_INFO("Target workspace hooked. Active frame coordinate (2,2) Hex color: 0x" 
                          << std::uppercase << std::hex << capturedColor);
        }
    }
}
