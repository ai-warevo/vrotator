#pragma once

/**
 * @namespace VRT::WindowManager
 * @brief Subsystem responsible for tracking the focus and visibility state of the target game process window.
 */
namespace VRT::WindowManager {
    /**
     * @brief Evaluates whether the primary game client application window is currently active and focused in the foreground.
     * @return true if the game window is currently processing foreground interactions, false otherwise.
     */
    bool IsGameWindowActive();
}
