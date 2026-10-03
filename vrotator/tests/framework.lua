VRT = VRT or {}
VRT.Tests = VRT.Tests or {}
VRT.Tests.Suites = {}

local logPrefix = "|cff00ffff[vrt-test]|r "

---
-- @public Test Suite Case Registration Interface
-- @param name string Unique human-readable identifier for the test case.
-- @param func function Anonymous block executing assertions.
---
function VRT.Tests.RegisterTestCase(name, func)
    table.insert(VRT.Tests.Suites, { name = name, run = func })
end

---
-- @public Deterministic Assertion Evaluator
-- @param condition boolean Expression condition state result to validate.
-- @param message string Error trace description injected upon failure states.
---
function VRT.Tests.Assert(condition, message)
    if not condition then
        error(message or "Assertion condition failed validation constraints.")
    end
end

---
-- @public Master Test Harness Execution Engine
---
function VRT.Tests.RunAll()
    DEFAULT_CHAT_FRAME:AddMessage("==============================================")
    DEFAULT_CHAT_FRAME:AddMessage(logPrefix .. "LAUNCHING LUA SIMULATION SUITE...")
    DEFAULT_CHAT_FRAME:AddMessage("==============================================")

    local passedCount = 0
    local failedCount = 0

    for i = 1, #VRT.Tests.Suites do
        local test = VRT.Tests.Suites[i]
        
        -- Isolate environmental conditions before executing each target vector
        if VRT.Tests.SetupMocks then VRT.Tests.SetupMocks() end

        -- Execute the routine via a protected call context to avoid fracturing UI threads
        local success, err = pcall(test.run)

        if success then
            passedCount = passedCount + 1
            DEFAULT_CHAT_FRAME:AddMessage(logPrefix .. "|cff00ff00[PASSED]|r " .. test.name)
        else
            failedCount = failedCount + 1
            DEFAULT_CHAT_FRAME:AddMessage(logPrefix .. "|cffff0000[FAILED]|r " .. test.name)
            DEFAULT_CHAT_FRAME:AddMessage("          ➔ |cffffaa00Trace Error:|r " .. tostring(err))
        end
        
        -- Safely tear down memory contexts post execution
        if VRT.Tests.TeardownMocks then VRT.Tests.TeardownMocks() end
    end

    DEFAULT_CHAT_FRAME:AddMessage("==============================================")
    DEFAULT_CHAT_FRAME:AddMessage(string.format("%sSUMMARY: Passed: |cff00ff00%d|r | Failed: %s%d|r", 
        logPrefix, passedCount, (failedCount > 0 and "|cffff0000" or "|cff00ff00"), failedCount))
    DEFAULT_CHAT_FRAME:AddMessage("==============================================")
end
