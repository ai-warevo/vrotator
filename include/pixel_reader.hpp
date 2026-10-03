#pragma once
#include <windows.h>

/**
 * @namespace VRT::PixelReader
 * @brief Subsystem responsible for high-speed color extraction from the game graphics stream.
 */
namespace VRT::PixelReader {
    /**
     * @brief Reads the color of the signal pixel from the target window context.
     * @return A native Win32 COLORREF structures representing the captured pixel data.
     */
    COLORREF ReadSignalPixel();
}
