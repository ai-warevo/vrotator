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

namespace VRT::InputEngine {

    void SendHardwareInput(int keyCode, int modifierCode) {
        if (keyCode <= 0) return;

        // 1. Конвертируем ASCII-код из аддона в Virtual-Key Code Windows
        // Используем раскладку по умолчанию, при необходимости страхуясь явным кастом
        SHORT vkMapped = VkKeyScanA(static_cast<char>(keyCode));
        WORD vKey = (vkMapped != -1) ? static_cast<WORD>(vkMapped & 0xFF) : static_cast<WORD>(keyCode);

        // 2. Распаковываем битовую маску: ModifierCode = (Shift * 1) + (Ctrl * 2) + (Alt * 4)
        bool shift = (modifierCode & 1) != 0;
        bool ctrl  = (modifierCode & 2) != 0;
        bool alt   = (modifierCode & 4) != 0;

        // Динамический массив структур INPUT для формирования единого пакета прерываний
        std::vector<INPUT> inputs;

        // Вспомогательная лямбда-функция для быстрой сборки структур ввода
        auto pushKey = [&](WORD vk, DWORD flags) {
            INPUT in = {};
            in.type = INPUT_KEYBOARD;
            in.ki.wVk = vk;
            in.ki.wScan = static_cast<WORD>(MapVirtualKeyA(vk, MAPVK_VK_TO_VSC));
            in.ki.dwFlags = flags;
            in.ki.time = 0;
            in.ki.dwExtraInfo = 0;
            inputs.push_back(in);
        };

        // Действие 1: Зажатие всех активных модификаторов
        if (shift) pushKey(VK_SHIFT, 0);
        if (ctrl)  pushKey(VK_CONTROL, 0);
        if (alt)   pushKey(VK_MENU, 0);

        // Действие 2: Нажатие основной клавиши
        pushKey(vKey, 0);

        // Действие 3: Отпускание основной клавиши
        pushKey(vKey, KEYEVENTF_KEYUP);

        // Действие 4: Отпускание модификаторов в обратном порядке (защита от залипания стека)
        if (alt)   pushKey(VK_MENU, KEYEVENTF_KEYUP);
        if (ctrl)  pushKey(VK_CONTROL, KEYEVENTF_KEYUP);
        if (shift) pushKey(VK_SHIFT, KEYEVENTF_KEYUP);

        // 4. Отправляем собранный пакет данных напрямую в подсистему ввода Windows ring-0
        if (!inputs.empty()) {
            SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
        }
    }
}
