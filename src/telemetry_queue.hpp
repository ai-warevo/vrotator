#ifndef TELEMETRY_QUEUE_HPP
#define TELEMETRY_QUEUE_HPP

#include <atomic>
#include <cstdint>
#include <array>
#include <cstring>
#include <windows.h>

namespace VRT {

enum class TelemetryEventType : uint8_t {
    FocusChange,
    PixelState,
    HardwareAction,
    SystemLog
};

struct TelemetryPacket {
    uint64_t timestamp; // Using GetTickCount64() for performance in producer
    TelemetryEventType type;
    union {
        struct {
            bool focusActive;
        } focusChange;
        struct {
            COLORREF color;
        } pixelState;
        struct {
            int key_r;
            int key_g;
        } hardwareAction;
        struct {
            char message[64];
        } systemLog;
    };
};

/**
 * @brief A Lock-Free Single Producer Single Consumer (SPSC) Ring Buffer.
 * Optimized for minimal latency in the producer thread.
 */
template <size_t Capacity>
class SPSCQueue {
public:
    static_assert((Capacity & (Capacity - 1)) == 0, "Capacity must be a power of 2");

    SPSCQueue() : head_(0), tail_(0) {}

    bool push(const TelemetryPacket& packet) noexcept {
        const size_t head = head_.load(std::memory_order_relaxed);
        const size_t next_head = (head + 1) & mask_;
        if (next_head == tail_.load(std::memory_order_acquire)) {
            return false; // Queue full
        }
        buffer_[head] = packet;
        head_.store(next_head, std::memory_order_release);
        return true;
    }

    bool pop(TelemetryPacket& packet) noexcept {
        const size_t tail = tail_.load(std::memory_order_relaxed);
        if (tail == head_.load(std::memory_order_acquire)) {
            return false; // Queue empty
        }
        packet = buffer_[tail];
        tail_.store((tail + 1) & mask_, std::memory_order_release);
        return true;
    }

private:
    std::array<TelemetryPacket, Capacity> buffer_;
    const size_t mask_ = Capacity - 1;
    alignas(64) std::atomic<size_t> head_;
    alignas(64) std::atomic<size_t> tail_;
};

} // namespace VRT

#endif // TELEMETRY_QUEUE_HPP
