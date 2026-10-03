VRT = VRT or {}
VRT.Scanner = VRT.Scanner or {}
VRT.Scanner.Strategies = {}

local Strategies = VRT.Scanner.Strategies

-- Strategy 1: Standard Active Spells
Strategies["spell"] = function(id, bind, barPrefix, slotIndex, localizedName)
    local spellLink = GetSpellLink(id, BOOKTYPE_SPELL)
    local realSpellID = spellLink and tonumber(spellLink:match("spell:(%d+)")) or id
    
    VRT.Utils.Log(string.format("[%s #%d] GLOBAL Spell ID: %d ('%s') -> Bind: %s", barPrefix, slotIndex, realSpellID, localizedName, bind))
    return realSpellID, bind
end

-- Strategy 2: Directly Stacked / Consumable Items
Strategies["item"] = function(id, bind, barPrefix, slotIndex, localizedName)
    local itemKey = "item:" .. id
    
    VRT.Utils.Log(string.format("[%s #%d] DIRECT ITEM Slot/ID: %s ('%s') -> Bind: %s", barPrefix, slotIndex, itemKey, localizedName, bind))
    return itemKey, bind
end

-- Strategy 3: Scripted Storage Macros
Strategies["macro"] = function(id, bind, barPrefix, slotIndex, localizedName)
    local macroName = GetMacroInfo(id)
    if not macroName then return nil, nil end
    
    local finalKey, isItemSlot = VRT.Scanner.Parser.ParseMacro(GetMacroBody(id))
    finalKey = finalKey or macroName
    
    if isItemSlot then
        VRT.Utils.Log(string.format("[%s #%d] Macro Item Slot: %s -> Bind: %s", barPrefix, slotIndex, tostring(finalKey), bind))
    elseif type(finalKey) == "number" then
        local spellName = GetSpellInfo(finalKey) or macroName
        VRT.Utils.Log(string.format("[%s #%d] Macro Spell ID: %d ('%s') -> Bind: %s", barPrefix, slotIndex, finalKey, spellName, bind))
    else
        VRT.Utils.Log(string.format("[%s #%d] Macro Name/Item: '%s' -> Bind: %s", barPrefix, slotIndex, tostring(finalKey), bind))
    end
    
    return finalKey, bind
end
