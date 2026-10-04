VRT = VRT or {}
VRT.Pipeline = VRT.Pipeline or {}

local Executor = VRT.Pipeline.Executor

---
-- @private Combat Compilation Engine
-- @param pipeline table Array list of sequential battle prioritizations.
-- @return function Isolated runtime matrix execution block.
---
local function BuildCombatRunner(pipeline)
    return function()
        for i = 1, #pipeline do
            if Executor.ExecutePipelineNode(pipeline[i]) then 
                return true 
            end
        end
        return false
    end
end

---
-- @private Buff Compilation Engine
-- @param pipeline table Array list of out-of-combat maintenance states.
-- @return function Isolated runtime matrix execution block.
---
local function BuildBuffsRunner(pipeline)
    return function()
        for i = 1, #pipeline do
            local node = pipeline[i]
            local extraCond = not node.extraCond or node.extraCond()
            
            if extraCond and Executor.CheckBuffAndSend(node.unit, node.check, node.action, node.onlyMyCast) then
                return true
            end
        end
        return false
    end
end

---
-- @public Architectural Pipeline Registration Interface
-- @param config table Pure declarative rotation schema setup configuration.
-- @desc Compiles explicit linear execution loops out of abstract node blocks.
---
function VRT.Pipeline.RegisterRotation(config)
    if not config.name then return end

    local instance = {
        className = config.className,
        IsActive  = config.isActive
    }

    if config.combatPipeline then
        instance.Combat = BuildCombatRunner(config.combatPipeline)
    end

    if config.buffsPipeline then
        instance.Buffs = BuildBuffsRunner(config.buffsPipeline)
    elseif config.buffs then
        instance.Buffs = config.buffs
    end

    VRT.Rotations[config.name] = instance
end

---
-- @public Zero-Overhead Pipeline Compiler Matrix
-- @param ... table List of sequential arrays to merge into a single flat execution pipeline.
-- @return table Combined flat array ready for executor consumption.
---
function VRT.Pipeline.Merge(...)
    local compiledPipeline = {}
    local subPipelines = {...}
    
    for i = 1, #subPipelines do
        local currentSub = subPipelines[i]
        if currentSub then
            for j = 1, #currentSub do
                table.insert(compiledPipeline, currentSub[j])
            end
        end
    end
    
    return compiledPipeline
end
