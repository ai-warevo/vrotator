#pragma once

#include "signal_dispatcher.hpp"

/**
 * @namespace VRT::InputEngine
 * @brief Subsystem responsible for kernel-level peripheral input injection.
 */
namespace VRT::InputEngine {
    /**
     * @brief Translates and injects a single discrete hardware input sequence with modifiers.
     * @param keyCode The numeric virtual key identifier or ASCII character value.
     * @param modifierCode The arithmetically packed modifier key bitmask state.
     */
    void SendHardwareInput(int keyCode, int modifierCode);

    /**
     * @brief Dispatches a pre-resolved signal action directly to the OS hardware ring.
     * @param action The resolved SignalAction containing key and modifier data.
     */
    void Dispatch(const SignalAction& action);
}
