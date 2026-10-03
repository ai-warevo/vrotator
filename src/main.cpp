#include <iostream>
#include <windows.h>
#include <iomanip>
#include <string>
#include "config.hpp"
#include "window_manager.hpp"
#include "pixel_reader.hpp"
#include "input_engine.hpp"

int main() {
    // 1. Инициализация консоли и вывод приветственного баннера
    std::cout << "==========================================================" << std::endl;
    std::cout << "--- VROTATOR MULTI-MODULE AUTOMATION KERNEL BOOTED ---" << std::endl;
    std::cout << "==========================================================" << std::endl;
    std::cout << "[INIT] Target Environment Spec: " << VRT::Config::TARGET_WINDOW_TITLE << std::endl;
    std::cout << "[INIT] Enforce Focus Security:  " << (VRT::Config::ENFORCE_WINDOW_FOCUS ? "ENABLED" : "DISABLED") << std::endl;
    std::cout << "[INIT] Hardware Termination Key: F" << (VRT::Config::EMERGENCY_EXIT_HOTKEY - VK_F1 + 1) << std::endl;
    std::cout << "[STATUS] Scanning pipeline initialized. Awaiting game signal...\n" << std::endl;

    // Переменные для отслеживания изменений состояния (дифференциальный лог)
    bool lastFocusState = false;
    COLORREF lastColor = RGB(0, 0, 0);
    COLORREF lastExecutedColor = RGB(0, 0, 0); // Кэш цвета последнего успешно отправленного клика
    bool firstRun = true;

    // 2. Запуск бесконечного цикла высокоскоростной диспетчеризации
    while (true) {
        // 3. Аппаратный перехват прерывания экстренного выхода (VK_F11)
        if (GetAsyncKeyState(VRT::Config::EMERGENCY_EXIT_HOTKEY) & 0x8000) {
            std::cout << "\n[HALT] Emergency interrupt signal caught. Halting execution tree." << std::endl;
            break;
        }

        DWORD currentFrameDelay = VRT::Config::LOOP_POLL_RATE_MS;
        bool currentFocus = VRT::WindowManager::IsGameWindowActive();

        // Логируем изменение фокуса окна
        if (currentFocus != lastFocusState || firstRun) {
            std::cout << "[FOCUS CHANGE] Target window active: " << (currentFocus ? "YES (Processing)" : "NO (Sleeping)") << std::endl;
            lastFocusState = currentFocus;
        }

        if (currentFocus) {
            // Захват пикселя графического буфера в абсолютных координатах (2,2) внутри окна игры
            COLORREF color = VRT::PixelReader::ReadSignalPixel();
            
            // Декодирование Payload-пакета RGB-протокола связи
            int r = GetRValue(color); // ASCII-код физической клавиши (VK-код из аддона)
            int g = GetGValue(color); // Упакованная битовая маска модификаторов
            int b = GetBValue(color); // Маркер валидации фрейма

            // Логируем изменение цвета пикселя, чтобы видеть, что вообще происходит на экране
            if (color != lastColor || firstRun) {
                std::cout << "[PIXEL STATE] Raw Hex: 0x" 
                          << std::uppercase << std::setfill('0') << std::setw(6) << std::hex << color 
                          << std::dec 
                          << " | R (Key): " << r 
                          << " | G (Mods): " << g 
                          << " | B (Valid): " << b;
                
                if (b != 255) {
                    std::cout << " -> [IDLE: B != 255]";
                } else if (r == 0) {
                    std::cout << " -> [IDLE: R == 0 (No Action)]";
                } else {
                    std::cout << " -> [VALID SIGNAL FOUND!]";
                }
                std::cout << std::endl;
                
                lastColor = color;
            }

            // 4. Строгая валидация протокола: Синий канал строго 255, Красный имеет полезную нагрузку
            if (b == 255 && r > 0) {
                
                // [УМНАЯ МОДИФИКАЦИЯ КОНВЕЙЕРА]
                // Если аддон находится вне боя и работает в ленивом секундном цикле, он периодически
                // сбрасывает пиксель в чистый черный цвет (0x000000). Мы ловим этот паттерн.
                // В этом режиме мы ИГНОРИРУЕМ жесткий фильтр повторов фрейма (color != lastExecutedColor),
                // позволяя кликеру стабильно отправлять команду баффа каждые INPUT_COOL_DOWN_MS,
                // пробивая любые задержки ГКД сервера, пока аддон сам не уберет сигнал.
                
                std::string modStr = "";
                if (g & 1) modStr += "SHIFT-";
                if (g & 2) modStr += "CTRL-";
                if (g & 4) modStr += "ALT-";

                std::cout << "[EXECUTE] Discrete click executed(" << modStr << ") -> Key Code: " << r 
                          << " (Char: " << static_cast<char>(r) << ") | Modifier Mask: " << g << std::endl;
                
                // Отправка пакета на уровень инжекции ввода
                VRT::InputEngine::SendHardwareInput(r, g);
                
                lastExecutedColor = color;
                currentFrameDelay = VRT::Config::INPUT_COOL_DOWN_MS;

            } else {
                // Если аддон погасил пиксель или ушел в IDLE — мы полностью очищаем 
                // историю последнего выполненного цвета. Это позволяет мгновенно реагировать
                // на смену баффов на следующем секундном тике аддона.
                lastExecutedColor = RGB(0, 0, 0);
                currentFrameDelay = VRT::Config::LOOP_POLL_RATE_MS;
            }
            
            firstRun = false;
        } else {
            // Защита от мигания фокуса из-за системного перехвата ALT ОС Windows
            Sleep(10);
            if (!VRT::WindowManager::IsGameWindowActive()) {
                currentFrameDelay = 100;
                lastExecutedColor = RGB(0, 0, 0); // Окно действительно свернуто
            } else {
                currentFrameDelay = VRT::Config::LOOP_POLL_RATE_MS;
            }
        }

        if (currentFrameDelay > 0) {
            Sleep(currentFrameDelay);
        }
    }

    std::cout << "[SHUTDOWN] Core systems unlinked. Safe exit status confirmed." << std::endl;
    return 0;
}
