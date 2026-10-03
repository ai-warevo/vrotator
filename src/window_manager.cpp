/*
## 3. src/window_manager.cpp (Реализация трекинга фокуса Win32)

* Зона ответственности: Прямое взаимодействие с подсистемой оконного менеджера Windows OS.
* Что должен делать:
1. Вызывать Win32 API функцию GetForegroundWindow() для получения дескриптора (HWND) окна, которое сейчас находится в фокусе у пользователя.
   2. Извлекать текстовый заголовок этого окна через GetWindowTextA().
   3. Выполнять строковое сравнение полученного заголовока с константой из config.hpp.
   4. Если включен режим жесткого фокуса, возвращать true только при полном совпадении. Если игра свернута или пользователь переключился на Discord/браузер — возвращать false, переводя кликер в режим безопасного сна.
*/

#include "window_manager.hpp"
#include "config.hpp"
#include <windows.h>
#include <string_view>
#include <vector>

namespace VRT::WindowManager {

    bool IsGameWindowActive() {
        // Если проверка фокуса отключена в конфигурации, безусловно разрешаем работу
        if (!Config::ENFORCE_WINDOW_FOCUS) {
            return true;
        }

        // 1. Получаем дескриптор (HWND) текущего активного окна пользователя
        HWND foregroundHwnd = GetForegroundWindow();
        if (!foregroundHwnd) {
            return false;
        }

        // 2. Запрашиваем длину заголовка окна
        int titleLength = GetWindowTextLengthA(foregroundHwnd);
        if (titleLength == 0) {
            return false;
        }

        // Выделяем буфер под строку (+1 для нуль-терминатора)
        std::vector<char> buffer(titleLength + 1);

        // Извлекаем текстовый заголовок окна
        if (GetWindowTextA(foregroundHwnd, buffer.data(), titleLength + 1) == 0) {
            return false;
        }

        // 3. Выполняем строковое сравнение полученного заголовка с целевым
        std::string_view activeTitle(buffer.data());
        
        // Возвращает true только при вхождении целевой строки ("World of Warcraft")
        return activeTitle.find(Config::TARGET_WINDOW_TITLE) != std::string_view::npos;
    }
}
