VRT = VRT or {}
VRT.Tests = VRT.Tests or {}

local originalGetSpellCooldown = GetSpellCooldown
local originalUnitBuff = UnitBuff
local originalUnitCastingInfo = UnitCastingInfo
local originalUnitChannelInfo = UnitChannelInfo
local originalGetItemInfo = GetItemInfo
local originalGetSpellLink = GetSpellLink
local originalGetItemCount = GetItemCount

VRT.Tests.MockData = {
    cooldowns = {},
    buffs = {},
    casting = nil,
    channeling = nil,
    items = {}
}

function VRT.Tests.SetupMocks()
    VRT.Tests.MockData.cooldowns = {}
    VRT.Tests.MockData.buffs = {}
    VRT.Tests.MockData.casting = nil
    VRT.Tests.MockData.channeling = nil
    VRT.Tests.MockData.items = {}

    -- Mock GetSpellCooldown
    GetSpellCooldown = function(spellID)
        local mock = VRT.Tests.MockData.cooldowns[spellID]
        if mock then return mock.start, mock.duration end
        return 0, 0
    end

    -- Mock UnitBuff
    UnitBuff = function(unit, index)
        local mockList = VRT.Tests.MockData.buffs[unit]
        if mockList and mockList[index] then
            local b = mockList[index]
            return b.name, nil, nil, nil, nil, nil, nil, b.caster, nil, nil, b.id
        end
        return nil
    end

    -- Mock UnitCastingInfo
    UnitCastingInfo = function(unit)
        local mock = VRT.Tests.MockData.casting
        if mock then return mock.name, nil, nil, nil, mock.endTime end
        return nil
    end

    -- Mock UnitChannelInfo
    UnitChannelInfo = function(unit)
        local mock = VRT.Tests.MockData.channeling
        if mock then return mock.name, nil, nil, nil, mock.endTime end
        return nil
    end

    -- Intelligent Mock GetItemInfo
    GetItemInfo = function(itemNameOrID)
        -- Hardcoded check for missing cache fallback test
        if itemNameOrID == "Missing Cache Item" then
            return nil, nil
        end

        -- If it's the specific test item or any other fallback string
        if itemNameOrID == "Сапфировый камень маны" or itemNameOrID == "Sapphire Mana Gem" then
            return itemNameOrID, "item:33312:0:0:0:0:0:0:0"
        end

        return nil, nil
    end

    -- Intelligent Mock GetSpellLink
    GetSpellLink = function(spellName)
        -- Return valid spell link layout strictly for spells, not items
        if spellName == "Ледяной доспех" or spellName == "Ice Armor" then
            return "spell:43008"
        end
        return nil
    end

    -- Mock GetItemCount
    GetItemCount = function(itemID)
        return 0
    end
end

function VRT.Tests.TeardownMocks()
    GetSpellCooldown = originalGetSpellCooldown
    UnitBuff = originalUnitBuff
    UnitCastingInfo = originalUnitCastingInfo
    UnitChannelInfo = originalUnitChannelInfo
    GetItemInfo = originalGetItemInfo
    GetSpellLink = originalGetSpellLink
    GetItemCount = originalGetItemCount
end
