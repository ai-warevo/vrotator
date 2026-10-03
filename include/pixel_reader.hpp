// │   ├── pixel_reader.hpp      # Модуль высокоскоростного захвата экрана GDI
/*
## 📂 Модуль высокоскоростного захвата экрана (Graphics Processing Layer)## 4. include/pixel_reader.hpp (Интерфейс подсистемы захвата цвета)

* Зона ответственности: Декларация интерфейса чтения графического буфера Windows. Подключает типы данных windows.h.
* Что должен содержать: Определение экспортируемой функции получения цвета ReadSignalPixel(), возвращающей нативный Win32-тип COLORREF.
*/
#pragma once
#include <windows.h>

namespace VRT::PixelReader {
    // Stub interface for high-speed color extraction
    COLORREF ReadSignalPixel();
}
