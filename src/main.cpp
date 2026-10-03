#include <iostream>
#include <windows.h>
#include "config.hpp"
#include "window_manager.hpp"
#include "pixel_reader.hpp"
#include "input_engine.hpp"

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

int main() {
    std::cout << "--- VROTATOR MULTI-MODULE AUTOMATION KERNEL BOOTED ---" << std::endl;
    std::cout << "Target key for runtime termination: F" << (VRT::Config::EMERGENCY_EXIT_HOTKEY - 111 + 1) << std::endl;

    // Execution Stub Loop
    while (true) {
        // Safe infrastructure exit check using hardware polling
        if (GetAsyncKeyState(VRT::Config::EMERGENCY_EXIT_HOTKEY) & 0x8000) {
            std::cout << "Emergency interrupt signal caught. Halting application execution tree." << std::endl;
            break;
        }

        if (VRT::WindowManager::IsGameWindowActive()) {
            COLORREF color = VRT::PixelReader::ReadSignalPixel();
            int r = GetRValue(color);
            int g = GetGValue(color);
            int b = GetBValue(color);

            // Simulating parsing layer detection
            if (b == 255) {
                VRT::InputEngine::SendHardwareInput(r, g);
            }
        }

        Sleep(2000); // Throttled loop for safe console diagnostic profiling
    }

    return 0;
}
