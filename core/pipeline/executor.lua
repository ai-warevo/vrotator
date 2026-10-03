VRT = VRT or {}
VRT.Pipeline = VRT.Pipeline or {}
VRT.Pipeline.Executor = VRT.Pipeline.Executor or {}

---
-- @public Pure Logic Buff Maintenance Dispatcher
-- @param unit string Target identifier string reference (e.g., "player", "focus").
-- @param checkBuffs table Data arrays mapping tracking Spell IDs.
-- @param actionSpells table Priority index for action bar mapping keys.
-- @param onlyMyCast boolean Filter flag constraint for strict player aura check.
-- @return boolean true if validation rules pass and a hardware signal is emitted.
---
function VRT.Pipeline.Executor.CheckBuffAndSend(unit, checkBuffs, actionSpells, onlyMyCast)
    local hasAnyBuff = false
    for _, buffID in ipairs(checkBuffs) do
        if VRT.State.HasBuff(unit, buffID, onlyMyCast) then
            hasAnyBuff = true
            break
        end
    end

    if not hasAnyBuff then
        for _, spellID in ipairs(actionSpells) do
            local bind = VRT.MyBinds[spellID]
            if bind then
                VRT.Signal.SendBind(bind)
                return true
            end
        end
    end
    return false
end

---
-- @public Real-time Pipeline Node Processor
-- @param node table The single declarative configuration record target to parse.
-- @return boolean true if node execution parameters match and an output token is pushed.
---
function VRT.Pipeline.Executor.ExecutePipelineNode(node)
    if not (node.cond and not node.cond()) and VRT.Pipeline.Strategies.IsAssetReady(node) then
        local isItemType = (node.type == "item" or node.type == "usable_item")
        local bindKey = isItemType and ("item:" .. node.id) or node.id
        local bind = VRT.MyBinds[bindKey]
        
        if bind then
            VRT.Signal.SendBind(bind)
            return true
        end
    end
    return false
end
