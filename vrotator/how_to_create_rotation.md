# Developer Guide: Designing, Registering, and Modifying Custom Rotations

This manifest establishes the strict architectural sequence required to modify existing rotations or bootstrap a completely new class/spec specialization module within the VRotator data-driven ecosystem.

---

## ⚡ TL;DR (Quick Checklist)
To register a new rotation or modify an existing one, you must execute exactly 4 steps:
1. **Append Spells/Items:** Open `rotations/[class]/spells.lua` and inject your new numeric Spell IDs or Item IDs. Never use raw magic numbers in pipelines.
2. **Deploy Blueprint:** Open/create `rotations/[class]/[spec].lua` and declare your config map containing `isActive`, `combatPipeline`, and `buffsPipeline`.
3. **Bind Hardware Keys:** Ensure **EVERY** spell and macro used inside your pipelines is physically placed on your in-game action bars and bound to a hardware key.
4. **Synchronize TOC:** Update `vrotator.toc` by declaring your files. The class `spells.lua` **MUST** load *before* your rotation blueprints. Type `/reload` in game.

---

## 🏗️ Phase 1: Spell & Item Static Database Synchronization

Before compiling logic nodes inside a pipeline, any referenced asset identifier must exist within the static class database dictionary file.

### Step 1: Update `rotations/[class]/spells.lua`
Navigate to your specific class database path and insert your new spell integers or consumable item hashes into the central tracking table:

```lua
local Spell = VRT.Spells.Mage

-- Appending new spell runtime identifiers
Spell.FrostfireBolt  = 42842  -- Global Spell ID
Spell.DeepFreeze     = 44572  -- Talent Cap Spell ID
Spell.ManaGemItem    = 33312  -- Hardcoded Item ID (Discovered by Action Bar Scanner)
```
*⚠️ **Critical Invariant:** Never use raw, naked magic numbers inside the pipeline files. Always map them directly out of the `Spell` namespace.*

---

## 🛠️ Phase 2: Compiling the Blueprint Descriptor File

Every single specialization configuration operates as a declarative blueprint plugin.
Create or modify your target file (e.g., `rotations/mage/fire_ttw.lua`).

---

## 📡 Phase 3: Metadata Manifest Synchronization (`vrotator.toc`)

The WoW client environment cannot dynamically map directory files at runtime. Every new script introduction requires explicit static link declaration inside the table bundle framework definition file.

### Step 1: Open `vrotator.toc`
Locate your configuration layers blocks and insert the precise path pointing toward your newly created file. The deployment layout **MUST** load the base spell database file **BEFORE** the execution blueprint configurations:

```toc
# ... framework core files remain upper ...
# ...
rotations\mage\spells.lua              <-- 1. Load data variables namespace dictionary first
rotations\mage\fire_ttw.lua            <-- 2. Load execution blueprints second
rotations\mage\fire_ffb.lua
rotations\mage\new_custom_spec.lua     <-- 3. Append your new custom spec modules here
# ...
vrotator.lua
```

---

## ⚡ Phase 4: Runtime Deployment & Testing

Once text configurations are saved inside your editor space workspace, initialize synchronization hooks against the client runtime:

1. **Flush Client Files Memory Space:** Type **`/reload`** directly inside the native in-game game chat console. This forces the WoW application thread to re-compile your `.toc` mapping changes.
2. **Boot Framework Engine:** Type **`/vrt`** in chat to activate the orchestration subsystem.
3. **Verify Execution Diagnostic Logs:** Open your chat log window space. If initialization was successful, the engine dispatcher will automatically detect your class/talents using your `isActive` rule and output:
   `[vrotator] Detected spec: MageFire_TTW. Module linked successfully.`
4. If the scanner throws a validation error or skips your spec module entirely, verify that:
   * Your target spell IDs actually exist inside your class `spells.lua`.
   * Your modified script is explicitly declared inside the `vrotator.toc` manifest layout.
   * Every automation slot used inside your pipelines is manually mapped onto visible game action slots and bound to physical keyboard key parameters.
