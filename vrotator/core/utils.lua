VRT = VRT or {}
VRT.Utils = VRT.Utils or {}

---
-- @public System Wrapper Client Output Log
-- @param text string Safe clean logging payload to print.
---
function VRT.Utils.Log(text)
    if VRT.DebugMode then
        print("|cff00ffff[vrotator]|r " .. text)
    end
end

---
-- @public Dynamic Runtime Class Evaluator
-- @return string Resolved spec tracking naming key registered within the framework index mapping.
---
function VRT.Utils.DetectPlayerSpec()
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
