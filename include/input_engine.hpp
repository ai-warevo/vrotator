// │   ├── input_engine.hpp      # Модуль низкоуровневой эмуляции SendInput
#pragma once

namespace VRT::InputEngine {
    // Stub interface for kernel-level peripheral injection
    void SendHardwareInput(int keyCode, int modifierCode);
}
