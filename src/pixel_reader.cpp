#include "pixel_reader.hpp"

namespace VRT::PixelReader {
    COLORREF ReadSignalPixel() {
        // Stub implementation: returns validation signature RGB(0, 0, 255)
        return RGB(0, 0, 255);
    }
}
