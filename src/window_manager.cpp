#include "window_manager.hpp"
#include "config.hpp"
#include <windows.h>
#include <string_view>
#include <array>

namespace VRT::WindowManager {

bool IsGameWindowActive() noexcept {
    // If foreground constraint security is disabled, bypass validation loops immediately
    if (!Config::ENFORCE_WINDOW_FOCUS) {
        return true;
    }

    // 1. Fetch the absolute runtime window handle currently holding OS thread focus
    const HWND foregroundHwnd = ::GetForegroundWindow();
    if (!foregroundHwnd) {
        return false;
    }

    // 2. Query the layout title character length constraints
    const int titleLength = ::GetWindowTextLengthA(foregroundHwnd);
    if (titleLength <= 0) {
        return false;
    }

    // Performance Optimization: Eradicate heap page faults by allocating standard 256-byte stack frame
    constexpr size_t kMaxTitleBufferSize = 256;
    std::array<char, kMaxTitleBufferSize> buffer{};

    // Extract the textual character layout representation safely into the array boundary limits
    const int safeLength = (titleLength < static_cast<int>(kMaxTitleBufferSize - 1)) 
                           ? titleLength 
                           : static_cast<int>(kMaxTitleBufferSize - 1);

    if (::GetWindowTextA(foregroundHwnd, buffer.data(), safeLength + 1) == 0) {
        return false;
    }

    // 3. Construct zero-overhead string view over stack memory allocation strings
    const std::string_view activeTitle(buffer.data(), static_cast<size_t>(safeLength));
    
    // 4. Check for direct target process identity window string occurrence mappings
    return activeTitle.find(Config::TARGET_WINDOW_TITLE) != std::string_view::npos;
}

} // namespace VRT::WindowManager
