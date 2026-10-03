# vRotator Clicker Abstraction Architecture Headers (`/include`)

This module provides standard decoupled object headers and type interface layouts establishing contract consistency across individual compilation targets.

## 📋 Architectural Contract Layouts

### 1. `config.hpp` (Global Dextral Parameters Compile-Time Manifest)
Central source of truth storing immutable `constexpr` parameters regulating execution limits, thread times, and environmental target variables.
* `TARGET_WINDOW_TITLE`: Precise string representation used for active window verification targeting.
* `ENFORCE_WINDOW_FOCUS`: System toggle switching background thread thread-sleep protection rules.
* `EMERGENCY_EXIT_HOTKEY`: Win32 virtual identifier constant configuring the manual termination hook (`VK_F11`).
* `LOOP_POLL_RATE_MS`: Throttling tick delay regulating frame timing alignment (~60-70Hz refresh rate sync).
* `INPUT_COOL_DOWN_MS`: Hardware action validation padding preventing multi-execution client frame duplicate macro locks.

### 2. `window_manager.hpp`
Exposes the core contract interface tracking process focusing states. Isolates client state checks away from lower processing blocks.

### 3. `pixel_reader.hpp`
Exposes high-speed graphical extraction pointers returning native `COLORREF` struct values wrapped away from the orchestrator main pipeline.

### 4. `input_engine.hpp`
Declares peripheral simulation contracts converting numeric tokens into pure physical hardware state alterations.
