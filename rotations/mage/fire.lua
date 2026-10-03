VRT = VRT or {}
VRT.Rotations = VRT.Rotations or {}
VRT.Rotations.MageFire = {}
VRT.Rotations.MageFire.className = "mage"

local MageFire = VRT.Rotations.MageFire
local Spell = VRT.Spells.Mage

local CombatPipeline = {
    { id = Spell.Pyroblast, cond = function() return VRT.HasBuff("player", Spell.HotStreakProc) end },
    { id = Spell.ScorchSpell, cond = function() return not VRT.HasDebuff("target", Spell.ShadowMastery) and not VRT.HasDebuff("target", Spell.ScorchDebuff) end },
    { id = Spell.LivingBomb, cond = function() return IsSpellKnown(Spell.LivingBomb) and not VRT.HasDebuff("target", Spell.LivingBomb, true) end },
    { id = Spell.MirrorImage, cond = nil },
    { id = Spell.Combustion, cond = nil },
    { id = Spell.Fireball, cond = nil }
}

local function ProcessSpell(spellID, conditionFunc)
    if (conditionFunc and not conditionFunc()) or not VRT.IsSpellReady(spellID) then return false end
    local bind = VRT.MyBinds[spellID]
    if bind then VRT.SendBindSignal(bind) return true end
    return false
end

function MageFire.IsActive()
    return IsSpellKnown(Spell.LivingBomb) or false
end

function MageFire.Buffs()
    if VRT.CheckBuffAndSend("player", {Spell.MoltenArmor}, {Spell.MoltenArmor}) then return true end

    local intellects = {Spell.ArcaneIntellect, Spell.ArcaneBrilliance, Spell.DalaranIntellect, Spell.DalaranBrilliance}
    if VRT.CheckBuffAndSend("player", intellects, intellects) then return true end

    if VRT.IsSpellReady(Spell.FocusMagic) and UnitExists("focus") and not UnitIsDeadOrGhost("focus") and UnitIsFriend("player", "focus") then
        if VRT.CheckBuffAndSend("focus", {Spell.FocusMagic}, {Spell.FocusMagic}, true) then return true end
    end
    return false
end

function MageFire.Combat()
    for i = 1, #CombatPipeline do
        local node = CombatPipeline[i]
        if ProcessSpell(node.id, node.cond) then return true end
    end
    return false
end
