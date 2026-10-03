# vRotator: High-Performance Data-Driven Client Automation Subsystem

An enterprise-grade, low-overhead reactive state machine inside the World of Warcraft client environment (WotLK 3.3.5a). By replacing nested procedural checking architecture with flattened, unmodifiable strategy tables and decoupled layout layers, this subsystem guarantees a 0ms frame-time calculation footprint at 60+ FPS.

---

## ⚠️ CRITICAL ARCHITECTURAL REQUIREMENTS (READ BEFORE USE)

### 1. Strict Hardware Binding Invariant
The engine operates entirely on direct memory mapping of physical button actions via the Blizzard UI layer. 
* **Rule:** **EVERY SINGLE SPELL, ITEM, OR MACRO** included in a `combatPipeline` or `buffsPipeline` **MUST BE EXPLICITLY PLACED ON THE ACTION BARS AND BOUND TO A PHYSICAL KEYBOARD KEY** (e.g., `1`, `ALT-Q`, `CTRL-SHIFT-5`).
* **Why:** If a spell or item is unbinded (`"NOT_BOUND"`) or left drifting on an inactive action bar, the internal scanning layer (`VRT.Scanner`) will fail to resolve its hardware trigger path. The core will instantly drop the calculation thread, zeroes the color signal, and refuse to process the rotation node to protect the network buffer from stack overflow.

### 2. Mandatory Macro Setup & Deployment
To automate non-spell hardware assets (like Engineering modifications and consumable bag items), you must deploy the pre-configured scripted macro blocks provided in the repository.

* **Global Item Triggers (`vrotator/rotations/macro.txt`):**
  Contains generic hardware overrides for universal slot execution. Copy these blocks into your native in-game macro panel (`/macro`) and drag them to any visible slot on your main action bars:
  * **Gloves Slot (Slot 10 - Hyperspeed Accelerators):** Must contain a dedicated `/use 10` execution string.
  * **Trinkets Slots (Slots 13 & 14):** Must contain discrete `/use 13` and `/use 14` action strings.

* **Class-Specific Triggers (`vrotator/rotations/mage/macro.txt`):**
  Contains target-specific optimization overrides for the Mage class subsystem. Copy and drag to actionbar panel:
  * **Mana Gem Activation:** Uses an isolated `/use item:33312` or named item script mapped directly to the `usable_item` automation layer.

* **Scanner Synchronization:** Once all macros and spells are arranged on your active action bars and bound to keyboard keys, type `/vrt` in chat. The `VRT.Scanner.Parser` sub-engine will instantly read the internal macro body text patterns (e.g., matching `/[Uu][Ss][Ee]%s+10`), bind them to keys, and cache them under structural string keys like `"item:10"`.

---

## 🗺️ Architectural Topology & Component Decoupling

The framework isolates state mutation, hardware mapping, string evaluation, and GUI updates into standalone functional modules:

```text
vrotator/
├── core/
│   ├── pipeline/
│   │   ├── executor.lua      # Runs specific node logic and macro validations
│   │   ├── main.lua          # Compilation engines (BuildCombatRunner, BuildBuffsRunner)
│   │   └── strategies.lua    # O(1) direct hardware asset cooldown lookup strategy maps
│   ├── scanner/
│   │   ├── bind.lua          # Low-level translation from client frames to hardware key mappings
│   │   ├── main.lua          # Flat orchestrator executing the main interface scan loop
│   │   ├── parser.lua        # Pure logic text deconstruction engine for multi-line macros
│   │   ├── strategies.lua    # Action routing handlers (spell, item, macro action routing)
│   │   └── tooltip.lua       # Memory-isolated localized UI tooltip scraper
│   ├── signal.lua            # High-priority UI Thread RGB Pixel graphics painter
│   ├── state.lua             # Low-level sensor hooks (GCD, cast strings, native client auras)
│   ├── utils.lua             # General helper utilities (Logging, dynamic spec detection)
│   └── vars.lua              # Core database storage and state dictionary pre-allocator
├── rotations/
│   └── mage/
│       ├── fire_ffb.lua      # FFB Mage priority blueprint data record
│       ├── fire_ttw.lua      # TTW Mage priority blueprint data record
│       └── spells.lua        # Class-specific static database constants dictionary
├── vrotator.lua              # Main event dispatcher and dynamic context thread switcher
└── vrotator.toc              # Metadata manifest regulating static compilation load order
```

---

## 📊 Core Data Flows & Engine Memory Schemas

### 1. Interface Deconstruction Pipeline (`VRT.Scanner`)
When a user invokes `/vrt`, the engine triggers a comprehensive, short-circuit hardware matrix scan. It iterates through all 60 core action buttons, bypasses nested conditions using the **Strategy Pattern**, and builds a unified execution map (`VRT.MyBinds`) in memory:

```text
[Blizzard Action Slots] ──> [VRT.Scanner Engine]
                                │
                                ├──> [strategies.lua] (Routes by Action Type: "spell"/"item"/"macro")
                                ├──> [parser.lua]     (Strips mod brackets, matches /cast or /use)
                                └──> [tooltip.lua]    (Resolves localized string keys)
                                │
                                ▼
                   Generated Hash Map Cache:
                   VRT.MyBinds = {
                       [42891]      = "1",            -- Numeric Spell ID -> Hardware Button
                       ["item:10"]  = "ALT-CTRL-Q",   -- "item:SlotID"    -> Encoded Macro Bind
                       ["item:33312"] = "SHIFT-E"     -- "item:ItemID"    -> Consumable Bag Item
                   }
```

### 2. Runtime Combat Pipeline Execution
During high-frequency frame updates in combat, the engine entirely avoids dynamic memory allocations (garbage collection optimization). It loops over static tables in a single linear pass:

```text
[Engine OnUpdate Frame Tick]
             │
             ▼
    [Is Asset Off Cooldown?] ──(NO)──> [Skip Node Immediately]
             │ (YES)
             ▼
    [ custom cond() predicate ] ──(FALSE)─> [Skip Node Immediately]
             │ (TRUE)
             ▼
    [Fetch Key from VRT.MyBinds] ──> [Paint Window Boundary Pixel via GDI] ──> [Halt Frame execution]
```

---

## 🎛️ Dual-Loop Thread Execution Engine

To preserve maximum performance overhead safety in both heavy raid environments and peaceful zones, `vrotator.lua` coordinates strict execution routing:

### ⚡ 1. Real-Time High-Speed Thread (Combat State)
* **Trigger Window:** Initiated strictly on the `PLAYER_REGEN_DISABLED` hardware event hook.
* **Frequency:** Native frame render updates (60Hz – 144Hz+ inline rendering thread).
* **Guards:** Instantly dumps execution stack at the top of the frame if `VRT.State.IsGCD()` evaluates to `true`, or if `VRT.State.IsCastingOrChanneling()` confirms an active spell lock. No out-of-combat processing occurs.

### 💤 2. Throttled Lazy-Loaded Thread (Out-of-Combat State)
* **Trigger Window:** Initiated strictly on the `PLAYER_REGEN_ENABLED` hardware event hook.
* **Frequency:** Throttled internally down to a strict **1.0 Hz** interval using an inline time delta accumulator (`buffTimeElapsed = buffTimeElapsed + elapsed`).
* **Operational Cycle:** Evaluates out-of-combat needs (Self-Buffs, Focus Magic maintenance, and automated item manufacturing like `Conjure Mana Gem`). 
* **Signal Clearance:** Implements an implicit inline fallback check: if the active module returns `false` (meaning all states are green), it flushes the output pixel token back to native black `(0, 0, 0)` instantly, preventing external keystroke loop deadlocks.

---

## 📋 Cross-Module Dependency & TOC Load Order Manifesto

Because modules reference shared tables, order of execution compilation is strictly structured inside the `.toc` manifest to eliminate `nil value` indexing crashes:

1. **`core\vars.lua`**: Memory Pre-allocator. Initializes central table namespaces (`VRT.Scanner`, `VRT.Pipeline`, etc.) before any file injects logic functions.
2. **`core\state.lua`**: Independent Layer. Directly tracks native hardware client APIs (Auras, Cast bars, GCDs). Has zero external framework dependencies.
3. **`core\utils\main.lua`**: Utility Layer. Exposes general functional facades (`VRT.Log`, `VRT.CheckBuffAndSend`, `VRT.DetectPlayerSpec`).
4. **`core\scanner\*`**: Interface Scan Subsystem. Parsers, tooltips, binding allocators, and strategy routers execute as an isolated cluster.
5. **`core\signal.lua`**: Visualization Output Layer. Controls the hardware pixel framework window painter coordinates.
6. **`core\pipeline\*`**: Compilation & Automation Machinery. Loads strategies, executes nodes, and structures the loop generation logic.
7. **`rotations\*`**: Blueprint Configurations. Class databases and spec arrays read the framework structures to deploy declarative priority blueprints.
8. **`vrotator.lua`**: Orchestration Core. Binds the main window dispatcher loops and CLI endpoints, booting the finalized infrastructure.
