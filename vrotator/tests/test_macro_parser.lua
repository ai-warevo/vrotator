VRT = VRT or {}

-- Vector 1: Standard Cyrillic Cast
VRT.Tests.RegisterTestCase("Macro Parser: Cyrillic Command Extraction", function()
    -- Matches your exact parser layout pattern: "/закл"
    local res, isSlot = VRT.Scanner.Parser.ParseMacro("/закл Ледяной доспех")
    VRT.Tests.Assert(res == 43008, "Failed to resolve explicit Cyrillic localization prefix matchers. Got: " .. tostring(res))
    VRT.Tests.Assert(isSlot == false, "Spell mistakenly cataloged under physical equipment slots.")
end)

-- Vector 2: Cyrillic Item Use
VRT.Tests.RegisterTestCase("Macro Parser: Cyrillic Item Use Extraction", function()
    -- Matches your exact parser layout pattern: "/исп"
    local res, isSlot = VRT.Scanner.Parser.ParseMacro("/исп Сапфировый камень маны")
    VRT.Tests.Assert(res == "item:33312", "Failed to resolve explicit Cyrillic item localization prefix matchers. Got: " .. tostring(res))
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
    local res, isSlot = VRT.Scanner.Parser.ParseMacro("/use 10")
    VRT.Tests.Assert(res == "item:10", "Hardware numeric slot parsing failed. Expected item:10, got: " .. tostring(res))
    VRT.Tests.Assert(isSlot == true, "Physical bar slot index mapping flag must evaluate to true.")
end)

-- Vector 5: Async Missing Cache Fallback
VRT.Tests.RegisterTestCase("Macro Parser: Asynchronous Item Lookup Fallback", function()
    -- Triggers the explicit "Missing Cache Item" mock block returning nil
    local res, isSlot = VRT.Scanner.Parser.ParseMacro("/use Missing Cache Item")
    VRT.Tests.Assert(res == "Missing Cache Item", "Non-blocking cache isolation dropped. Fallback naming string required on zero-state lookups. Got: " .. tostring(res))
end)
