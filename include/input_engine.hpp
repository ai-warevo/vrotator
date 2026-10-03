// │   ├── input_engine.hpp      # Модуль низкоуровневой эмуляции SendInput
/*
## 📂 Модуль низкоуровневой эмуляции ввода (Hardware Peripheral Injection Control)## 6. include/input_engine.hpp (Интерфейс подсистемы инжекции ввода)

* Зона ответственности: Декларация контракта на симуляцию клавиатурных прерываний.
* Что должен содержать: Определение функции SendHardwareInput(int keyCode, int modifierCode), принимающей ASCII-код клавиши и битовую маску модификаторов.
*/
#pragma once

namespace VRT::InputEngine {
    // Stub interface for kernel-level peripheral injection
    void SendHardwareInput(int keyCode, int modifierCode);
}
