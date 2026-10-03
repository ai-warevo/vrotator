#include <iostream>
#include <windows.h>
#include <iomanip>
#include "config.hpp"
#include "window_manager.hpp"
#include "pixel_reader.hpp"
#include "input_engine.hpp"

int main() {
    // Инициализация консоли и вывод приветственного баннера
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
    bool firstRun = true;

    // Запуск бесконечного цикла высокоскоростной диспетчеризации
    while (true) {
        // Аппаратный перехват прерывания экстренного выхода (VK_F11)
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
            // Захват пикселя графического буфера в абсолютных координатах (0,0)
            COLORREF color = VRT::PixelReader::ReadSignalPixel();
            
            // Декодирование Payload-пакета RGB-протокола связи
            int r = GetRValue(color); // ASCII-код физической клавиши
            int g = GetGValue(color); // Упакованная битовая маска модификаторов
            int b = GetBValue(color); // Маркер валидации фрейма

            // Логируем изменение цвета пикселя, чтобы видеть, что вообще происходит на экране
            if (color != lastColor || firstRun) {
                std::cout << "[PIXEL STATE] Raw Hex: 0x" 
                          << std::uppercase << std::setfill('0') << std::setw(6) << std::hex << color 
                          << std::dec // возвращаем десятичный формат для каналов
                          << " | R (Key): " << r 
                          << " | G (Mods): " << g 
                          << " | B (Valid): " << b;
                
                // Пишем причину, если сигнал игнорируется
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

            // Строгая валидация протокола: Синий канал строго 255, Красный имеет полезную нагрузку
            if (b == 255 && r > 0) {
                std::cout << "[EXECUTE] Injecting input -> Key Code: " << r << " (Char: " << static_cast<char>(r) << ") | Modifier Mask: " << g << std::endl;
                
                // Передача ASCII-токена и модификаторов на уровень ядра ОС
                VRT::InputEngine::SendHardwareInput(r, g);
                
                // Защита от дублирования макросов: переключаем задержку кадра на кулдаун защиты
                currentFrameDelay = VRT::Config::INPUT_COOL_DOWN_MS;
            }
            
            firstRun = false;
        } else {
            // Если игра свернута или не в фокусе, принудительно засыпаем на 100мс
            currentFrameDelay = 100;
        }

        // Синхронизация цикла с частотой интерфейса
        if (currentFrameDelay > 0) {
            Sleep(currentFrameDelay);
        }
    }

    std::cout << "[SHUTDOWN] Core systems unlinked. Safe exit status confirmed." << std::endl;
    return 0;
}
