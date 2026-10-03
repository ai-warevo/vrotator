// │   ├── config.hpp            # Глобальные константы кликера (задержки, клавиши)
#pragma once
#include <windows.h>

namespace VRT::Config {
    // Window Management Constraints
    constexpr const char* TARGET_WINDOW_TITLE = "World of Warcraft";
    constexpr bool ENFORCE_WINDOW_FOCUS       = true; // If true, sleeps when game is minimized

    // Hardware Input Emulation Constants
    constexpr int EMERGENCY_EXIT_HOTKEY       = VK_F11; // Standard hardware interrupt keybind (F11)
    constexpr int LOOP_POLL_RATE_MS           = 15;     // Frame-time ticker delay (~60-70 Hz poll)
    constexpr int INPUT_COOL_DOWN_MS          = 50;     // Post-execution safety macro cooldown
}
