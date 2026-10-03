/*
## 5. src/pixel_reader.cpp (Реализация захвата пикселя через GDI)

* Зона ответственности: Взаимодействие с интерфейсом графических устройств Windows (Graphics Device Interface).
* Что должен делать:
1. При первом вызове захватывать контекст устройства всего экрана (HDC) через низкоуровневый вызов GetDC(NULL).
   2. Считывать цвет в абсолютных экранных координатах (0, 0) (верхний левый угол монитора, где аддон рисует пиксель) с помощью сверхбыстрой функции GetPixel().
   3. Кэшировать дескриптор HDC в памяти процесса для исключения утечек ресурсов и просадок производительности.
   4. Обеспечивать корректное освобождение контекста ReleaseDC при деструктуризации или закрытии программы.
*/

#include "pixel_reader.hpp"
#include "config.hpp"

namespace VRT::PixelReader {

    // Внутренний RAII-класс для жесткой привязки к контексту игрового окна
    class GameWindowContextWrapper {
    public:
        GameWindowContextWrapper() {
            InitializeContext();
        }

        ~GameWindowContextWrapper() {
            ReleaseContext();
        }

        HDC GetContext() {
            // Проверяем валидность хэндла окна. Если игра была перезапущена,
            // или хэндл инвалидировался — переинициализируем контекст на лету
            if (!m_hwnd || !IsWindow(m_hwnd)) {
                ReleaseContext();
                InitializeContext();
            }
            return m_hdc;
        }

    private:
        HWND m_hwnd = nullptr;
        HDC  m_hdc  = nullptr;

        void InitializeContext() {
            // Ищем окно по строгому имени из конфигурационного манифеста
            m_hwnd = FindWindowA(NULL, Config::TARGET_WINDOW_TITLE);
            if (m_hwnd) {
                // Получаем DC не всего экрана, а конкретно клиентской области игры
                m_hdc = GetDC(m_hwnd);
            }
        }

        void ReleaseContext() {
            if (m_hdc && m_hwnd) {
                ReleaseDC(m_hwnd, m_hdc);
            }
            m_hwnd = nullptr;
            m_hdc = nullptr;
        }
    };

    COLORREF ReadSignalPixel() {
        // Кэшируем контекст игрового окна в памяти процесса (Meyers Singleton)
        static GameWindowContextWrapper windowContext;
        HDC hdc = windowContext.GetContext();

        if (!hdc) {
            return RGB(0, 0, 0); // Окно игры не найдено -> возвращаем черный цвет (IDLE)
        }

        // Считываем цвет из безопасного центра матрицы 5х5 (смещение на 2 пикселя внутрь).
        // Теперь координаты (2,2) аппаратно привязаны к внутренней графике WoW.
        return GetPixel(hdc, 2, 2);
    }
}
