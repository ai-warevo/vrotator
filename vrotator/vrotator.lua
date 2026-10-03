VRT = VRT or {}
local frame = CreateFrame("Frame")
local buffTimeElapsed = 0
local isEnabled = false

---
-- @lifecycle Out-of-Combat Frame Tick (Throttled Loop)
-- @trigger Hooked via frame:SetScript("OnUpdate", OnUpdateBuffs) when player is not in combat.
-- @param self Frame The frame object executing this script script.
-- @param elapsed number The time delta in seconds since the last rendered frame.
-- @desc Implements a 1.0-second lazy-loaded polling mechanism for buff and inventory tracking.
--       Prevents CPU frame-time spikes in peaceful environments (e.g., Dalaran) by bypassing 60+ FPS ticks.
--       Maintains visual state of the signal pixel until active rotation demands zero-signal.
---
local function OnUpdateBuffs(self, elapsed)
    if VRT.State.IsCastingOrChanneling() or VRT.State.IsGCD() then
        VRT.Signal.SetSignalColor(0, 0, 0)
        return
    end

    buffTimeElapsed = buffTimeElapsed + elapsed
    
    if buffTimeElapsed >= 1.0 then
        buffTimeElapsed = 0
        
        local actionTaken = false
        if not UnitAffectingCombat("player") and VRT.CurrentRotation.Buffs then
            actionTaken = VRT.CurrentRotation.Buffs()
        end
        
        if not actionTaken then
            VRT.Signal.SetSignalColor(0, 0, 0)
        end
    else
        -- ФИКС БЕШЕНОГО СПАМА: Во все остальные 59 кадров секунды (пока таймер копит время)
        -- принудительно гасим пиксель в черный. Это превращает сигнал в короткий одиночный импульс,
        -- давая С++ кликеру команду выполнить ровно ОДИН дискретный клик.
        VRT.Signal.SetSignalColor(0, 0, 0)
    end
end

---
-- @lifecycle In-Combat Frame Tick (High-Frequency Loop)
-- @trigger Hooked via frame:SetScript("OnUpdate", OnUpdate) when player is actively in combat.
-- @param self Frame The frame object executing this script.
-- @param elapsed number The time delta in seconds since the last rendered frame.
-- @desc Real-time execution loop running on every single frame render (60+ Hz).
--       Features a strict performance guard structure that instantly cuts calculations 
--       if the player or target environment states invalidate active spell queuing.
---
local function OnUpdate(self, elapsed)
    if not UnitExists("target")
    or UnitIsDeadOrGhost("player")
    or UnitIsDeadOrGhost("target")
    or not UnitCanAttack("player", "target")
    or VRT.State.IsCastingOrChanneling()
    or VRT.State.IsGCD() then
        VRT.Signal.SetSignalColor(0, 0, 0) 
        return
    end

    local actionTaken = false
    if VRT.CurrentRotation.Combat then
        actionTaken = VRT.CurrentRotation.Combat()
    end

    if not actionTaken then
        VRT.Signal.SetSignalColor(0, 0, 0)
    end
end

---
-- @lifecycle Core Event Listener (State Switcher)
-- @trigger Registered via frame:RegisterEvent and handled by frame:SetScript("OnEvent", OnEvent).
-- @param self Frame The frame context catching the engine event.
-- @param event string The exact Blizzard system event string identifier.
-- @param ... tuple Pack of dynamic event payloads (vararg).
-- @desc Automates context switching between high-frequency combat loops and throttled buff management.
--       Guarantees engine synchronization with local combat state changes.
---
local function OnEvent(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        frame:SetScript("OnUpdate", OnUpdate)
    elseif event == "PLAYER_REGEN_ENABLED" then
        frame:SetScript("OnUpdate", OnUpdateBuffs)
        VRT.Signal.SetSignalColor(0, 0, 0)
    end
end

---
-- @lifecycle Engine Bootstrap Sequence
-- @desc Handles hardware scanning, dynamic module linking, and reactive event attachment.
--       Uses absolute guard clauses to prevent corrupted initialization states.
---
local function StartVrotator()
    VRT.Utils.Log("Initializing universal core...")
    
    VRT.MyBinds = VRT.Scanner.GetAllSpellBindingsWithIDs()
    VRT.Utils.Log("Action bars scanned.")

    local spec = VRT.Utils.DetectPlayerSpec()
    if not spec then
        VRT.Utils.Log("Error: Configuration for your current talent build not found!")
        isEnabled = false
        return
    end
    VRT.Utils.Log("Detected spec: " .. spec .. ". Module linked successfully.")

    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", OnEvent)
    
    local inCombat = UnitAffectingCombat("player")
    local activeLoop = inCombat and OnUpdate or OnUpdateBuffs
    
    frame:SetScript("OnUpdate", activeLoop)
    
    if not inCombat and VRT.CurrentRotation.Buffs then
        VRT.CurrentRotation.Buffs()
    end
    
    VRT.Utils.Log("|cff00ff00ENABLED|r")
end

---
-- @lifecycle Engine Teardown Sequence
-- @desc Safely unhooks structural pointers, destroys event listeners, and flushes output pixels.
--       Prevents memory leaks and floating signals in the UI thread.
---
local function StopVrotator()
    frame:UnregisterAllEvents()
    frame:SetScript("OnEvent", nil)
    frame:SetScript("OnUpdate", nil)
    VRT.CurrentRotation.Combat = nil
    VRT.CurrentRotation.Buffs = nil
    buffTimeElapsed = 0
    if VRT.Signal.SetSignalColor then
        VRT.Signal.SetSignalColor(0, 0, 0)
    end
    VRT.Utils.Log("|cffff0000DISABLED|r")
end

---
-- @lifecycle Client Console Command (Flat Router)
-- @trigger Invoked by typing "/vrt" directly in the client chat box.
---
SLASH_VROTATOR1 = "/vrt"
SlashCmdList["VROTATOR"] = function(msg)
    isEnabled = not isEnabled
    
    local handler = isEnabled and StartVrotator or StopVrotator
    handler()
end
