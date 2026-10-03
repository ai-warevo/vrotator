VRT = VRT or {}
VRT.Tests = VRT.Tests or {}

local originalGetSpellCooldown = GetSpellCooldown
local originalUnitBuff = UnitBuff
local originalUnitCastingInfo = UnitCastingInfo
local originalUnitChannelInfo = UnitChannelInfo
local originalGetItemInfo = GetItemInfo

-- In-memory state tracking matrix tables
VRT.Tests.MockData = {
    cooldowns = {},
    buffs = {},
    casting = nil,
    channeling = nil,
    items = {}
}

function VRT.Tests.SetupMocks()
    -- Initialize fresh isolated memory containers
    VRT.Tests.MockData.cooldowns = {}
    VRT.Tests.MockData.buffs = {}
    VRT.Tests.MockData.casting = nil
    VRT.Tests.MockData.channeling = nil
    VRT.Tests.MockData.items = {}

    -- Inject mocked GetSpellCooldown routine overrides
    GetSpellCooldown = function(spellID)
        local mock = VRT.Tests.MockData.cooldowns[spellID]
        if mock then return mock.start, mock.duration end
        return 0, 0
    end

    -- Inject mocked UnitBuff scanner routing table overrides
    UnitBuff = function(unit, index)
        local mockList = VRT.Tests.MockData.buffs[unit]
        if mockList and mockList[index] then
            local b = mockList[index]
            return b.name, nil, nil, nil, nil, nil, nil, b.caster, nil, nil, b.id
        end
        return nil
    end

    -- Inject mocked UnitCastingInfo status indicator hooks
    UnitCastingInfo = function(unit)
        local mock = VRT.Tests.MockData.casting
        if mock then return mock.name, nil, nil, nil, mock.endTime end
        return nil
    end

    -- Inject mocked UnitChannelInfo status indicator hooks
    UnitChannelInfo = function(unit)
        local mock = VRT.Tests.MockData.channeling
        if mock then return mock.name, nil, nil, nil, mock.endTime end
        return nil
    end

    -- Inject mocked GetItemInfo database async resolution buffers
    GetItemInfo = function(itemNameOrID)
        local mock = VRT.Tests.MockData.items[itemNameOrID]
        if mock then return mock.name, mock.link end
        return nil, nil
    end
end

function VRT.Tests.TeardownMocks()
    -- Fully re-link native core pointer addresses back to primary Blizzard API
    GetSpellCooldown = originalGetSpellCooldown
    UnitBuff = originalUnitBuff
    UnitCastingInfo = originalUnitCastingInfo
    UnitChannelInfo = originalUnitChannelInfo
    GetItemInfo = originalGetItemInfo
end
