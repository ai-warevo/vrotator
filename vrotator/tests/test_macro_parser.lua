VRT = VRT or {}

-- Vector 1: Standard Cyrillic Cast
VRT.Tests.RegisterTestCase("Macro Parser: Cyrillic Command Extraction", function()
    local res, isSlot = VRT.Scanner.Parser.ParseMacro("/заклинание Ледяной доспех")
    VRT.Tests.Assert(res ~= nil, "Failed to resolve explicit Cyrillic localization prefix matchers.")
    VRT.Tests.Assert(isSlot == false, "Spell mistakenly cataloged under physical equipment slots.")
end)

-- Vector 2: Cyrillic Item Use
VRT.Tests.RegisterTestCase("Macro Parser: Cyrillic Item Use Extraction", function()
    local res, isSlot = VRT.Scanner.Parser.ParseMacro("/испол Сапфировый камень маны")
    VRT.Tests.Assert(res ~= nil, "Failed to resolve explicit Cyrillic item localization prefix matchers.")
    VRT.Tests.Assert(isSlot == false, "Item name string should not be evaluated as a raw hardware slot.")
end)

-- Vector 3: Bracket Stripping
VRT.Tests.RegisterTestCase("Macro Parser: Bracket Condition Stripping", function()
    local res, isSlot = VRT.Scanner.Parser.ParseMacro("/use [target=focus, harm] item:33312")
    VRT.Tests.Assert(res == "item:33312", "Conditional array token parsing mismatch. Expected item:33312, got: " .. tostring(res))
    VRT.Tests.Assert(isSlot == false, "Explicit dictionary ID mapping string interpreted as raw action bar slot index.")
end)

-- Vector 4: Hardware Engineering Slots
VRT.Tests.RegisterTestCase("Macro Parser: Physical Slot Hardware Binding", function()
    local res, isSlot = VRT.Scanner.Parser.ParseMacro("/use 10") -- Hyperspeed Accelerators (Gloves)
    VRT.Tests.Assert(res == "item:10", "Hardware numeric slot parsing failed. Expected item:10, got: " .. tostring(res))
    VRT.Tests.Assert(isSlot == true, "Physical bar slot index mapping flag must evaluate to true.")
end)

-- Vector 5: Async Missing Cache Fallback
VRT.Tests.RegisterTestCase("Macro Parser: Asynchronous Item Lookup Fallback", function()
    VRT.Tests.MockData.items["Sapphire Mana Gem"] = nil
    
    local res, isSlot = VRT.Scanner.Parser.ParseMacro("/use Sapphire Mana Gem")
    VRT.Tests.Assert(res == "Sapphire Mana Gem", "Non-blocking cache isolation dropped. Fallback naming string required on zero-state lookups.")
end)
