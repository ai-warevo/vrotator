#include "pixel_reader.hpp"
#include "config.hpp"

namespace VRT::PixelReader {

namespace {

    /**
     * @class GameWindowContextWrapper
     * @brief RAII wrapper for managing the lifecycle of the target game window's device context (HDC).
     */
    class GameWindowContextWrapper {
    public:
        GameWindowContextWrapper() noexcept {
            InitializeContext();
        }

        ~GameWindowContextWrapper() noexcept {
            ReleaseContext();
        }

        // Prevent copying and moving to ensure exclusive resource ownership Invariant
        GameWindowContextWrapper(const GameWindowContextWrapper&) = delete;
        GameWindowContextWrapper& operator=(const GameWindowContextWrapper&) = delete;
        GameWindowContextWrapper(GameWindowContextWrapper&&) = delete;
        GameWindowContextWrapper& operator=(GameWindowContextWrapper&&) = delete;

        /**
         * @brief Validates the active window state and recovers the graphics handle if invalid.
         * @return A calibrated and ready Win32 Device Context pointer (HDC).
         */
        [[nodiscard]] HDC GetContext() noexcept {
            if (!m_hwnd || !::IsWindow(m_hwnd)) {
                ReleaseContext();
                InitializeContext();
            }
            return m_hdc;
        }

    private:
        HWND m_hwnd = nullptr;
        HDC  m_hdc  = nullptr;

        void InitializeContext() noexcept {
            m_hwnd = ::FindWindowA(nullptr, Config::TARGET_WINDOW_TITLE);
            if (m_hwnd) {
                // Safely grab the DC of the client workspace area instead of the absolute display surface
                m_hdc = ::GetDC(m_hwnd);
            }
        }

        void ReleaseContext() noexcept {
            if (m_hdc && m_hwnd) {
                ::ReleaseDC(m_hwnd, m_hdc);
            }
            m_hwnd = nullptr;
            m_hdc = nullptr;
        }
    };

} // namespace

COLORREF ReadSignalPixel() {
    // Globally cached thread-safe instance framework (Meyers Singleton Pattern)
    static GameWindowContextWrapper windowContext;
    const HDC hdc = windowContext.GetContext();

    // Fallback protection: Return absolute black if target execution workspace handle is missing
    if (!hdc) {
        return RGB(0, 0, 0);
    }

    // High-performance microsecond extraction target boundary shifting into matrix center safe zones (2,2)
    return ::GetPixel(hdc, 2, 2);
}

} // namespace VRT::PixelReader
