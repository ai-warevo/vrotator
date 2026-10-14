#pragma once

#include <iostream>
#include <string_view>
#include <array>
#include <cstdio>
#include <windows.h>

namespace VRT::Utils {

    /**
     * @brief High-performance timestamp writer pulling ticks from standard stack registers.
     */
    inline void PrintLogTimestamp() noexcept {
        SYSTEMTIME st;
        ::GetLocalTime(&st);
        
        std::array<char, 16> buffer{};
        const int written = std::snprintf(buffer.data(), buffer.size(), "[%02d:%02d:%02d.%03d] ", 
                                          st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
        if (written > 0) {
            std::cout << std::string_view(buffer.data(), static_cast<size_t>(written));
        }
    }

    /**
     * @brief Dedicated hardware token identifier code translator facade.
     */
    [[nodiscard]] inline std::string ResolveKeyName(const int vkCode, std::array<char, 16>& safeBuffer) noexcept {
        if (vkCode >= VK_F1 && vkCode <= VK_F12) {
            const int written = std::snprintf(safeBuffer.data(), safeBuffer.size(), "F%d", vkCode - VK_F1 + 1);
            return std::string_view(safeBuffer.data(), static_cast<size_t>(written));
        }
        
        if ((vkCode >= '0' && vkCode <= '9') || (vkCode >= 'A' && vkCode <= 'Z')) {
            safeBuffer[0] = static_cast<char>(vkCode);
            return std::string_view(safeBuffer.data(), 1);
        }
        
        if (vkCode >= 'a' && vkCode <= 'z') {
            safeBuffer[0] = static_cast<char>(::toupper(vkCode));
            return std::string_view(safeBuffer.data(), 1);
        }

        switch (vkCode) {
            case VK_SPACE:  return "SPACE";
            case VK_RETURN: return "ENTER";
            case VK_ESCAPE: return "ESC";
            case VK_TAB:    return "TAB";
            case VK_BACK:   return "BACKSPACE";
            default: {
                const int written = std::snprintf(safeBuffer.data(), safeBuffer.size(), "VK_%d", vkCode);
                return std::string_view(safeBuffer.data(), static_cast<size_t>(written));
            }
        }
    }
} // namespace VRT::Utils
