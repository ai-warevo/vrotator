VRT = VRT or {}
VRT.Rotations = VRT.Rotations or {}

-- Функция принимает кэш биндов (myBinds) из ядра
function VRT.Rotations.MageFire(myBinds)
    -- 1. Селф-баффы (Доспех и Интеллект)
    if not VRT.HasBuff("player", 43046) then -- Molten Armor
        local bind = myBinds[43046]
        if bind then VRT.SendBindSignal(bind) return true end
    elseif not VRT.HasBuff("player", 42995) then -- Arcane Intellect
        local bind = myBinds[42995]
        if bind then VRT.SendBindSignal(bind) return true end
    end

    -- 2. Бафф союзника (Focus Magic)
    if VRT.IsSpellReady(54646) and UnitExists("focus") and not UnitIsDeadOrGhost("focus") and UnitIsFriend("player", "focus") then
        -- Проверяем наличие твоего баффа Focus Magic (ID 54646) строго на цели в фокусе
        local hasFM = false
        for j = 1, 40 do
            local name, _, _, _, _, _, bCaster, _, id = UnitBuff("focus", j)
            if not name then break end
            
            if id == 54646 and bCaster == "player" then 
                hasFM = true 
                break 
            end
        end

        -- Если баффа от тебя на фокусе нет — достаем бинд из мапы
        if not hasFM then
            -- Ищем бинд по имени твоего макроса или спелла на панели
            local bind = myBinds[54646] or myBinds["Focus Magic"] or myBinds["FocusMagic"]
            if bind then 
                VRT.Log("Focus Magic missing on FOCUS. Sending bind: " .. tostring(bind))
                VRT.SendBindSignal(bind) 
                return true 
            end
        end
    end

    ----------------------------------------------------
    -- Основная ротация
    ----------------------------------------------------
    if UnitAffectingCombat("player") and UnitExists("target") and not UnitIsDeadOrGhost("target") and UnitCanAttack("player", "target") then
        
        -- 1. Бурсты с пула по КД
        if VRT.IsSpellReady(55342) then -- Mirror Image
            local bind = myBinds[55342]
            if bind then VRT.SendBindSignal(bind) return true end
        elseif VRT.IsSpellReady(11129) then -- Combustion
            local bind = myBinds[11129]
            if bind then VRT.SendBindSignal(bind) return true end
        end

        -- 2. Прок Hot Streak -> Мгновенный Pyroblast
        if VRT.HasBuff("player", 48108) then -- Hot Streak прок
            local bind = myBinds[42891] -- Pyroblast
            if bind then VRT.SendBindSignal(bind) return true end
        end

        -- 3. Дебафф Improved Scorch. Игнорим, если есть Shadow Mastery
        local hasShadowMastery = VRT.HasDebuff("target", 17800)
        local hasScorch = VRT.HasDebuff("target", 22959)
        if not hasShadowMastery and not hasScorch then
            local bind = myBinds[42859] -- Scorch
            if bind then VRT.SendBindSignal(bind) return true end
        end

        -- 4. Дебафф Living Bomb
        local hasBomb, bombCaster = VRT.HasDebuff("target", 55360)
        if not hasBomb or bombCaster ~= "player" then
            local bind = myBinds[55360] -- Living Bomb
            if bind then VRT.SendBindSignal(bind) return true end
        end

        -- 5. Основной филлер
        local fireballBind = myBinds[42833] -- Fireball
        if fireballBind then 
            VRT.SendBindSignal(fireballBind) 
            return true 
        end
    end

    return false -- Никакое действие не сработало
end
