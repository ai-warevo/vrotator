#include <iostream>
#include <windows.h>
#include <iomanip>
#include <string_view>
#include <array>
#include <cstdio>
#include <string>

#include "config.hpp"
#include "window_manager.hpp"
#include "pixel_reader.hpp"
#include "input_engine.hpp"
#include "signal_dispatcher.hpp"
#include "vrt_utils.hpp"

namespace VRT {
namespace {

    /**
     * @struct EngineState
     * @brief Holds runtime context to decouple execution variables between decoupled steps.
     */
    struct EngineState {
        bool lastFocusState = false;
        COLORREF lastColor = RGB(0, 0, 0);
        COLORREF lastExecutedColor = RGB(0, 0, 0);
        bool firstRun = true;
    };

    /**
     * @brief Emits a decoupled notification string whenever process visibility focus updates.
     */
    void TrackFocusState(const bool currentFocus, EngineState& state) noexcept {
        if (currentFocus == state.lastFocusState && !state.firstRun) {
            return;
        }
        VRT::Utils::PrintLogTimestamp();
        std::cout << "[FOCUS CHANGE] Target window active: " << (currentFocus ? "YES (Processing)" : "NO (Sleeping)") << std::endl;
        state.lastFocusState = currentFocus;
    }

    /**
     * @brief Isolates lower power consumption logic transitions when application is out of focus.
     * @return The delay in milliseconds.
     */
    [[nodiscard]] DWORD HandleOutOfFocusState(EngineState& state) noexcept {
        ::Sleep(10);
        const DWORD delay = WindowManager::IsGameWindowActive() ? Config::LOOP_POLL_RATE_MS : 100;
        state.lastExecutedColor = RGB(0, 0, 0);
        return delay;
    }

    /**
     * @brief Monitors desktop memory layouts and logs telemetry tracking nodes upon signal transitions.
     */
    void ProcessTraceLogging(const COLORREF color, const int r, const int g, const int b, EngineState& state) noexcept {
        if (color == state.lastColor && !state.firstRun) {
            return;
        }
        VRT::Utils::PrintLogTimestamp();
        std::cout << "[PIXEL STATE] Raw Hex: 0x" << std::uppercase << std::setfill('0') << std::setw(6) << std::hex << color << std::dec
                  << " | R (Key): " << r << " | G (Mods): " << g << " | B (Valid): " << b;
        
        if (b != 255)       std::cout << " -> [IDLE: B != 255]";
        else if (r == 0)    std::cout << " -> [IDLE: R == 0 (No Action)]";
        else                std::cout << " -> [VALID SIGNAL FOUND!]";
        std::cout << std::endl;
        
        state.lastColor = color;
    }

} // namespace
} // namespace VRT

int main() {
    std::cout << "==========================================================" << std::endl;
    VRT::Utils::PrintLogTimestamp(); std::cout << "--- vROTATOR MULTI-MODULE AUTOMATION KERNEL BOOTED ---" << std::endl;
    std::cout << "==========================================================" << std::endl;
    
    VRT::Utils::PrintLogTimestamp(); std::cout << "[INIT] Target Environment Spec: " << VRT::Config::TARGET_WINDOW_TITLE << std::endl;
    VRT::Utils::PrintLogTimestamp(); std::cout << "[INIT] Enforce Focus Security:  " << (VRT::Config::ENFORCE_WINDOW_FOCUS ? "ENABLED" : "DISABLED") << std::endl;
    VRT::Utils::PrintLogTimestamp(); std::cout << "[INIT] Hardware Termination Key: F" << (VRT::Config::EMERGENCY_EXIT_HOTKEY - VK_F1 + 1) << std::endl;
    VRT::Utils::PrintLogTimestamp(); std::cout << "[STATUS] Scanning pipeline initialized. Awaiting game signal...\n" << std::endl;

    VRT::EngineState state{};

    // Initialize the Table-Driven State Machine
    VRT::SignalDispatcher dispatcher;
    
    // Pre-populate with current implicit logic: Any R > 0, G in [0,255], B = 255 is a valid signal.
    // In a real deployment, this would be populated from a configuration file/resource.
    for (int r = 1; r <= 255; ++r) {
        for (int g = 0; g <= 255; ++g) {
            dispatcher.RegisterSignal(r, g, 255, r, g);
        }
    }

    while (true) {
        if (::GetAsyncKeyState(VRT::Config::EMERGENCY_EXIT_HOTKEY) & 0x8000) {
            std::cout << "\n";
            VRT::Utils::PrintLogTimestamp(); std::cout << "[HALT] Emergency interrupt signal caught. Halting execution tree." << std::endl;
            break;
        }

        DWORD currentFrameDelay = VRT::Config::LOOP_POLL_RATE_MS;
        const bool currentFocus = VRT::WindowManager::IsGameWindowActive();

        VRT::TrackFocusState(currentFocus, state);

        if (!currentFocus) {
            currentFrameDelay = VRT::HandleOutOfFocusState(state);
            if (currentFrameDelay > 0) ::Sleep(currentFrameDelay);
            continue;
        }

        const COLORREF color = VRT::PixelReader::ReadSignalPixel();
        const int r = GetRValue(color);
        const int g = GetGValue(color);
        const int b = GetBValue(color);

        VRT::ProcessTraceLogging(color, r, g, b, state);
        state.firstRun = false;

        // TABLE-DRIVEN DISPATCH: Constant time O(1) lookup
        const auto& action = dispatcher.GetAction(r, g, b);

        if (!action.isValid) {
            state.lastExecutedColor = RGB(0, 0, 0);
            if (currentFrameDelay > 0) ::Sleep(currentFrameDelay);
            continue;
        }

        // Don't repeat the same action if pixel hasn't changed color
        if (color == state.lastExecutedColor) {
            if (currentFrameDelay > 0) ::Sleep(currentFrameDelay);
            continue;
        }

        VRT::InputEngine::Dispatch(action);
    
        state.lastExecutedColor = color;
        currentFrameDelay = VRT::Config::INPUT_COOL_DOWN_MS;

        if (currentFrameDelay > 0) {
            ::Sleep(currentFrameDelay);
        }
    }

    VRT::Utils::PrintLogTimestamp(); std::cout << "[SHUTDOWN] Core systems unlinked. Safe exit status confirmed." << std::endl;
    return 0;
}
