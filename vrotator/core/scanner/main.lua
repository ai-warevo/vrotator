VRT = VRT or {}
VRT.Scanner = VRT.Scanner or {}
VRT.Scanner.Tooltip = VRT.Scanner.Tooltip or {}

---
-- @public Action Bar Scanning Orchestrator
-- @return table Flattened global database structure ready for VRT.MyBinds ingestion.
-- @desc Runs pure flat matrix iterations. Eliminates nested procedural execution 
--       by routing active payloads to corresponding declarative Strategy blocks.
---
function VRT.Scanner.GetAllSpellBindingsWithIDs()
    local idToKeyMap = {}
    local barOffsets = {
        ["ActionButton"]              = 0,
        ["MultiBarBottomLeftButton"]  = 60,
        ["MultiBarBottomRightButton"] = 48,
        ["MultiBarRightButton"]       = 24,
        ["MultiBarLeftButton"]        = 36,
    }
    local barFrames = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
    }
    
    VRT.Utils.Log("--- STARTING DECOUPLED MATRIX SCANNING ---")
    
    for _, barPrefix in ipairs(barFrames) do
        local offset = barOffsets[barPrefix]
        
        for i = 1, 12 do
            local slotID = offset + i
            local actionType, id = GetActionInfo(slotID)
            
            if actionType and actionType ~= "" and VRT.Scanner.Strategies[actionType] then
                local bind = VRT.Scanner.ResolveKeyBind(barPrefix, i)
                local localizedName = VRT.Scanner.Tooltip.ResolveLocalizedName(slotID)
                
                local mapKey, mapBind = VRT.Scanner.Strategies[actionType](id, bind, barPrefix, i, localizedName)
                
                if mapKey and mapBind then
                    idToKeyMap[mapKey] = mapBind
                end
            end
        end
    end
    
    VRT.Utils.Log("--- MATRIX SCANNING ARCHITECTURE COMPLETED ---")
    return idToKeyMap
end
