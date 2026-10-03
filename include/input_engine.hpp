#pragma once

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
}
