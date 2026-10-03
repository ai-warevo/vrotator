# vRotator Clicker Source Implementation (`/src`)

This directory houses the concrete C++17 implementations executing platform-specific operations against the Win32 subsystem. Every module is strictly optimized to guarantee a zero-heap allocation footprint on high-frequency execution ticks.

## ⚙️ Execution Modules Description

* **`main.cpp` (System Orchestrator Core):**
  Houses the asynchronous reactive application execution tree loop. Built completely flat using the **Guard Clauses Pattern** combined with frame-skip `continue` mechanics to maximize code readability and branch prediction efficiency. Manages structural data synchronization via a lightweight `EngineState` context, processes low-latency differential telemetry log streams, evaluates high-priority asynchronous hardware interrupts using `GetAsyncKeyState(VK_F11)`, and dynamically alternates poll times between `LOOP_POLL_RATE_MS` and `INPUT_COOL_DOWN_MS`.

* **`window_manager.cpp` (OS Focus Filter):**
  Interacts with the Windows desktop thread manager layer. Queries `GetForegroundWindow()` handles and copies characters via `GetWindowTextA()`. Engineered with a fixed 256-byte stack frame allocation buffer (`std::array`) to strictly eradicate memory page faults and system heap locks on hot paths, ensuring peripheral execution is locked to the targeted process without arbitrary keyboard leakage.

* **`pixel_reader.cpp` (High-Speed Memory Graphics Stream):**
  Encapsulates target context lookup via an isolated resource management wrapper (RAII) inside an anonymous namespace layer. Acquires a direct persistent handle referencing the localized game client window workspace region instead of the absolute screen frame. Invokes microsecond-level color extractions via GDI memory mapping blocks (`GetPixel`) targeted at safe matrix coordinates `(2,2)`, caching tracking pointers locally via a Meyers Singleton to completely eradicate resource leaks and pipeline stuttering.

* **`input_engine.cpp` (Kernel-Level Hardware Injection Control):**
  Unpacks arithmetically encoded byte modifiers via deterministic bitwise masking. Constructs compact, fixed-size transaction batches entirely inside localized stack registers (`std::array<INPUT, 4>`). Combines physical modifiers and target keys with native hardware scan codes mapped via `MapVirtualKeyA`, injecting raw execution sequences straight into the Windows ring-0 input ring via atomic `SendInput` arrays separated by a rigid 10ms hold padding window to prevent keystroke preemption drops.
