VRT = VRT or {}
local frame = CreateFrame("Frame")

local function OnUpdate(self, elapsed)
    if not UnitExists("target")
    or UnitIsDeadOrGhost("player")
    or UnitIsDeadOrGhost("target")
    or not UnitCanAttack("player", "target")
    or VRT.IsCastingOrChanneling()
    or VRT.IsGCD() then
        VRT.SetSignalColor(0, 0, 0) 
        return
    end

    local actionTaken = false
    if VRT.CurrentRotation.Combat then
        actionTaken = VRT.CurrentRotation.Combat()
    end

    if not actionTaken then
        VRT.SetSignalColor(0, 0, 0)
    end
end

local function OnEvent(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        frame:SetScript("OnUpdate", OnUpdate)
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        frame:SetScript("OnUpdate", nil)
        VRT.SetSignalColor(0, 0, 0)
        
    elseif event == "UNIT_AURA" or event == "PLAYER_ALIVE" then
        if not UnitAffectingCombat("player") and VRT.CurrentRotation.Buffs then
            VRT.CurrentRotation.Buffs()
        end
    end
end

local isEnabled = false
SLASH_VROTATOR1 = "/vrt"
SlashCmdList["VROTATOR"] = function()
    isEnabled = not isEnabled
    
    if isEnabled then
        VRT.Log("Initializing universal core...")
        VRT.MyBinds = VRT.ScanAllSpellBindingsWithIDs()
        VRT.Log("Action bars scanned.")

        local spec = VRT.DetectPlayerSpec()
        if spec then
            VRT.Log("Detected spec: " .. spec .. ". Module linked successfully.")
        else
            VRT.Log("Error: Configuration for your current talent build not found!")
            isEnabled = false
            return
        end

        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("UNIT_AURA")
        frame:RegisterEvent("PLAYER_ALIVE")
        frame:SetScript("OnEvent", OnEvent)
        
        if UnitAffectingCombat("player") then
            frame:SetScript("OnUpdate", OnUpdate)
        else
            if VRT.CurrentRotation.Buffs then VRT.CurrentRotation.Buffs() end
        end
        VRT.Log("|cff00ff00ENABLED|r")
    else
        frame:UnregisterAllEvents()
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
        VRT.CurrentRotation.Combat = nil
        VRT.CurrentRotation.Buffs = nil
        if VRT.SetSignalColor then
            VRT.SetSignalColor(0, 0, 0)
        end
        VRT.Log("|cffff0000DISABLED|r")
    end
end
