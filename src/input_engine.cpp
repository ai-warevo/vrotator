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
    [[nodiscard]] inline INPUT BuildKeyEvent(const WORD vk, const DWORD flags) noexcept {
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

    /**
     * @brief High-resolution precision delay using a spin-wait loop.
     * @param milliseconds The desired delay in milliseconds.
     */
    void SpinWait(double milliseconds) noexcept {
        if (milliseconds <= 0.0) return;

        LARGE_INTEGER frequency, start, end;
        ::QueryPerformanceFrequency(&frequency);
        ::QueryPerformanceCounter(&start);

        const double targetTicks = (milliseconds / 1000.0) * static_cast<double>(frequency.QuadPart);
        const long long targetEndTicks = start.QuadPart + static_cast<long long>(targetTicks);

        do {
            ::QueryPerformanceCounter(&end);
        } while (end.QuadPart < targetEndTicks);
    }
} // namespace

void SendHardwareInput(const int keyCode, const int modifierCode, double delayMs) {
    if (keyCode <= 0) {
        return;
    }

    const auto targetVKey = static_cast<WORD>(keyCode);

    // Deconstruct arithmetic packed payload states: (Shift * 1) + (Ctrl * 2) + (Alt * 4)
    const bool hasShift = (modifierCode & 1) != 0;
    const bool hasCtrl  = (modifierCode & 2) != 0;
    const bool hasAlt   = (modifierCode & 4) != 0;

    /**
     * @brief Helper to populate an input array with a sequence of Down or Up events.
     * Maintains "Inverted Topology" for UP events to ensure system-level stability.
     */
    auto FillSequence = [&](INPUT* arr, UINT& count, bool isUp) {
        if (!isUp) {
            // Sequence: Modifiers -> Target Key
            if (hasShift) arr[count++] = BuildKeyEvent(VK_SHIFT, 0);
            if (hasCtrl)  arr[count++] = BuildKeyEvent(VK_CONTROL, 0);
            if (hasAlt)   arr[count++] = BuildKeyEvent(VK_MENU, 0);
            arr[count++] = BuildKeyEvent(targetVKey, 0);
        } else {
            // Sequence: Target Key -> Modifiers (Inverted topology)
            arr[count++] = BuildKeyEvent(targetVKey, KEYEVENTF_KEYUP);
            if (hasAlt)   arr[count++] = BuildKeyEvent(VK_MENU, KEYEVENTF_KEYUP);
            if (hasCtrl)  arr[count++] = BuildKeyEvent(VK_CONTROL, KEYEVENTF_KEYUP);
            if (hasShift) arr[count++] = BuildKeyEvent(VK_SHIFT, KEYEVENTF_KEYUP);
        }
    };

    if (delayMs <= 0.0) {
        // [OPTIMIZATION]: Batching - Single atomic syscall containing both DOWN and UP events.
        std::array<INPUT, 8> eventSequence{};
        UINT eventCount = 0;

        FillSequence(eventSequence.data(), eventCount, false); // Press phase
        FillSequence(eventSequence.data(), eventCount, true);  // Release phase

        DispatchInputBatch(eventSequence.data(), eventCount);
    } else {
        // [OPTIMIZATION]: Precision Timing - High-res spin-wait between two distinct batches.
        std::array<INPUT, 4> pressEvents{};
        UINT pressCount = 0;
        FillSequence(pressEvents.data(), pressCount, false);
        DispatchInputBatch(pressEvents.data(), pressCount);

        SpinWait(delayMs);

        std::array<INPUT, 4> releaseEvents{};
        UINT releaseCount = 0;
        FillSequence(releaseEvents.data(), releaseCount, true);
        DispatchInputBatch(releaseEvents.data(), releaseCount);
    }
}

#ifdef ENABLE_VROTATOR_TESTS
namespace InternalTestBridge {
    INPUT TestBuildKeyEvent(WORD vk, DWORD flags) noexcept {
        return BuildKeyEvent(vk, flags);
    }
}
#endif
} // namespace VRT::InputEngine
