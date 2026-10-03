# vRotator Native Core Test Suite (`/tests`)

This directory houses the isolated integration tests and unit component test vectors for the native compiled C++17 Win32 background worker. The test suite leverages the modern amalgamated instance of the Catch2 v3.16.0 framework to maintain zero external runtime installation dependencies, eliminate memory allocations on compilation, and ensure strict validation of the hot-path execution blocks.

## 🏗️ Test Workspace Topology

```text
tests/
├── catch2/
│   ├── catch_amalgamated.hpp # Catch2 v3.16.0 amalgamated header (Auto-downloaded)
│   └── catch_amalgamated.cpp # Catch2 v3.16.0 compiled engine runner (Auto-downloaded)
├── test_input_engine.cpp     # Unit tests validating arithmetic modifier unpacking & scan codes
├── test_pixel_reader.cpp    # Integration tests validating graphics sampling contexts & fallbacks
├── test_window_manager.cpp  # Unit tests validating stack-allocated title string boundaries
└── README.md                 # This updated C++ testing architecture specification
```

## 🛠️ Automated Compilation & Execution Layout

The testing workflow is completely automated and tightly coupled with the master project workspace build routines via the top-level meta-build system configuration. 

To execute a clean compilation from absolute zero and run the full verification test suite target (`vrotator_tests.exe`), invoke the automation pipeline direct mandate through the terminal workspace tracker:

```bash
# Triggers a full repository rebuild, fetches dependencies, and executes the Catch2 v3 suite directly
make test
```

## 📋 Core Test Vector Specifications

### 1. Bitmask Payload Deconstruction & Scan Codes (`test_input_engine.cpp`)
Validates that the input processing logic correctly unpacks packed arithmetic integer modifier codes from the Green (`G`) channel and handles low-level peripheral tracking layout states safely:
* **Vector 0 (No Modifiers):** Payload bitmask `0` must generate clean isolated structural responses confirming all system modifier key parameters (`Shift`, `Ctrl`, `Alt`) evaluate to `false`.
* **Vector 6 & 7 (Multi-Modifiers):** Payloads `6` and `7` must mathematically unpack to verify precise simultaneous combinations (`CTRL+ALT` and `SHIFT+CTRL+ALT`) required to drive triple-modifier capabilities.
* **Hardware Scan Codes:** Directly executes Win32 `MapVirtualKeyA` constraints to prove that hardware scan code bindings match standard layouts (e.g., matching `0x10` for key `Q`, `0x02` for key `1`, `0x3B` for key `F1`) to guarantee anti-cheat bypass.

### 2. Stack Buffer Invariant Protections (`test_window_manager.cpp`)
Enforces the safety bounds of the strict heap-free window active state validator logic to protect the background thread loops from system exploitation:
* **String Matching Verification:** Ensures foreground window title checks accurately detect sub-string sequences containing `World of Warcraft` regardless of screen spec extensions, architectures, or windowed borderless wrapper modes.
* **Buffer Overflow Resilience:** Mathematically tests simulated long text buffers against the stack allocation bounds (`std::array<char, 256>`), ensuring that character strings truncate at a rigid 255-character ceiling without triggering access violations.

### 3. GDI Graphics Sampling & Memory Fallbacks (`test_pixel_reader.cpp`)
Coordinates safety verification across the primary display device context extraction stream logic layers:
* **Coordinate Space Centering:** Proves that matrix offset selections map perfectly to coordinate properties `(2,2)` inside the matrix center to isolate text colors away from windows boundaries.
* **Dynamic Failure Robustness:** Programmatically queries active operational handles, verifying that if the targeted workspace context drops or evaluates to `nullptr` (e.g., game client minimized or killed), the core gracefully falls back to `RGB(0,0,0)` to avoid engine runtime crashes.
