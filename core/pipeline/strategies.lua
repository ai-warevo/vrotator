VRT = VRT or {}
VRT.Pipeline = VRT.Pipeline or {}
VRT.Pipeline.Strategies = VRT.Pipeline.Strategies or {}

local Strategies = VRT.Pipeline.Strategies

-- Strategy 1: Equipped Gear Inventory Slots (e.g., 10, 13, 14)
Strategies["item"] = function(nodeID)
    local itemLink = GetInventoryItemLink("player", nodeID)
    if not itemLink or not GetItemSpell(itemLink) then return false end

    local start, duration = GetInventoryItemCooldown("player", nodeID)
    return (start == 0 and duration == 0)
end

-- Strategy 2: Consumable Baggage Assets (e.g., Mana Gem, Pots)
Strategies["usable_item"] = function(nodeID)
    if GetItemCount(nodeID) == 0 then return false end
    
    local start, duration = GetItemCooldown(nodeID)
    return (start == 0 and duration == 0)
end

-- Strategy 3: Native Magic Spells (Standard Fallback)
Strategies["spell"] = function(nodeID)
    return VRT.State.IsSpellReady(nodeID)
end

---
-- @public Strategy Router Interface
-- @param node table The pipeline target item being validated.
-- @return boolean true if the evaluated hardware asset is off cooldown.
---
function VRT.Pipeline.Strategies.IsAssetReady(node)
    local strategyKey = node.type or "spell"
    return Strategies[strategyKey](node.id)
end
