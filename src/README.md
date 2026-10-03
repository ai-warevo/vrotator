# vRotator Clicker Source Implementation (`/src`)

This directory houses the concrete C++17 implementations executing platform-specific operations against the Win32 subsystem.

## ⚙️ Execution Modules Description

* **`main.cpp` (System Orchestrator Core):**
  Houses the asynchronous infrastructure application execution tree loop. Manages safe initialization bindings, samples polling states tied to `LOOP_POLL_RATE_MS`, and evaluates high-priority asynchronous hardware interrupts using `GetAsyncKeyState(VK_F11)` to instantly terminate the worker thread.
* **`window_manager.cpp` (OS Focus Filter):**
  Interacts with the Windows desktop thread manager layer. Queries `GetForegroundWindow()` handles and abstracts character arrays via `GetWindowTextA()` to isolate execution strictly to the target environment process, preventing arbitrary keyboard leakage into unexpected user applications.
* **`pixel_reader.cpp` (High-Speed Memory Graphics Stream):**
  Acquires a direct persistent handle wrapper referencing the OS primary Display Context (`HDC`). Invokes microsecond-level color extractions via GDI memory mapping blocks (`GetPixel`), caching pointers locally to completely eradicate memory page fault allocation spikes.
* **`input_engine.cpp` (Kernel-Level Hardware Injection Control):**
  Unpacks the mathematically encoded arithmetic byte modifiers via low-level bitwise masking. Constructs synchronous sequential keyboard execution structures and injects raw input sequences straight into the Windows input ring-0 preemption subsystem using `SendInput()`.
