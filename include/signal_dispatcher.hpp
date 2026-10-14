#pragma once

#include <cstdint>
#include <array>

namespace VRT {

/**
 * @struct SignalAction
 * @brief Encapsulates the result of a signal lookup.
 */
struct SignalAction {
    bool isValid = false;
    int keyCode = 0;
    int modifiers = 0;
};

/**
 * @class SignalDispatcher
 * @brief A table-driven state machine that maps pixel colors to hardware actions.
 * 
 * This class utilizes a pre-computed Lookup Table (LUT) to achieve O(1) dispatching,
 * minimizing branch mispredictions in the hot loop.
 */
class SignalDispatcher {
public:
    /**
     * @brief Size of the lookup table. A power of two allows for fast bitwise masking.
     */
    static constexpr size_t TABLE_SIZE = 65536;

    SignalDispatcher() = default;

    /**
     * @brief Registers a signal associated with a specific color.
     * 
     * @param r Red component (0-255)
     * @param g Green component (0-255)
     * @param b Blue component (0-255)
     * @param keyCode The virtual key code to inject.
     * @param modifiers The bitmask of modifiers (Shift, Ctrl, Alt).
     */
    void RegisterSignal(int r, int g, int b, int keyCode, int modifiers) {
        uint32_t hash = FastHash(r, g, b);
        m_actionTable[hash] = { true, keyCode, modifiers };
    }

    /**
     * @brief Retrieves the action for a given color using the fast lookup.
     * 
     * @param r Red component
     * @param g Green component
     * @param b Blue component
     * @return A constant reference to the SignalAction.
     */
    [[nodiscard]] inline const SignalAction& GetAction(int r, int g, int b) const noexcept {
        return m_actionTable[FastHash(r, g, b)];
    }

private:
    /**
     * @brief A fast hash function that maps RGB to a table index.
     * 
     * Uses bitwise operations to combine components and applies a mask for O(1) access.
     */
    [[nodiscard]] inline uint32_t FastHash(int r, int g, int b) const noexcept {
        // Combine R, G, B into a single 24-bit value and mask to TABLE_SIZE.
        return (static_cast<uint32_t>(r << 16) | 
                static_cast<uint32_t>(g << 8)  | 
                 static_cast<uint32_t>(b)) & (TABLE_SIZE - 1);
    }

    std::array<SignalAction, TABLE_SIZE> m_actionTable{};
};

} // namespace VRT
