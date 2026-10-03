# vRotator AddOn Pure Lua Simulation Suite (`vrotator/tests`)

This directory implements a lightweight, memory-isolated in-game testing harness designed specifically to validate the reactive state-machine logic, macro parsing regex patterns, and pipeline compilation sequences within the sealed Blizzard execution sandbox environment.

## 🏗️ Subsystem Mock Framework Topology

```text
vrotator/tests/
├── framework.lua         # Lightweight Test Runner orchestrator (Asserts, Assertions & Log formatters)
├── mock_blizzard_api.lua # Dynamic override injection layer hooks (Simulates GCD and learned Auras)
├── test_macro_parser.lua # Test assertions validating text regex patterns and Item ID extractions
├── test_pipeline_engine.lua # Asserts testing the 300ms Spell Queue and state transitions
└── README.md             # This Lua test automation specification
```

## 🚀 Execution & Driver Mechanics

Because the code executes within the sealed World of Warcraft UI thread environment, the tests are triggered via a dedicated client slash command router interface.

Type the following deployment command directly into the in-game chat box to run the suite:
```text
/vrt test
```

The runtime suite captures the engine namespaces, temporarily detaches production environment bindings, injects the state mock table drivers, runs compilation validation checks, and prints clean visual pass/fail logging results directly into the client main chat frame (`DEFAULT_CHAT_FRAME`).

## 📋 Lua Test Vector Specifications

### 1. Macro Deconstruction Matrix (`test_macro_parser.lua`)
Ensures that string mutations and regex extractions execute deterministically regardless of localization or conditional modifiers:
* **Cyrillic Command Extraction:** Tests if `/заклинание Ледяной доспех` or `/испол Сапфировый камень маны` maps cleanly to its corresponding structural data.
* **Bracket Conditional Truncation:** Feeds text containing execution conditions like `/cast [target=focus, harm] Fireball` to ensure it strips bracket configurations down to the target key token without dropping characters.
* **Asynchronous Non-blocking Item Lookups:** Validates that item string names (e.g., `/use Сапфировый камень маны`) resolve into explicit numeric entries like `"item:33312"`, preventing frame calculation blocking.

### 2. Spell Queue Window & GCD Network Padding (`test_pipeline_engine.lua`)
Validates that runtime execution blocks maintain structural boundaries during combat transitions and latency spikes:
* **GCD Safety Ceiling Check:** Simulates a server latency lag spike where `GetSpellCooldown` returns a duration of `1.64` seconds, confirming that the network-padded `VRT.State.IsGCD()` logic evaluates strictly to `true` and flushes the pixel color to zero.
* **300ms Spell Queue Integration:** Mocks an active cast bar with exactly `250ms` remaining until completion, verifying that `ExecutePipelineNode` evaluates this state as open, bypasses standard blockades, and immediately pushes the next output token to the signaling layer.
