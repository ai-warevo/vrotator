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

local function ExecutePipelineNode(node)
    if (node.cond and not node.cond()) or not VRT.IsSpellReady(node.id) then 
        return false 
    end
    
    local bind = VRT.MyBinds[node.id]
    if bind then
        VRT.SendBindSignal(bind)
        return true
    end
    return false
end

function VRT.RegisterRotation(config)
    if not config.name then return end

    local instance = {
        className = config.className,
        IsActive = config.isActive
    }

    -- 1. Автоматическая сборка боевой ротации (Combat Pipeline)
    if config.combatPipeline then
        instance.Combat = function()
            for i = 1, #config.combatPipeline do
                local node = config.combatPipeline[i]
                -- Логика выполнения боевой ноды
                if not (node.cond and not node.cond()) and VRT.IsSpellReady(node.id) then
                    local bind = VRT.MyBinds[node.id]
                    if bind then
                        VRT.SendBindSignal(bind)
                        return true
                    end
                end
            end
            return false
        end
    end

    -- 2. Автоматическая сборка менеджмента баффов (Buffs Pipeline)
    if config.buffsPipeline then
        instance.Buffs = function()
            for i = 1, #config.buffsPipeline do
                local node = config.buffsPipeline[i]
                
                -- Если для баффа заданы внешние условия (например, проверка фокуса для Focus Magic)
                local extraCond = true
                if node.extraCond and not node.extraCond() then
                    extraCond = false
                end
                
                if extraCond then
                    -- Дергаем нашего универсального робота проверки баффов
                    if VRT.CheckBuffAndSend(node.unit, node.check, node.action, node.onlyMyCast) then
                        return true
                    end
                end
            end
            return false
        end
    -- Запасной вариант, если кто-то захочет написать баффы старой кастомной функцией
    elseif config.buffs then
        instance.Buffs = config.buffs
    end

    -- Регистрируем готовый инстанс в ядре аддона
    VRT.Rotations[config.name] = instance
end