#include "input_engine.hpp"
#include <iostream>

namespace VRT::InputEngine {
    void SendHardwareInput(int keyCode, int modifierCode) {
        // Stub implementation: prints abstract diagnostic log to console output
        std::cout << "[STUB ENGINE] Input Routed -> Key: " << keyCode << " Mods: " << modifierCode << std::endl;
    }
}
