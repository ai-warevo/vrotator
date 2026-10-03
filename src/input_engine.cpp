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

    // Вспомогательная внутренняя функция — убрали const, чтобы SendInput принимал неконстантный указатель
    static void SendRawInputBatch(std::vector<INPUT>& inputs) {
        if (!inputs.empty()) {
            SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
        }
    }

    void SendHardwareInput(int keyCode, int modifierCode) {
        // Защитный барьер: если сигнал пустой, мгновенно выходим
        if (keyCode <= 0) {
            return;
        }

        // ПРЯМОЙ МАППИНГ: Входящий keyCode уже является валидным Virtual-Key кодом Windows
        WORD targetVKey = static_cast<WORD>(keyCode);

        // Распаковываем битовую маску модификаторов: (Shift * 1) + (Ctrl * 2) + (Alt * 4)
        bool shift = (modifierCode & 1) != 0;
        bool ctrl  = (modifierCode & 2) != 0;
        bool alt   = (modifierCode & 4) != 0;

        // Вспомогательная лямбда для сборки структур INPUT
        auto buildKeyEvent = [](WORD vk, DWORD flags) -> INPUT {
            INPUT in = {};
            in.type = INPUT_KEYBOARD;
            in.ki.wVk = vk;
            in.ki.wScan = static_cast<WORD>(MapVirtualKeyA(vk, MAPVK_VK_TO_VSC));
            in.ki.dwFlags = flags;
            in.ki.time = 0;
            in.ki.dwExtraInfo = 0;
            return in;
        };

        // ==========================================
        // ЭТАП 1: ФИЗИЧЕСКОЕ ЗАЖАТИЕ КЛАВИШ (KEYDOWN)
        // ==========================================
        std::vector<INPUT> pressBatch;

        // Зажимаем active модификаторы
        if (shift) pressBatch.push_back(buildKeyEvent(VK_SHIFT, 0));
        if (ctrl)  pressBatch.push_back(buildKeyEvent(VK_CONTROL, 0));
        if (alt)   pressBatch.push_back(buildKeyEvent(VK_MENU, 0));

        // Зажимаем основную клавишу бинда
        pressBatch.push_back(buildKeyEvent(targetVKey, 0));

        // Атомарно отправляем фазу нажатия в ОС
        SendRawInputBatch(pressBatch);

        // ==========================================
        // ЭТАП 2: АППАРАТНЫЙ МИКРО-СОН (ТАЙМИНГ УДЕРЖАНИЯ)
        // ==========================================
        // Пауза 10 мс для фиксации модификаторов движком WoW
        Sleep(10);

        // ==========================================
        // ЭТАП 3: ФИЗИЧЕСКОЕ ОТПУСКАНИЕ КЛАВИШ (KEYUP)
        // ==========================================
        std::vector<INPUT> releaseBatch;

        // Сначала отпускаем основную клавишу способности
        releaseBatch.push_back(buildKeyEvent(targetVKey, KEYEVENTF_KEYUP));

        // Затем отпускаем модификаторы в обратном порядке (защита от залипания)
        if (alt)   releaseBatch.push_back(buildKeyEvent(VK_MENU, KEYEVENTF_KEYUP));
        if (ctrl)  releaseBatch.push_back(buildKeyEvent(VK_CONTROL, KEYEVENTF_KEYUP));
        if (shift) releaseBatch.push_back(buildKeyEvent(VK_SHIFT, KEYEVENTF_KEYUP));

        // Атомарно отправляем фазу освобождения в ОС
        SendRawInputBatch(releaseBatch);
    }
}
