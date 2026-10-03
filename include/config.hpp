#pragma once
#include <windows.h>

/**
 * @namespace VRT::Config
 * @brief Global compile-time configuration manifest regulating framework execution limits.
 */
namespace VRT::Config {
    // Window Management Constraints
    constexpr const char* TARGET_WINDOW_TITLE = "World of Warcraft";
    constexpr bool ENFORCE_WINDOW_FOCUS       = true;

    // Hardware Input Emulation Constants
    constexpr int EMERGENCY_EXIT_HOTKEY       = VK_F11;
    constexpr int LOOP_POLL_RATE_MS           = 15;
    constexpr int INPUT_COOL_DOWN_MS          = 50;
}
