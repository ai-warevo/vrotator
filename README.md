# vRotator: Data-Driven Hardware-Injected Automation Framework

An enterprise-grade, ultra-low-latency automation ecosystem designed for MMORPG client optimization. The framework bridges pure in-game runtime data extraction with a compiled native Windows background worker via an asynchronous high-speed RGB visual signaling protocol.

## 🚀 Quick Start & Compilation

### Local Visual Studio & CMake Setup
From the repository root workspace directory, invoke the MSVC compiler wrapper:
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
./build/Release/vrotator_clicker.exe 
```
The optimized native binary target will compile straight into the `build/` root folder directory as `vrotator_clicker.exe`.

## 🏗️ System Architecture Overview

The repository is organized into isolated structural layers adhering strictly to the Single Responsibility Principle (SRP) and decoupling core mechanics from the OS layer:

```text
AddOns/
├── .github/workflows/    # CI/CD pipelines (Automated MSVC compilation)
├── .vscode/              # IDE viewspace abstraction configurations
├── build/                # Local compilation artifacts (Git-ignored)
├── include/              # Native C++ abstraction headers (C++17)
├── src/                  # Native C++ execution modules (Win32 core)
├── tests/                # Isolated integration and component unit tests
├── vrotator/             # Pure Lua game-client data abstraction framework
├── CMakeLists.txt        # Top-level meta-build system configuration
└── README.md             # Global architecture manifesto
```

## 📡 Cross-Process RGB Signaling Protocol Specification

Data transfer from the game client to the native execution core bypasses standard IPC vectors (which are heavily monitored by game anti-cheat heuristics) by projecting an arithmetic data packet directly onto an isolated 5x5 screen space coordinate at the matrix boundaries `(0, 0)`.

A background thread pulls the desktop memory buffer coordinates via direct GDI access, instantly decoding individual color channel payloads:

* **Red Channel (`R`):** Virtual ASCII code representation of the primary hardware keybound character (e.g., `49` for key `1`, `65` for key `A`).
* **Green Channel (`G`):** Arithmetically packed bitmask representing standard modifier key states:
  \[\text{ModifierCode} = (\text{Shift} \times 1) + (\text{Ctrl} \times 2) + (\text{Alt} \times 4)\]
  *Example: A simultaneous `CTRL+ALT` state evaluates to a precise Green byte payload value of 2 + 4 = 6.*
* **Blue Channel (`B`):** Framing validation signature field. Must evaluate to exactly **`255`**. If `B != 255` or `R == 0`, the signal token is treated as an empty context (IDLE state), and execution is skipped.

