#include "input_engine.hpp"
#include <windows.h>
#include <array>

namespace VRT::InputEngine {

namespace {
    /**
     * @brief Generates a platform-compliant hardware keyboard input structure.
     * @param vk The Windows Virtual-Key code.
     * @param flags The execution state behavior bitmask flags (e.g., KEYEVENTF_KEYUP).
     * @return A constructed Win32 INPUT event record.
     */
    [[nodiscard]] constexpr INPUT BuildKeyEvent(const WORD vk, const DWORD flags) noexcept {
        INPUT input{};
        input.type = INPUT_KEYBOARD;
        input.ki.wVk = vk;
        input.ki.wScan = static_cast<WORD>(::MapVirtualKeyA(vk, MAPVK_VK_TO_VSC));
        input.ki.dwFlags = flags;
        input.ki.time = 0;
        input.ki.dwExtraInfo = 0;
        return input;
    }

    /**
     * @brief Dispatches a packed array sequence directly to the OS ring-0 subsystem.
     * @param data Raw pointer to the contiguous sequential memory storage block.
     * @param count Total number of structural entities scheduled for preemption.
     */
    void DispatchInputBatch(INPUT* const data, const UINT count) noexcept {
        if (count > 0) {
            ::SendInput(count, data, sizeof(INPUT));
        }
    }
} // namespace

void SendHardwareInput(const int keyCode, const int modifierCode) noexcept {
    if (keyCode <= 0) [[unlikely]] {
        return;
    }

    const auto targetVKey = static_cast<WORD>(keyCode);

    // Deconstruct arithmetic packed payload states: (Shift * 1) + (Ctrl * 2) + (Alt * 4)
    const bool hasShift = (modifierCode & 1) != 0;
    const bool hasCtrl  = (modifierCode & 2) != 0;
    const bool hasAlt   = (modifierCode & 4) != 0;

    // Hard ceiling architecture constraint: Maximum potential sequence allocations per transactional window
    constexpr size_t kMaxEventsPerBatch = 4;
    
    // Performance Optimization: Eradicate heap page faults by allocating frames inside standard execution stacks
    std::array<INPUT, kMaxEventsPerBatch> pressEvents{};
    UINT pressCount = 0;

    // Sequential Hardware Down Matrix State Ingestion
    if (hasShift) pressEvents[pressCount++] = BuildKeyEvent(VK_SHIFT, 0);
    if (hasCtrl)  pressEvents[pressCount++] = BuildKeyEvent(VK_CONTROL, 0);
    if (hasAlt)   pressEvents[pressCount++] = BuildKeyEvent(VK_MENU, 0);
    pressEvents[pressCount++] = BuildKeyEvent(targetVKey, 0);

    // Atomically commit keyboard preemption hooks into native desktop threads
    DispatchInputBatch(pressEvents.data(), pressCount);

    // Deterministic hardware hold padding window allowing safe game client internal processing loops
    ::Sleep(10);

    std::array<INPUT, kMaxEventsPerBatch> releaseEvents{};
    UINT releaseCount = 0;

    // Sequential Hardware Up Matrix State Ingestion (Inverted topology eliminates system sticky modifications)
    releaseEvents[releaseCount++] = BuildKeyEvent(targetVKey, KEYEVENTF_KEYUP);
    if (hasAlt)   releaseEvents[releaseCount++] = BuildKeyEvent(VK_MENU, KEYEVENTF_KEYUP);
    if (hasCtrl)  releaseEvents[releaseCount++] = BuildKeyEvent(VK_CONTROL, KEYEVENTF_KEYUP);
    if (hasShift) releaseEvents[releaseCount++] = BuildKeyEvent(VK_SHIFT, KEYEVENTF_KEYUP);

    DispatchInputBatch(releaseEvents.data(), releaseCount);
}

} // namespace VRT::InputEngine
