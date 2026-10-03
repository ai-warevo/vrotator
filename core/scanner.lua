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
                        
                    elseif actionType == "macro" then
                        local macroName = GetMacroInfo(id)
                        if macroName then
                            local macroBody = GetMacroBody(id)
                            local macroSpellID = nil
                            local localizedName = macroName -- дефолтное имя, если спелл не найдется
                            
                            if macroBody then
                                -- 1. Парсим строку /cast или /закл (игнорируя регистр)
                                local castLine = macroBody:match("/[Cc][Aa][Ss][Tt]%s+([^\n]+)")
                                or macroBody:match("/use%s+([^\n]+)")
                                or macroBody:match("/[Зз][Aa][Кк][Лл]%s+([^\n]+)")
                                
                                if castLine then
                                    -- 2. Очищаем условия в квадратных скобках вроде [mod:ctrl, harm] или [@cursor]
                                    -- Убираем всё, что находится внутри [], вместе со скобками
                                    local cleanCast = castLine:gsub("%b[]", "")
                                    
                                    -- 3. Если макрос сложный (через точку с запятой Spell1; Spell2), берем первое заклинание
                                    cleanCast = cleanCast:match("([^;]+)")
                                    
                                    if cleanCast then
                                        -- Удаляем лишние пробелы в начале и конце названия спелла
                                        cleanCast = cleanCast:gsub("^%s*", ""):gsub("%s*$", "")
                                        
                                        -- 4. Пытаемся получить глобальный Spell ID по чистому имени заклинания
                                        local spellLink = GetSpellLink(cleanCast)
                                        if spellLink then
                                            local parsedID = spellLink:match("spell:(%d+)")
                                            if parsedID then 
                                                macroSpellID = tonumber(parsedID)
                                                -- Заменяем имя макроса на реальное название спелла для логов
                                                localizedName = GetSpellInfo(macroSpellID) or localizedName
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- Если нашли Spell ID внутри макроса, пишем под числовым ключом. 
                            -- Если нет (например, макрос на юз тринкета/предмета) — оставляем имя макроса.
                            local finalKey = macroSpellID or macroName
                            idToKeyMap[finalKey] = bind
                            
                            if macroSpellID then
                                VRT.Log(string.format("[%s #%d] Macro Spell ID: %d ('%s') -> Bind: %s", barPrefix, i, macroSpellID, localizedName, bind))
                            else
                                VRT.Log(string.format("[%s #%d] Macro Name: '%s' -> Bind: %s", barPrefix, i, macroName, bind))
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