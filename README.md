# vRotator: Data-Driven Hardware-Injected Automation Framework

An enterprise-grade, ultra-low-latency automation ecosystem designed for MMORPG client optimization. The framework bridges pure in-game runtime data extraction via a decoupled Lua subsystem with a compiled native Windows background worker using an asynchronous, non-IPC, high-speed RGB visual signaling protocol.

---

## ⚖️ LEGAL, SAFETY & ANTI-CHEAT DISCLAIMER (MIT LICENSE INVARIANT)

> **⚠️ CRITICAL NOTICE — READ CAREFULLY BEFORE DEPLOYING THIS ARCHITECTURE**
> 
> This repository and all compiled/interpreted codebase assets contained herein are provided strictly for **educational, architectural analysis, and research purposes only**. 
> 
> By compiling, launching, or interacting with the `vRotator` framework, you explicitly acknowledge and agree to the following terms:
> 
> 1. **No Affiliation & Fair Use:** This project is not affiliated, associated, authorized, endorsed by, or in any way officially connected with Blizzard Entertainment, Inc., or any of its subsidiaries or affiliates. All product and company names are trademarks™ or registered® trademarks of their respective holders.
> 2. **Anti-Cheat & Account Security Risks:** Automated client progression, frame sampling, and hardware injection techniques may violate the End User License Agreement (EULA) or Terms of Service (ToS) of commercial MMORPG environments. Use of this software carries an inherent risk of permanent account termination, software bans, or hardware profiling flags. The authors assume **absolute zero liability** for any punitive actions executed by anti-cheat telemetry algorithms.
> 3. **Hardware Emulation Control Warning:** The `vrotator_clicker` application utilizes low-level Win32 `SendInput` routines to preempt the operating system keyboard ring buffer. Misconfiguration or execution loops under hyper-accelerated poll rates can result in localized OS lockups, keystroke flooding, or input driver freezing.
> 4. **WARRANTY EXCLUSION (As-Is Basis):** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---


## 🚀 Quick Start & Compilation

### Local Visual Studio & CMake Setup
From the repository root workspace directory, execute the meta-build system pipeline to compile a standalone statically-linked binary:
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
./build/vrotator_clicker.exe

# or just
make
```
The optimized native binary target will compile and deploy straight into the `build/` folder root directory as `vrotator_clicker.exe`.

## 🏗️ System Architecture Overview

The repository is organized into isolated structural layers adhering strictly to the Single Responsibility Principle (SRP) and decoupling game-client logical matrices from the Windows OS layer:

```text
vRotator-Workspace/
├── .github/workflows/    # CI/CD pipelines (Automated MSVC cross-compilation release workflows)
├── .vscode/              # IDE workspace visualization configurations
├── build/                # Local compilation output artifacts (Git-ignored)
├── include/              # Native C++ abstraction headers (C++17 contracts)
│   ├── config.hpp        # Global compile-time parameter constants and safety limits
│   ├── input_engine.hpp  # High-performance simulation execution interfaces
│   ├── pixel_reader.hpp  # High-speed GDI graphics device memory data collectors
│   └── window_manager.hpp# OS process focus and visibility monitoring tracking contracts
├── src/                  # Native C++ execution modules (Win32 Core Engine)
│   ├── input_engine.cpp  # Stack-allocated ring-0 hardware sequence injection control
│   ├── main.cpp          # Non-nested flat async orchestrator & differential log tree
│   ├── pixel_reader.cpp  # Zero-copy window-space graphics context device sampler
│   └── window_manager.cpp# Heap-free active workspace foreground verification filter
├── tests/                # Isolated integration and automated component unit tests
├── vrotator/             # Pure Lua game-client data abstraction framework (AddOn)
├── CMakeLists.txt        # Top-level meta-build system layout linking static runtimes
└── README.md             # Global architecture manifesto and structural specification
```

## 📡 Cross-Process RGB Signaling Protocol Specification

Data transfer from the game client to the native execution core bypasses standard IPC vectors (which are monitored by game client anti-cheat heuristics) by projecting an arithmetic data packet directly onto an isolated screen space coordinate boundary.

The background worker samples pixel data through a persistent, cached window device context handle wrapper via high-speed GDI graphics rendering memory mappings (`GetPixel`), targeted at local client workspace coordinates `(2, 2)`—the absolute safe center of the `5x5` pixel matrix to circumvent any Aero desktop window manager color distortion or edge-blur filters:

* **Red Channel (`R`):** Pure Virtual-Key representation of the target hardware keybound token character mapped from the client's internal binding dictionary (e.g., `49` for key `1`, `81` for key `Q`, `113` for key `F2`). Matches 1:1 with native Win32 virtual-key values.
* **Green Channel (`G`):** Arithmetically packed bitmask payload representing simultaneous keyboard modifier states:
  \[\text{ModifierCode} = (\text{Shift} \times 1) + (\text{Ctrl} \times 2) + (\text{Alt} \times 4)\]
  *Example: A simultaneous `CTRL+ALT` state evaluates to an exact Green byte integer value of \(2 + 4 = 6\).*
* **Blue Channel (`B`):** Framing validation signature field. Must evaluate to exactly **`255`**. If \(B \neq 255\) or \(R = 0\), the signal is treated as an empty execution context (`IDLE` state), transactional history is flushed, and input injection is skipped.

## ⚡ Core Engine Optimization Matrix

1. **Zero-Heap Allocation Invariant (`0ms Hot-Path Overhead`)**: Dynamic memory operations and allocations are completely eliminated from the real-time execution loop. Peripheral action sequences and string conversions run strictly on stack registers (`std::array`), bypassing OS page faults and heap fragmentation locks.
2. **Flat Guard Clauses & Sub-function Topology**: The core application execution tree loop inside `main.cpp` is broken into discrete, low-latency decoupled steps (`TrackFocusState`, `HandleOutOfFocusState`, `ProcessTraceLogging`, `DispatchHardwareAction`), passing data via a lightweight `EngineState` context wrapper. Loop indentation is kept flat using frame-skip `continue` markers to optimize branch prediction.
3. **Atomic Keystroke Serialization**: To ensure older game client engines process rapid multi-modifier bindings without keystroke drops, key input events are committed into the OS ring-0 stream via an atomic `SendInput` array transaction containing explicit hardware scan codes. The press and release stages are split by a precise `10ms` hardware pad sleep window, ensuring flawless sequence alignment under load.
