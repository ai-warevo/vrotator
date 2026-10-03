VRT = VRT or {}

local function GetKeyBindingForButton(barPrefix, index)
    local bindPrefixes = {
        ["ActionButton"] = "ACTIONBUTTON",
        ["MultiBarBottomLeftButton"] = "MULTIACTIONBAR1BUTTON",
        ["MultiBarBottomRightButton"] = "MULTIACTIONBAR2BUTTON",
        ["MultiBarRightButton"] = "MULTIACTIONBAR3BUTTON",
        ["MultiBarLeftButton"] = "MULTIACTIONBAR4BUTTON",
    }
    
    local internalPrefix = bindPrefixes[barPrefix]
    if not internalPrefix then return "NOT_BOUND" end
    
    local internalCommand = internalPrefix .. index
    local key1, key2 = GetBindingKey(internalCommand)
    
    return key1 or key2 or "NOT_BOUND"
end

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
            local buttonName = barPrefix .. i
            local buttonFrame = _G[buttonName]
            
            if buttonFrame and buttonFrame.action then
                local slotID = buttonFrame.action
                local actionType, id = GetActionInfo(slotID)
                
                scannerTooltip:ClearLines()
                scannerTooltip:SetAction(slotID)
                local tooltipTextFrame = _G["PixelBotScannerTooltipTextLeft1"]
                local localizedName = tooltipTextFrame and tooltipTextFrame:GetText() or "Unknown"
                
                if actionType and actionType ~= "" then
                    local bind = GetKeyBindingForButton(barPrefix, i)
                    
                    if actionType == "spell" then
                        local bookIndex = id
                        local realSpellID = nil
                        local spellLink = GetSpellLink(bookIndex, BOOKTYPE_SPELL)
                        
                        if spellLink then
                            local parsedID = spellLink:match("spell:(%d+)")
                            if parsedID then 
                                realSpellID = tonumber(parsedID) 
                            end
                        end
                        
                        realSpellID = realSpellID or bookIndex
                        idToKeyMap[realSpellID] = bind
                        VRT.Log(string.format("[%s #%d] GLOBAL Spell ID: %d ('%s') -> Bind: %s", barPrefix, i, realSpellID, localizedName, bind))
                        
                    elseif actionType == "item" then
                        local itemKey = "item:" .. id
                        idToKeyMap[itemKey] = bind
                        VRT.Log(string.format("[%s #%d] DIRECT ITEM Slot/ID: %s ('%s') -> Bind: %s", barPrefix, i, itemKey, localizedName, bind))

                    elseif actionType == "macro" then
                        local macroName = GetMacroInfo(id)
                        if macroName then
                            local macroBody = GetMacroBody(id)
                            local finalKey = macroName -- дефолтный строковый ключ
                            local isItemSlot = false
                            
                            if macroBody then
                                local castLine = macroBody:match("/[Cc][Aa][Ss][Tt]%s+([^\n]+)")
                                    or macroBody:match("/[Зз][Aa][Кк][Лл]%s+([^\n]+)")
                                local useLine = macroBody:match("/[Uu][Ss][Ee]%s+([^\n]+)")
                                    or macroBody:match("/[Ии][Сс][Пп][Оо][Лл]%s+([^\n]+)")
                                
                                if castLine then
                                    local cleanCast = castLine:gsub("%b[]", ""):match("([^;]+)")
                                    if cleanCast then
                                        cleanCast = cleanCast:gsub("^%s*", ""):gsub("%s*$", "")
                                        local spellLink = GetSpellLink(cleanCast)
                                        if spellLink then
                                            local parsedID = spellLink:match("spell:(%d+)")
                                            if parsedID then finalKey = tonumber(parsedID) end
                                        end
                                    end
                                elseif useLine then
                                    local cleanUse = useLine:gsub("%b[]", ""):match("([^;]+)")
                                    if cleanUse then
                                        cleanUse = cleanUse:gsub("^%s*", ""):gsub("%s*$", "")
                                        local slotNumber = tonumber(cleanUse)
                                        
                                        -- Если это номер слота шмотки (10, 13, 14)
                                        if slotNumber then
                                            finalKey = "item:" .. slotNumber
                                            isItemSlot = true
                                        else
                                            -- Если в /use написано текстовое имя вещи вместо номера слота
                                            finalKey = cleanUse
                                        end
                                    end
                                end
                            end
                            
                            idToKeyMap[finalKey] = bind
                            
                            if isItemSlot then
                                VRT.Log(string.format("[%s #%d] Macro Item Slot: %s -> Bind: %s", barPrefix, i, finalKey, bind))
                            elseif type(finalKey) == "number" then
                                VRT.Log(string.format("[%s #%d] Macro Spell ID: %d ('%s') -> Bind: %s", barPrefix, i, finalKey, localizedName, bind))
                            else
                                VRT.Log(string.format("[%s #%d] Macro Name/Item: '%s' -> Bind: %s", barPrefix, i, tostring(finalKey), bind))
                            end
                        end
                    end
                end
            end
        end
    end
    
    VRT.Log("--- MULTI-LANGUAGE SCANNING COMPLETED ---")
    return idToKeyMap
end
