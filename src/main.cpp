/*
## 📂 Главный оркестратор (System Kernel Orchestration)## 8. src/main.cpp (Точка входа и главный цикл диспетчеризации)

* Зона ответственности: Инициализация приложения, контроль бесконечного цикла, обработка экстренных прерываний и логирование.
* Что должен делать:
1. Выводить в консоль приветственный баннер и статус готовности подсистем кликера.
   2. Запускать бесконечный цикл while(true) с фиксированной частотой опроса (LOOP_POLL_RATE_MS из конфига), чтобы не нагружать процессор холостым ходом.
   3. На каждом шаге цикла проверять состояние клавиши экстренного выхода с помощью GetAsyncKeyState(VK_F11). Если зажата — мгновенно останавливать выполнение и закрывать процесс.
   4. Запрашивать состояние окна через WindowManager. Если оно активно — дергать PixelReader и получать цвет.
   5. Разбирать макрос цвета: вытаскивать каналы R, G, B.
   6. Валидация сигнала: Проверять синий канал. Если B == 255 и R > 0 — передавать параметры R (клавиша) и G (модификаторы) в InputEngine для мгновенного клика.
   7. После успешного клика отправлять поток выполнения в сон на безопасный таймаут (INPUT_COOL_DOWN_MS), давая игре ровно один кадр на регистрацию и обновление интерфейса, предотвращая дублирование макросов.
*/

#include <iostream>
#include <windows.h>
#include <iomanip>
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

            // Если пиксель сбросился в черный или изменился, очищаем кэш исполнения
            if (color == RGB(0, 0, 0)) {
                lastExecutedColor = RGB(0, 0, 0);
            }

            // 4. Строгая валидация протокола: Синий канал строго 255, Красный имеет полезную нагрузку
            if (b == 255 && r > 0) {
                // Защитный фильтр: кликаем только если этот цвет ЕЩЕ НЕ БЫЛ обработан в этой серии сигналов.
                // Как только аддон сменит способность или сбросит пиксель в черный, фильтр откроется заново.
                if (color != lastExecutedColor) {
                    std::cout << "[EXECUTE] Discrete click executed -> Key Code: " << r 
                              << " (Char: " << static_cast<char>(r) << ") | Modifier Mask: " << g << std::endl;
                    
                    // Передача параметров на уровень ядра ОС для мгновенного атомарного клика
                    VRT::InputEngine::SendHardwareInput(r, g);
                    
                    // Запоминаем текущий цвет, чтобы заблокировать повторный спам на следующих кадрах
                    lastExecutedColor = color;
                    
                    // Переключаем задержку кадра на кулдаун защиты, давая игре время на обновление UI
                    currentFrameDelay = VRT::Config::INPUT_COOL_DOWN_MS;
                }
            }
            
            firstRun = false;
        } else {
            // Если игра свернута или не в фокусе, принудительно засыпаем на 100мс
            currentFrameDelay = 100;
            lastExecutedColor = RGB(0, 0, 0); // сбрасываем кэш при потере фокуса
        }

        // Синхронизация цикла с частотой интерфейса
        if (currentFrameDelay > 0) {
            Sleep(currentFrameDelay);
        }
    }

    std::cout << "[SHUTDOWN] Core systems unlinked. Safe exit status confirmed." << std::endl;
    return 0;
}
