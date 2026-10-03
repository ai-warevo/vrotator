VRT = VRT or {}
VRT.Scanner = VRT.Scanner or {}
VRT.Scanner.Parser = {}

--- @immutable Table of matchers for declarative macro deconstruction
local MacroMatchers = {
    -- English standard layouts
    { pattern = "/cast%s+([^\n]+)",      type = "spell" },
    { pattern = "/CAST%s+([^\n]+)",      type = "spell" },
    { pattern = "/use%s+([^\n]+)",       type = "item"  },
    { pattern = "/USE%s+([^\n]+)",       type = "item"  },
    
    -- Russian localized layouts (Explicit flat strings to bypass Lua 5.1 multi-byte regex limitations)
    { pattern = "/закл%s+([^\n]+)", type = "spell" },
    { pattern = "/ЗАКЛ%s+([^\n]+)", type = "spell" },
    { pattern = "/исп%s+([^\n]+)",      type = "item"  },
    { pattern = "/ИСП%s+([^\n]+)",      type = "item"  }
}

---
-- @public Target Stripper
-- @param rawLine string Single line of macro command execution
-- @return string Cleaned string target name stripped of bracket conditionals
---
function VRT.Scanner.Parser.SanitizeTarget(rawLine)
    local clean = rawLine:gsub("%b[]", ""):match("([^;]+)")
    return clean and clean:gsub("^%s*", ""):gsub("%s*$", "") or nil
end

---
-- @public Macro Deconstructor
-- @param macroBody string Raw multi-line macro text block
-- @return any number (Spell ID), string (Prefixed item storage key), or nil
-- @return boolean Flag verifying if the returned token represents an inventory slot
---
function VRT.Scanner.Parser.ParseMacro(macroBody)
    if not macroBody then return nil, false end

    for i = 1, #MacroMatchers do
        local matchedLine = macroBody:match(MacroMatchers[i].pattern)
        if matchedLine then
            local cleanTarget = VRT.Scanner.Parser.SanitizeTarget(matchedLine)
            
            if cleanTarget then
                if MacroMatchers[i].type == "item" then
                    local slotNumber = tonumber(cleanTarget)
                    if slotNumber then return "item:" .. slotNumber, true end
                    
                    local itemIDFromLink = cleanTarget:match("item:(%d+)")
                    if itemIDFromLink then 
                        return "item:" .. itemIDFromLink, false 
                    end
                    
                    local _, itemLink = GetItemInfo(cleanTarget)
                    if itemLink then
                        local parsedItemID = itemLink:match("item:(%d+)")
                        if parsedItemID then 
                            return "item:" .. parsedItemID, false 
                        end
                    end

                    return cleanTarget, false
                end

                local spellLink = GetSpellLink(cleanTarget)
                if spellLink then
                    local parsedID = spellLink:match("spell:(%d+)")
                    if parsedID then return tonumber(parsedID), false end
                end
            end
        end
    end
    return nil, false
end
