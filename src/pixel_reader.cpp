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

namespace VRT::PixelReader {

    // Внутренний RAII-класс для безопасного управления жизненным циклом HDC
    class DeviceContextWrapper {
    public:
        DeviceContextWrapper() {
            // 1. При первом вызове захватываем контекст устройства всего экрана (HDC)
            m_hdc = GetDC(NULL);
        }

        ~DeviceContextWrapper() {
            // 4. Обеспечиваем корректное освобождение контекста при закрытии программы
            if (m_hdc) {
                ReleaseDC(NULL, m_hdc);
            }
        }

        HDC GetContext() const { return m_hdc; }

    private:
        HDC m_hdc = nullptr;
    };

    COLORREF ReadSignalPixel() {
        // 3. Кэшируем дескриптор HDC в памяти процесса через статический синглтон
        static DeviceContextWrapper dcWrapper;
        HDC hdc = dcWrapper.GetContext();

        if (!hdc) {
            return RGB(0, 0, 0); // Если контекст невалиден, возвращаем черный цвет (IDLE)
        }

        // 2. Считываем цвет в абсолютных экранных координатах (0, 0) с помощью GetPixel()
        return GetPixel(hdc, 0, 0);
    }
}
