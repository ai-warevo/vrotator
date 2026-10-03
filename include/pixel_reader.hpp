// │   ├── pixel_reader.hpp      # Модуль высокоскоростного захвата экрана GDI
#pragma once
#include <windows.h>

namespace VRT::PixelReader {
    // Stub interface for high-speed color extraction
    COLORREF ReadSignalPixel();
}
