VRT = VRT or {}
local frame = CreateFrame("Frame")

local currentRotation = nil

-- Функция автоматического определения класса и активного спека
local function DetectPlayerSpec()
    local _, classFilename = UnitClass("player")
    local class = classFilename:lower() -- Получаем класс персонажа (например, "mage")
    
    if class == "mage" then
        -- Проверка ключевых талантов спеков Мага в WotLK:
        if IsSpellKnown(12042) then      -- Presence of Mind (Arcane)
            return "mage_arcane"
        elseif IsSpellKnown(55360) then  -- Living Bomb (Fire)
            return "mage_fire"
        elseif IsSpellKnown(44572) then  -- Deep Freeze (Frost)
            return "mage_frost"
        end
    -- Сюда в будущем добавятся блоки для других классов:
    -- elseif class == "warrior" then ...
    end
    
    return nil
end

-- Общий цикл OnUpdate ядра аддона
local function OnUpdate(self, elapsed)
    if UnitIsDeadOrGhost("player")
    or not UnitExists("target")
    or UnitIsDeadOrGhost("target")
    or not UnitAffectingCombat("player")
    or not UnitCanAttack("player", "target")
    or VRT.IsCastingOrChanneling()
    or VRT.IsGCD() then
        VRT.SetSignalColor(0, 0, 0) 
        return
    end

    local actionTaken = false
    if currentRotation then
        actionTaken = currentRotation()
    end

    -- Если ни одно условие в модуле ротации не сработало, тушим пиксель
    if not actionTaken then
        VRT.SetSignalColor(0, 0, 0)
    end
end

-- Обработчик боевых событий
local function OnEvent(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        frame:SetScript("OnUpdate", OnUpdate)
    elseif event == "PLAYER_REGEN_ENABLED" then
        frame:SetScript("OnUpdate", nil)
        VRT.SetSignalColor(0, 0, 0)
    end
end

-- Универсальная переключалка /vrt
local isEnabled = false
SLASH_VROTATOR1 = "/vrt"
SlashCmdList["VROTATOR"] = function()
    isEnabled = not isEnabled
    
    if isEnabled then
        VRT.Log("Initializing universal core...")
        
        -- 1. Определяем спек игрока
        local spec = DetectPlayerSpec()
        if spec == "mage_fire" and VRT.Rotations.MageFire then
            currentRotation = VRT.Rotations.MageFire
            VRT.Log("Detected: Fire Mage. Module loaded.")
        else
            currentRotation = nil
            VRT.Log("Error: Rotation module for your current spec/class not found!")
        end

        -- 2. Кэшируем бинды панелей
        VRT.MyBinds = VRT.ScanAllSpellBindingsWithIDs()
        VRT.Log("Action bars scanned.")

        -- 3. Активируем триггеры боя
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:SetScript("OnEvent", OnEvent)
        
        if UnitAffectingCombat("player") then
            frame:SetScript("OnUpdate", OnUpdate)
        end
        VRT.Log("|cff00ff00ENABLED|r")
    else
        frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
        currentRotation = nil
        if VRT.SetSignalColor then VRT.SetSignalColor(0, 0, 0) end
        VRT.Log("|cffff0000DISABLED|r")
    end
end
