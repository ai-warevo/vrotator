VRT = VRT or {}

---
-- @private Hardware Bind Resolver
-- @param barPrefix string The native UI frame prefix (e.g., "MultiBarBottomLeftButton").
-- @param index number The action button slot index (1 to 12).
-- @return string The mapped hardware keybind string (e.g., "ALT-CTRL-1") or "NOT_BOUND".
-- @desc Translates the internal WoW action slot command strings into physical hardware keys.
---
local function GetKeyBindingForButton(barPrefix, index)
    local bindPrefixes = {
        ["ActionButton"]              = "ACTIONBUTTON",
        ["MultiBarBottomLeftButton"]  = "MULTIACTIONBAR1BUTTON",
        ["MultiBarBottomRightButton"] = "MULTIACTIONBAR2BUTTON",
        ["MultiBarRightButton"]       = "MULTIACTIONBAR3BUTTON",
        ["MultiBarLeftButton"]        = "MULTIACTIONBAR4BUTTON",
    }
    
    local internalPrefix = bindPrefixes[barPrefix]
    if not internalPrefix then return "NOT_BOUND" end
    
    local key1, key2 = GetBindingKey(internalPrefix .. index)
    return key1 or key2 or "NOT_BOUND"
end

---
-- @private Macro Sub-Engine Parser
-- @param macroBody string The raw multi-line macro text extracted from the client.
-- @return any number (Spell ID), string (prefixed item/macro name), or nil if fallback occurs.
-- @return boolean true if the matched key represents a valid inventory equipment slot.
-- @desc Parses raw macro strings using a declarative short-circuit strategy pipeline.
--       Extracts either global Spell IDs or uniquely prefixed inventory equipment slots.
---
local function ParseMacroBody(macroBody)
    if not macroBody then return nil, false end

    -- Declarative Routing Table: Priority order for string pattern matching
    local matchers = {
        { pattern = "/[Cc][Aa][Ss][Tt]%s+([^\n]+)",      type = "spell" },
        { pattern = "/[Зз][Aa][Кк][Лл]%s+([^\n]+)",      type = "spell" },
        { pattern = "/[Uu][Ss][Ee]%s+([^\n]+)",          type = "item"  },
        { pattern = "/[Ии][Сс][Пп][Оо][Лл]%s+([^\n]+)",  type = "item"  }
    }

    for i = 1, #matchers do
        local line = macroBody:match(matchers[i].pattern)
        if line then
            -- Strips conditionals like [mod:ctrl, @cursor] and isolates the target payload
            local cleanTarget = line:gsub("%b[]", ""):match("([^;]+)")
            if cleanTarget then
                cleanTarget = cleanTarget:gsub("^%s*", ""):gsub("%s*$", "")
                
                -- Strategy 1: Node parsed as a hardware /use statement
                if matchers[i].type == "item" then
                    local slotNumber = tonumber(cleanTarget)
                    if slotNumber then
                        return "item:" .. slotNumber, true -- Returns exact factory key format
                    end
                    return cleanTarget, false
                end

                -- Strategy 2: Node parsed as a hardware /cast statement
                local spellLink = GetSpellLink(cleanTarget)
                if spellLink then
                    local parsedID = spellLink:match("spell:(%d+)")
                    if parsedID then 
                        return tonumber(parsedID), false 
                    end
                end
            end
        end
    end

    return nil, false
end

---
-- @public Automation Action Bar Core Scanner
-- @return table Flat database mapping internal identifiers (Spell IDs/Item Strings) to keybinds.
-- @desc Scans all five core native Blizzard action bars frame-by-frame.
--       Deconstructs active slot payloads into unambiguous keys using low-level API mapping.
--       Guarantees cross-language execution safety by relying strictly on numeric identifiers.
---
function VRT.ScanAllSpellBindingsWithIDs()
    local idToKeyMap = {}
    
    local scannerTooltip = CreateFrame("GameTooltip", "PixelBotScannerTooltip", nil, "GameTooltipTemplate")
    scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    
    local barFrames = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
    }
    
    VRT.Log("--- STARTING MULTI-LANGUAGE ID SCANNING ---")
    
    for _, barPrefix in ipairs(barFrames) do
        for i = 1, 12 do
            local buttonFrame = _G[barPrefix .. i]
            
            -- Guard Clause: Instantly skip empty, unregistered, or uninitialized action slots
            if not buttonFrame or not buttonFrame.action then 
                -- Short-circuits loop to next iteration bypassing nesting
            else
                local slotID = buttonFrame.action
                local actionType, id = GetActionInfo(slotID)
                
                if actionType and actionType ~= "" then
                    local bind = GetKeyBindingForButton(barPrefix, i)
                    
                    -- Resolves localized string name via safe invisible tooltip injection
                    scannerTooltip:ClearLines()
                    scannerTooltip:SetAction(slotID)
                    local tooltipTextFrame = _G["PixelBotScannerTooltipTextLeft1"]
                    local localizedName = tooltipTextFrame and tooltipTextFrame:GetText() or "Unknown"
                    
                    ----------------------------------------------------
                    -- DISPATCHER ROTATION: Action Type Routing
                    ----------------------------------------------------
                    
                    -- Handler 1: Standard Active Spells
                    if actionType == "spell" then
                        local spellLink = GetSpellLink(id, BOOKTYPE_SPELL)
                        local realSpellID = spellLink and tonumber(spellLink:match("spell:(%d+)")) or id
                        
                        idToKeyMap[realSpellID] = bind
                        VRT.Log(string.format("[%s #%d] GLOBAL Spell ID: %d ('%s') -> Bind: %s", barPrefix, i, realSpellID, localizedName, bind))
                        
                    -- Handler 2: Consumable / Directly Placed Items
                    elseif actionType == "item" then
                        local itemKey = "item:" .. id
                        idToKeyMap[itemKey] = bind
                        VRT.Log(string.format("[%s #%d] DIRECT ITEM Slot/ID: %s ('%s') -> Bind: %s", barPrefix, i, itemKey, localizedName, bind))
                        
                    -- Handler 3: Scripted Core Macros
                    elseif actionType == "macro" then
                        local macroName = GetMacroInfo(id)
                        if macroName then
                            local finalKey, isItemSlot = ParseMacroBody(GetMacroBody(id))
                            finalKey = finalKey or macroName -- Fallback to string name if parsing fails
                            
                            idToKeyMap[finalKey] = bind
                            
                            -- Performance-tuned logging router
                            if isItemSlot then
                                VRT.Log(string.format("[%s #%d] Macro Item Slot: %s -> Bind: %s", barPrefix, i, tostring(finalKey), bind))
                            elseif type(finalKey) == "number" then
                                local spellName = GetSpellInfo(finalKey) or macroName
                                VRT.Log(string.format("[%s #%d] Macro Spell ID: %d ('%s') -> Bind: %s", barPrefix, i, finalKey, spellName, bind))
                            else
                                VRT.Log(string.format("[%s #%d] Macro Name/Item: '%s' -> Bind: %s", barPrefix, i, tostring(finalKey), bind))
                            end
                        end
                    end
                    ----------------------------------------------------
                end
            end
        end
    end
    
    VRT.Log("--- MULTI-LANGUAGE SCANNING COMPLETED ---")
    return idToKeyMap
end
