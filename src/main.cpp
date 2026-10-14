#include <iostream>
#include <windows.h>
#include <iomanip>
#include <string_view>
#include <array>
#include <cstdio>
#include <string>
#include <thread>
#include <atomic>
#include <cstring>
#include "config.hpp"
#include "window_manager.hpp"
#include "pixel_reader.hpp"
#include "input_engine.hpp"
#include "telemetry_queue.hpp"

namespace VRT {
    SPSCQueue<4096> g_telemetryQueue;
    std::atomic<bool> g_keepRunning{true};
}

namespace {

    /**
     * @brief High-performance timestamp writer pulled by the consumer thread.
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
     * @brief Background consumer thread for handling all telemetry and I/O.
     */
    void TelemetryConsumer() {
        VRT::TelemetryPacket packet;
        while (VRT::g_keepRunning || VRT::g_telemetryQueue.pop(packet)) {
            if (VRT::g_telemetryQueue.pop(packet)) {
                PrintLogTimestamp();

                switch (packet.type) {
                    case VRT::TelemetryEventType::FocusChange:
                        std::cout << "[FOCUS CHANGE] Target window active: " 
                                  << (packet.focusChange.focusActive ? "YES (Processing)" : "NO (Sleeping)") << std::endl;
                        break;
                    case VRT::TelemetryEventType::PixelState: {
                        COLORREF color = packet.pixelState.color;
                        int r = GetRValue(color);
                        int g = GetGValue(color);
                        int b = GetBValue(color);
                        std::cout << "[PIXEL STATE] Raw Hex: 0x" << std::uppercase << std::setfill('0') << std::setw(6) << std::hex << color << std::dec
                                  << " | R (Key): " << r << " | G (Mods): " << g << " | B (Valid): " << b;

                        if (b != 255)       std::cout << " -> [IDLE: B != 255]";
                        else if (r == 0)    std::cout << " -> [IDLE: R == 0 (No Action)]";
                        else                std::cout << " -> [VALID SIGNAL FOUND!]";
                        std::cout << std::endl;
                        break;
                    }
                    case VRT::TelemetryEventType::HardwareAction: {
                        std::array<char, 16> keyBuf{};
                        std::string_view keyName = ResolveKeyName(packet.hardwareAction.key_r, keyBuf);
                        std::string modStr = "";
                        if (packet.hardwareAction.key_g & 1) modStr += "SHIFT-";
                        if (packet.hardwareAction.key_g & 2) modStr += "CTRL-";
                        if (packet.hardwareAction.key_g & 4) modStr += "ALT-";

                        std::cout << "[EXECUTE] Discrete click executed -> Combo: (" << modStr << keyName 
                                  << ") | Key Code: " << packet.hardwareAction.key_r 
                                  << " | Modifier Mask: 0x" << std::hex << packet.hardwareAction.key_g << std::dec << std::endl;
                        break;
                    }
                    case VRT::TelemetryEventType::SystemLog:
                        std::cout << packet.systemLog.message << std::endl;
                        break;
                }
            } else {
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
            }
        }
    }

    /**
     * @struct EngineState
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
        VRT::TelemetryPacket p{};
        p.timestamp = GetTickCount64();
        p.type = VRT::TelemetryEventType::FocusChange;
        p.focusChange.focusActive = currentFocus;
        VRT::g_telemetryQueue.push(p);

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
        VRT::TelemetryPacket p{};
        p.timestamp = GetTickCount64();
        p.type = VRT::TelemetryEventType::PixelState;
        p.pixelState.color = color;
        VRT::g_telemetryQueue.push(p);

        state.lastColor = color;
    }

    /**
     * @brief Injects keyboard events into standard thread ring rings upon context changes.
     */
    void DispatchHardwareAction(const int r, const int g) noexcept {
        VRT::TelemetryPacket p{};
        p.timestamp = GetTickCount64();
        p.type = VRT::TelemetryEventType::HardwareAction;
        p.hardwareAction.key_r = r;
        p.hardwareAction.key_g = g;
        VRT::g_telemetryQueue.push(p);

        InputEngine::SendHardwareInput(r, g);
    }

    void LogSystemMessage(const char* msg) noexcept {
        VRT::TelemetryPacket p{};
        p.timestamp = GetTickCount64();
        p.type = VRT::TelemetryEventType::SystemLog;
        std::strncpy(p.systemLog.message, msg, 63);
        p.systemLog.message[63] = '\0'; // Ensure null termination
        VRT::g_telemetryQueue.push(p);
    }

} // namespace

} // namespace VRT

int main() {
    // Start telemetry thread
    std::thread telemetryThread(VRT::TelemetryConsumer);

    LogSystemMessage("==========================================================");
    LogSystemMessage("--- vROTATOR MULTI-MODULE AUTOMATION KERNEL BOOTED ---");
    LogSystemMessage("==========================================================");
    
    // Wait a bit for consumer to catch up so boot logs are printed
    std::this_thread::sleep_for(std::chrono::milliseconds(50));

    char buf[128];
    std::snprintf(buf, sizeof(buf), "[INIT] Target Environment Spec: %s", VRT::Config::TARGET_WINDOW_TITLE);
    LogSystemMessage(buf);

    std::snprintf(buf, sizeof(buf), "[INIT] Enforce Focus Security:  %s", (VRT::Config::ENFORCE_WINDOW_FOCUS ? "ENABLED" : "DISABLED"));
    LogSystemMessage(buf);

    std::snprintf(buf, sizeof(buf), "[INIT] Hardware Termination Key: F%d", (VRT::Config::EMERGENCY_EXIT_HOTKEY - VK_F1 + 1));
    LogSystemMessage(buf);

    LogSystemMessage("[STATUS] Scanning pipeline initialized. Awaiting game signal...");
    LogSystemMessage("");

    VRT::EngineState state{};

    while (true) {
        if (::GetAsyncKeyState(VRT::Config::EMERGENCY_EXIT_HOTKEY) & 0x8000) {
            LogSystemMessage("");
            LogSystemMessage("[HALT] Emergency interrupt signal caught. Halting execution tree.");
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

        VRT::DispatchHardwareAction(r, g);
    
        state.lastExecutedColor = color;
        currentFrameDelay = VRT::Config::INPUT_COOL_DOWN_MS;

        if (currentFrameDelay > 0) {
            ::Sleep(currentFrameDelay);
        }
    }

    LogSystemMessage("[SHUTDOWN] Core systems unlinked. Safe exit status confirmed.");
    
    VRT::g_keepRunning = false;
    telemetryThread.join();

    return 0;
}
