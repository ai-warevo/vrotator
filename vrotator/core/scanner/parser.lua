VRT = VRT or {}
VRT.Scanner = VRT.Scanner or {}
VRT.Scanner.Parser = {}

--- @immutable Table of matchers for declarative macro deconstruction
local MacroMatchers = {
    { pattern = "/[Cc][Aa][Ss][Tt]%s+([^\n]+)",      type = "spell" },
    { pattern = "/[Зз][Aa][Кк][Лл]%s+([^\n]+)",      type = "spell" },
    { pattern = "/[Uu][Ss][Ee]%s+([^\n]+)",          type = "item"  },
    { pattern = "/[Ии][Сс][Пп][Оо][Лл]%s+([^\n]+)",  type = "item"  }
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
