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
     * @brief High-performance timestamp writer pulling ticks from standard stack registers.
     */
    void PrintLogTimestamp() noexcept {
        SYSTEMTIME st;
        ::GetLocalTime(&st);
        
        std::array<char, 16> buffer{};
        const int written = std::snprintf(buffer.data(), buffer.size(), "[%02d:%02d:%02d.%03d] ", 
                                          st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
        if (written > 0) {
            std::cout << std::string_view(buffer.data(), static_cast<size_t>(written));
        }
    }

    /**
     * @brief Dedicated hardware token identifier code translator facade.
     */
    [[nodiscard]] std::string_view ResolveKeyName(const int vkCode, std::array<char, 16>& safeBuffer) noexcept {
        if (vkCode >= VK_F1 && vkCode <= VK_F12) {
            const int written = std::snprintf(safeBuffer.data(), safeBuffer.size(), "F%d", vkCode - VK_F1 + 1);
            return std::string_view(safeBuffer.data(), static_cast<size_t>(written));
        }
        
        if ((vkCode >= '0' && vkCode <= '9') || (vkCode >= 'A' && vkCode <= 'Z')) {
            safeBuffer[0] = static_cast<char>(vkCode);
            return std::string_view(safeBuffer.data(), 1);
        }
        
        if (vkCode >= 'a' && vkCode <= 'z') {
            safeBuffer[0] = static_cast<char>(::toupper(vkCode));
            return std::string_view(safeBuffer.data(), 1);
        }

        switch (vkCode) {
            case VK_SPACE:  return "SPACE";
            case VK_RETURN: return "ENTER";
            case VK_ESCAPE: return "ESC";
            case VK_TAB:    return "TAB";
            case VK_BACK:   return "BACKSPACE";
            default: {
                const int written = std::snprintf(safeBuffer.data(), safeBuffer.size(), "VK_%d", vkCode);
                return std::string_view(safeBuffer.data(), static_cast<size_t>(written));
            }
        }
    }

    /**
     * @brief Emits a decoupled notification string whenever process visibility focus updates.
     */
    void TrackFocusState(const bool currentFocus, EngineState& state) noexcept {
        if (currentFocus == state.lastFocusState && !state.firstRun) {
            return;
        }
        PrintLogTimestamp();
        std::cout << "[FOCUS CHANGE] Target window active: " << (currentFocus ? "YES (Processing)" : "NO (Sleeping)") << std::endl;
        state.lastFocusState = currentFocus;
    }

    /**
     * @brief Isolates lower power consumption logic transitions when application is out of focus.
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
        PrintLogTimestamp();
        std::cout << "[PIXEL STATE] Raw Hex: 0x" << std::uppercase << std::setfill('0') << std::setw(6) << std::hex << color << std::dec
                  << " | R (Key): " << r << " | G (Mods): " << g << " | B (Valid): " << b;
        
        if (b != 255)       std::cout << " -> [IDLE: B != 255]";
        else if (r == 0)    std::cout << " -> [IDLE: R == 0 (No Action)]";
        else                std::cout << " -> [VALID SIGNAL FOUND!]";
        std::cout << std::endl;
        
        state.lastColor = color;
    }

    /**
     * @brief Injects keyboard events into standard thread ring rings upon context changes.
     */
    void DispatchHardwareAction(const int r, const int g, const int modifierCode) noexcept {
        std::string modStr = "";
        if (g & 1) modStr += "SHIFT-";
        if (g & 2) modStr += "CTRL-";
        if (g & 4) modStr += "ALT-";

        std::array<char, 16> keyNameBuffer{};
        std::string_view keyName = ResolveKeyName(r, keyNameBuffer);

        PrintLogTimestamp();
        std::cout << "[EXECUTE] Discrete click executed -> Combo: (" << modStr << keyName 
                  << ") | Key Code: " << r << " | Modifier Mask: " << g << std::endl;
    
        InputEngine::SendHardwareInput(r, g);
    }

} // namespace
} // namespace VRT

int main() {
    std::cout << "==========================================================" << std::endl;
    VRT::PrintLogTimestamp(); std::cout << "--- vROTATOR MULTI-MODULE AUTOMATION KERNEL BOOTED ---" << std::endl;
    std::cout << "==========================================================" << std::endl;
    
    VRT::PrintLogTimestamp(); std::cout << "[INIT] Target Environment Spec: " << VRT::Config::TARGET_WINDOW_TITLE << std::endl;
    VRT::PrintLogTimestamp(); std::cout << "[INIT] Enforce Focus Security:  " << (VRT::Config::ENFORCE_WINDOW_FOCUS ? "ENABLED" : "DISABLED") << std::endl;
    VRT::PrintLogTimestamp(); std::cout << "[INIT] Hardware Termination Key: F" << (VRT::Config::EMERGENCY_EXIT_HOTKEY - VK_F1 + 1) << std::endl;
    VRT::PrintLogTimestamp(); std::cout << "[STATUS] Scanning pipeline initialized. Awaiting game signal...\n" << std::endl;

    VRT::EngineState state{};

    while (true) {
        if (::GetAsyncKeyState(VRT::Config::EMERGENCY_EXIT_HOTKEY) & 0x8000) {
            std::cout << "\n";
            VRT::PrintLogTimestamp(); std::cout << "[HALT] Emergency interrupt signal caught. Halting execution tree." << std::endl;
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

        if (b != 255 || r <= 0) {
            state.lastExecutedColor = RGB(0, 0, 0);
            if (currentFrameDelay > 0) ::Sleep(currentFrameDelay);
            continue;
        }

        if (color == state.lastExecutedColor) {
            if (currentFrameDelay > 0) ::Sleep(currentFrameDelay);
            continue;
        }

        VRT::DispatchHardwareAction(r, g, color);
    
        state.lastExecutedColor = color;
        currentFrameDelay = VRT::Config::INPUT_COOL_DOWN_MS;

        if (currentFrameDelay > 0) {
            ::Sleep(currentFrameDelay);
        }
    }

    VRT::PrintLogTimestamp(); std::cout << "[SHUTDOWN] Core systems unlinked. Safe exit status confirmed." << std::endl;
    return 0;
}
