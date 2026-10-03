VRT = VRT or {}

function VRT.Log(text)
    if VRT.DebugMode then
        print("|cff00ffff[vrotator]|r " .. text)
    end
end

function VRT.HasBuff(unit, spellID)
    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, _, id = UnitBuff(unit, i)
        if not id then break end
        if id == spellID then return true end
    end
    return false
end

function VRT.HasDebuff(unit, spellID)
    for i = 1, 40 do
        local _, _, _, _, _, _, _, caster, _, _, id = UnitDebuff(unit, i)
        if not id then break end
        if id == spellID then return true, caster end
    end
    return false, nil
end

function VRT.IsSpellReady(spellID)
    local start, duration = GetSpellCooldown(spellID)
    return (start == 0 and duration == 0)
end

function VRT.IsGCD()
    local start, duration = GetSpellCooldown(42891)
    return (start > 0 and duration > 0 and duration <= 1.5)
end

function VRT.IsCastingOrChanneling()
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return true
    end
    return false
end
