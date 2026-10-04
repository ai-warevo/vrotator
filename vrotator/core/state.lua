VRT = VRT or {}
VRT.State = VRT.State or {}

---
-- @public Aura Scanner Component
-- @param unit string Target identifier hash (e.g., "player", "target", "focus").
-- @param spellID number Unique numeric Blizzard Spell ID wrapper.
-- @param onlyPlayer boolean Strict constraint flag filtering for player-applied auras.
-- @return boolean true if target aura exists and matches application constraints.
---
function VRT.State.HasBuff(unit, spellID, onlyPlayer)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, caster, _, _, id = UnitBuff(unit, i)
        if not name then break end

        if id == spellID and (not onlyPlayer or caster == "player") then
            return true
        end
    end
    return false
end

---
-- @public Negative Aura Scanner Component
-- @param unit string Target identifier hash (e.g., "player", "target", "focus").
-- @param spellID number Unique numeric Blizzard Spell ID wrapper.
-- @param onlyPlayer boolean Strict constraint flag filtering for player-applied debuffs.
-- @return boolean true if target debuff exists and matches application constraints.
-- @return string Identifier of the aura caster or nil.
---
function VRT.State.HasDebuff(unit, spellID, onlyPlayer)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, caster, _, _, id = UnitDebuff(unit, i)
        if not name then break end
        
        if id == spellID and (not onlyPlayer or caster == "player") then
            return true, caster
        end
    end
    return false, nil
end

---
-- @public Hardware Spell Cooldown Evaluator
-- @param spellID number Target Spell ID integer.
-- @return boolean true if spell cooldown is completely flushed and ready to queue.
---
function VRT.State.IsSpellReady(spellID)
    local start, duration = GetSpellCooldown(spellID)
    return (start == 0 and duration == 0)
end

---
-- @public Global Cooldown Monitor
-- @return boolean true if global network queue cooldown is currently blocking execution.
---
function VRT.State.IsGCD()
    if not VRT.Spells or not VRT.Spells.GCD then return false end
    local start, duration = GetSpellCooldown(VRT.Spells.GCD)
    return (start > 0 and duration > 0 and duration <= 2.0)
end

---
-- @public Action Thread Pipeline Guard
-- @return boolean true if player frame status is locked inside standard active cast strings.
---
function VRT.State.IsCastingOrChanneling()
    return (UnitCastingInfo("player") or UnitChannelInfo("player")) and true or false
end

---
-- @public Movement Sensor Hook
-- @return boolean true if the player character is currently moving.
---
function VRT.State.IsMoving()
    return (GetUnitSpeed("player") or 0) > 0
end
