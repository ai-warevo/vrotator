# vRotator Clicker Abstraction Architecture Headers (`/include`)

This module provides standard decoupled object headers and type interface layouts establishing strict contract consistency across individual compilation targets. All interfaces are engineered for maximum performance, enforcing a Zero-Heap Allocation Invariant on high-frequency execution threads.

## 📋 Architectural Contract Layouts

### 1. `config.hpp` (Global Parameters Compile-Time Manifest)
Central source of truth storing immutable `constexpr` parameters regulating execution limits, thread times, and environmental target variables.
* `TARGET_WINDOW_TITLE`: Precise string representation used for active window verification targeting (e.g., "World of Warcraft").
* `ENFORCE_WINDOW_FOCUS`: System toggle switching background thread thread-sleep protection rules (forces sleep cycles if the game is minimized or out of focus).
* `EMERGENCY_EXIT_HOTKEY`: Win32 virtual key identifier constant configuring the manual termination hook (`VK_F11`).
* `LOOP_POLL_RATE_MS`: Throttling tick delay regulating frame timing alignment (~60-70Hz refresh rate sync, defaults to 15ms).
* `INPUT_COOL_DOWN_MS`: Post-execution hardware safety padding window preventing multi-execution client frame duplicate macro locks (defaults to 50ms).

### 2. `window_manager.hpp`
Exposes the core contract interface tracking process focus states. Isolates process-specific window visibility checks away from lower peripheral processing blocks. Implemented via static stack frames (`std::array`) to bypass standard system memory allocations on the hot path.

### 3. `pixel_reader.hpp`
Exposes high-speed graphical extraction routines returning native Win32 `COLORREF` struct values wrapped away from the orchestrator main pipeline. Utilizes a cached Meyers Singleton device context wrapper (`HDC`) to eliminate window handle leakage and kernel-level resource allocation spikes.

### 4. `input_engine.hpp`
Declares peripheral simulation contracts converting mathematically packed numeric modifier tokens into pure physical hardware state alterations. Orchestrates synchronous sequential keyboard execution structures injected directly into the OS input ring-0 ring via atomic `SendInput` batches.
