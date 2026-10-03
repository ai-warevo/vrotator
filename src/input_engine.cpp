/*
## 7. src/input_engine.cpp (Реализация обхода защит через SendInput)

* Зона ответственности: Генерация чистых аппаратных событий ввода на уровне ядра ОС.
* Что должен делать:
1. Принимать сырые данные RGB-сигнала. Конвертировать ASCII-код из аддона в системный код виртуальной клавиши Windows (Virtual-Key Code).
   2. Распаковывать битовую маску зеленого канала (modifierCode) на три независимых флага состояний: Shift, Ctrl, Alt.
   3. Динамически собирать массив структур INPUT (максимум до 4 действий на один фрейм):
   * Действие 1: Зажатие всех активных модификаторов (INPUT_KEYBOARD).
      * Действие 2: Нажатие основной клавиши.
      * Действие 3: Отпускание основной клавиши (KEYEVENTF_KEYUP).
      * Действие 4: Отпускание модификаторов в обратном порядке (защита от залипания).
   4. Отправлять собранный пакет данных напрямую в подсистему ввода Windows через ядерную функцию SendInput(). Игра воспримет это как 100% физический клик по клавиатуре.
*/

#include "input_engine.hpp"
#include <windows.h>
#include <vector>

#include "input_engine.hpp"
#include <windows.h>
#include <vector>

namespace VRT::InputEngine {

    void SendHardwareInput(int keyCode, int modifierCode) {
        // Защитный барьер: если сигнал пустой или невалидный, игнорируем инжекцию
        if (keyCode <= 0) {
            return;
        }

        // 1. Конвертируем входящий ASCII-токен из аддона в системный Virtual-Key Code Windows
        SHORT vkMapped = VkKeyScanA(static_cast<char>(keyCode));
        WORD vKey = (vkMapped != -1) ? static_cast<WORD>(vkMapped & 0xFF) : static_cast<WORD>(keyCode);

        // 2. Распаковываем битовую маску зеленого канала: ModifierCode = (Shift * 1) + (Ctrl * 2) + (Alt * 4)
        bool shift = (modifierCode & 1) != 0;
        bool ctrl  = (modifierCode & 2) != 0;
        bool alt   = (modifierCode & 4) != 0;

        // Динамический массив структур INPUT для сборки единого атомарного пакета
        std::vector<INPUT> inputs;

        // Вспомогательная лямбда-функция для быстрого и безопасного наполнения вектора событий
        auto pushKeyEvent = [&](WORD vk, DWORD flags) {
            INPUT in = {};
            in.type = INPUT_KEYBOARD;
            in.ki.wVk = vk;
            // Аппаратный скан-код (Hardware Scan Code) — критически важен для обхода защит WoW
            in.ki.wScan = static_cast<WORD>(MapVirtualKeyA(vk, MAPVK_VK_TO_VSC));
            in.ki.dwFlags = flags;
            in.ki.time = 0;
            in.ki.dwExtraInfo = 0;
            inputs.push_back(in);
        };

        // Действие 1: Физическое зажатие всех активных модификаторов (INPUT_KEYBOARD)
        if (shift) pushKeyEvent(VK_SHIFT, 0);
        if (ctrl)  pushKeyEvent(VK_CONTROL, 0);
        if (alt)   pushKeyEvent(VK_MENU, 0);

        // Действие 2: Нажатие основной клавиши бинда способности
        pushKeyEvent(vKey, 0);

        // Действие 3: Отпускание основной клавиши способности (KEYEVENTF_KEYUP)
        pushKeyEvent(vKey, KEYEVENTF_KEYUP);

        // Действие 4: Отпускание модификаторов в обратном порядке (жесткая защита от залипания стека ОС)
        if (alt)   pushKeyEvent(VK_MENU, KEYEVENTF_KEYUP);
        if (ctrl)  pushKeyEvent(VK_CONTROL, KEYEVENTF_KEYUP);
        if (shift) pushKeyEvent(VK_SHIFT, KEYEVENTF_KEYUP);

        // Отправляем собранную последовательность напрямую в подсистему ввода Windows ring-0
        if (!inputs.empty()) {
            SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
        }
    }
}
