# vRotator: High-Performance Data-Driven Client Automation Subsystem

An enterprise-grade, low-overhead reactive state machine architecture running inside the World of Warcraft client environment (WotLK 3.3.5a). By replacing nested procedural checking structures with flattened, unmodifiable strategy tables and decoupled execution layers, this subsystem guarantees a 0ms frame-time calculation footprint at 60Hz to 144Hz+ inline rendering thread rates.

---

## ⚠️ CRITICAL ARCHITECTURAL REQUIREMENTS

### 1. Strict Hardware Binding Invariant
The engine operates entirely on direct memory mapping of physical button actions via the Blizzard UI layer. 
* **The Rule:** **EVERY SINGLE SPELL, ITEM, OR MACRO** included in a `combatPipeline` or `buffsPipeline` **MUST BE EXPLICITLY PLACED ON THE ACTION BARS AND BOUND TO A PHYSICAL KEYBOARD KEY** (e.g., `1`, `ALT-Q`, `CTRL-SHIFT-Z`).
* **The Rationale:** If a spell or item is unbinded (`"NOT_BOUND"`) or left drifting on an inactive action bar, the internal scanning layer (`VRT.Scanner`) will fail to resolve its hardware trigger path. The core will instantly drop the calculation thread, flush the color signal to absolute black `(0, 0, 0)`, and refuse to process the rotation node to protect the network buffer from stack overflow.

### 2. Mandatory Macro Setup & Deployment
To automate non-spell hardware assets (like Engineering modifications and consumable bag items), you must deploy the pre-configured scripted macro blocks provided in the repository.

* **Global Item Triggers (`vrotator/rotations/macro.txt`):**
  Contains generic hardware overrides for universal slot execution. Copy these blocks into your native in-game macro panel (`/macro`) and drag them to any visible slot on your main action bars:
  * **Gloves Slot (Slot 10 - Hyperspeed Accelerators):** Must contain a dedicated `/use 10` execution string.
  * **Trinkets Slots (Slots 13 & 14):** Must contain discrete `/use 13` and `/use 14` action strings.

* **Class-Specific Triggers (`vrotator/rotations/mage/macro.txt`):**
  Contains target-specific optimization overrides for the Mage class subsystem. Copy and drag to actionbar panel:
  * **Mana Gem Activation:** Uses an isolated `/use item:33312` or named item script mapped directly to the `usable_item` automation layer.

* **Scanner Synchronization:** Once all macros and spells are arranged on your active action bars and bound to keyboard keys, type `/vrt` in chat. The `VRT.Scanner.Parser` sub-engine will instantly read the internal macro body text patterns (e.g., matching `/[Uu][Ss][Ee]%s+10` or extracting absolute numeric keys from item links), bind them to keys, and cache them under structural string keys like `"item:10"` or `"item:33312"`.

---

## 🗺️ Architectural Topology & Component Decoupling

The framework isolates state mutation, hardware mapping, string evaluation, and GUI updates into standalone functional modules:

```text
vrotator/
├── core/
│   ├── pipeline/
│   │   ├── executor.lua      # Runs specific node logic, 300ms Spell Queue windows & cast validations
│   │   ├── main.lua          # Compilation engines (BuildCombatRunner, BuildBuffsRunner) with flat loops
│   │   └── strategies.lua    # O(1) direct hardware asset cooldown lookup strategy maps
│   ├── scanner/
│   │   ├── bind.lua          # GetBindingKey data translators to normal engine layouts
│   │   ├── main.lua          # Pure mathematical 1..72 absolute action slot scanning engine
│   │   ├── parser.lua        # Non-blocking async-proof regex item/spell macro link deconstructor
│   │   ├── strategies.lua    # Action routing handlers processing macros into precise data keys
│   │   └── tooltip.lua       # Memory-isolated localized UI tooltip scraper using lazy initialization
│   ├── signal.lua            # Vertex-color stable high-priority RGB UI Thread graphics painter
│   ├── state.lua             # Low-level sensor hooks (Padded GCD tracker, cast strings, native client auras)
│   ├── utils.lua             # General helper utilities (Logging facades, dynamic talent spec detection)
│   └── vars.lua              # Core database storage, key mappings, and state dictionary pre-allocator
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
When a user invokes `/vrt`, the engine triggers a comprehensive, short-circuit hardware matrix scan. It iterates through all 60 core action buttons, bypasses nested conditions using the **Strategy Pattern**, and builds a unified execution map (`VRT.MyBinds`) in memory mathematically (calculating absolute slot IDs from 1 to 72 to preserve complete compatibility with custom UI replacements like Bartender4, Dominos, or ElvUI):

```text
[Blizzard Action Slots] ──> [VRT.Scanner Engine]
                                │
                                ├──> [strategies.lua] (Routes by Action Type: "spell"/"item"/"macro")
                                ├──> [parser.lua]     (Strips mod brackets, extracts clean item IDs)
                                └──> [tooltip.lua]    (Resolves localized string keys via hidden frame)
                                │
                                ▼
                   Generated Hash Map Cache:
                   VRT.MyBinds = {
                       [42891]        = "1",           -- Numeric Spell ID -> Hardware Button
                       ["item:10"]    = "ALT-CTRL-Q",  -- "item:SlotID"    -> Encoded Macro Bind
                       ["item:33312"] = "SHIFT-E"      -- "item:ItemID"    -> Consumable Bag Item
                   }
```

### 2. Runtime Combat Pipeline Execution
During high-frequency frame updates in combat, the engine entirely avoids dynamic memory allocations (garbage collection optimization). It loops over static tables compiled by `BuildCombatRunner` in a single linear pass, utilizing a highly advanced 300ms Spell Queue Window to evaluate casting state and pipeline priority:

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
* **Guards:** Instantly dumps execution stack at the top of the frame if `VRT.State.IsGCD()` evaluates to `true` (monitored via a network-padded safety duration ceiling of `<= 2.0s` to protect against server latency spikes), or if `VRT.State.IsCastingOrChanneling()` confirms an active spell lock.

### 💤 2. Impulse Throttled Lazy-Loaded Thread (Out-of-Combat State)
* **Trigger Window:** Initiated strictly on the `PLAYER_REGEN_ENABLED` hardware event hook.
* **Frequency:** Throttled internally down to a strict **1.0 Hz** interval using an inline time delta accumulator.
* **Operational Cycle:** Evaluates out-of-combat needs (Self-Buffs, Focus Magic maintenance, and automated item manufacturing like `Conjure Mana Gem`) over compiled flat array collections via `BuildBuffsRunner`.
* **Anti-Spam Impulse Fix:** To prevent double execution and severe keystroke spam during out-of-combat maintenance, the output visual acts as an **impulse trigger**. It paints the targeted signal color for a single frame to allow discrete external click extraction, and on the very next frame render, the cycle automatically flushes the output token back to native black `(0, 0, 0)`, ensuring flawless out-of-combat progression without clip locks.
