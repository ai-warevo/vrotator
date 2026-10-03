VRT = VRT or {}
local frame = CreateFrame("Frame")

local buffTimeElapsed = 0

local function OnUpdateBuffs(self, elapsed)
    if VRT.IsCastingOrChanneling() then
        return
    end

    buffTimeElapsed = buffTimeElapsed + elapsed
    
    if buffTimeElapsed >= 1.0 then
        buffTimeElapsed = 0
        
        if not UnitAffectingCombat("player")
            and VRT.CurrentRotation.Buffs then
            VRT.CurrentRotation.Buffs()
        end
    end
end

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
        frame:SetScript("OnUpdate", OnUpdateBuffs)
        VRT.SetSignalColor(0, 0, 0)
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
        frame:SetScript("OnEvent", OnEvent)
        
        if UnitAffectingCombat("player") then
            frame:SetScript("OnUpdate", OnUpdate)
        else
            frame:SetScript("OnUpdate", OnUpdateBuffs)
            if VRT.CurrentRotation.Buffs then
                VRT.CurrentRotation.Buffs()
            end
        end
        VRT.Log("|cff00ff00ENABLED|r")
    else
        frame:UnregisterAllEvents()
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
        VRT.CurrentRotation.Combat = nil
        VRT.CurrentRotation.Buffs = nil
        buffTimeElapsed = 0
        if VRT.SetSignalColor then VRT.SetSignalColor(0, 0, 0) end
        VRT.Log("|cffff0000DISABLED|r")
    end
end
