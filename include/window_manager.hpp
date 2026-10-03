// │   └── window_manager.hpp    # Модуль трекинга фокуса окна WoW
/*
## 📂 Модуль трекинга окна игры (Window Management Subsystem)## 2. include/window_manager.hpp (Интерфейс подсистемы фокуса)

* Зона ответственности: Декларация высокоуровневых контрактов для взаимодействия ядра с оконной подсистемой Windows.
* Что должен содержать: Определение единственной экспортируемой функции проверки состояния IsGameWindowActive().
*/
#pragma once

namespace VRT::WindowManager {
    // Stub interface for tracking game window focus state
    bool IsGameWindowActive();
}
