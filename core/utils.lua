VRT = VRT or {}

function VRT.Log(text)
    if VRT.DebugMode then
        print("|cff00ffff[vrotator]|r " .. text)
    end
end

function VRT.HasBuff(unit, spellID, onlyPlayer)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, caster, _, _, id = UnitBuff(unit, i)
        if not name then
            break
        end

        if id == spellID and (not onlyPlayer or caster == "player") then
            return true
        end
    end
    return false
end

function VRT.HasDebuff(unit, spellID, onlyPlayer)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, caster, _, _, id = UnitDebuff(unit, i)
        if not name then
            break
        end
        
        if id == spellID and (not onlyPlayer or caster == "player") then
            return true, caster
        end
    end
    return false, nil
end

function VRT.IsSpellReady(spellID)
    local start, duration = GetSpellCooldown(spellID)
    return (start == 0 and duration == 0)
end

-- https://www.wowhead.com/wotlk/spell=61304/global-cooldown
function VRT.IsGCD()
    local start, duration = GetSpellCooldown(61304)
    return (start > 0 and duration > 0 and duration <= 1.5)
end

function VRT.IsCastingOrChanneling()
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return true
    end

    return false
end

function VRT.CheckBuffAndSend(unit, checkBuffs, actionSpells, onlyMyCast)
    local hasAnyBuff = false
    for _, buffID in ipairs(checkBuffs) do
        if VRT.HasBuff(unit, buffID, onlyMyCast) then
            hasAnyBuff = true
            break
        end
    end

    if not hasAnyBuff then
        for _, spellID in ipairs(actionSpells) do
            local bind = VRT.MyBinds[spellID]
            if bind then
                VRT.SendBindSignal(bind)
                return true
            end
        end
    end

    return false
end

function VRT.DetectPlayerSpec()
    local _, classFilename = UnitClass("player")
    local playerClass = classFilename:lower()
    
    for specName, rotationModule in pairs(VRT.Rotations) do
        local isMatch = (not rotationModule.className or rotationModule.className == playerClass) 
                        and rotationModule.IsActive 
                        and rotationModule.IsActive()
        
        if isMatch then
            VRT.CurrentRotation.Combat = rotationModule.Combat
            VRT.CurrentRotation.Buffs = rotationModule.Buffs
            return specName
        end
    end
    return nil
end
