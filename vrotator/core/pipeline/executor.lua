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
    if node.cond and not node.cond() then
        return false
    end

    if not VRT.Pipeline.Strategies.IsAssetReady(node) then
        return false
    end

    if VRT.State.IsCastingOrChanneling() then
        local castingName, _, _, _, endTime = UnitCastingInfo("player")
        if castingName then
            local remainingTime = (endTime / 1000) - GetTime()
            if remainingTime > 0.30 then
                return false -- Еще кастуем, до конца далеко
            end
        else
            return false
        end
    elseif VRT.State.IsGCD() then
        return false
    end

    local isItemType = (node.type == "item" or node.type == "usable_item")
    local bindKey = isItemType and ("item:" .. node.id) or node.id
    local bind = VRT.MyBinds[bindKey]
    
    if bind then
        VRT.Signal.SendBind(bind)
        return true
    end

    return false
end
