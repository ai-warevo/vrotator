local Spell = VRT.Spells.Mage

local FireTTWCoreCombat = {
    {
        id   = Spell.Pyroblast,
        cond = function() 
            return VRT.State.HasBuff("player", Spell.HotStreakProc) 
        end
    },
    {
        id   = Spell.LivingBomb,
        cond = function() 
            return not VRT.State.HasDebuff("target", Spell.LivingBomb, true) 
        end
    },
    {
        id   = Spell.ScorchSpell,
        cond = function() 
            return not VRT.State.HasDebuff("target", Spell.ShadowMastery) 
            and not VRT.State.HasDebuff("target", Spell.ScorchDebuff) 
        end
    },
    {
        id   = Spell.MirrorImage,
        cond = nil
    },
    {
        id   = Spell.Combustion,
        cond = nil
    }
}

local FireTTWBaseFiller = {
    {
        id   = Spell.Fireball,
        cond = nil
    }
}

VRT.Pipeline.RegisterRotation({
    name      = "MageFire_TTW",
    className = "mage",
    
    isActive  = function() 
        return IsSpellKnown(Spell.LivingBomb) and not IsSpellKnown(Spell.IcyVeins) 
    end,

    combatPipeline = VRT.Pipeline.Merge(
        VRT.Spells.CommonBurst,
        FireTTWCoreCombat,
        VRT.Spells.Mage.Recovery,
        FireTTWBaseFiller
    ),
    
    buffsPipeline = VRT.Pipeline.Merge(
        VRT.Spells.Mage.CommonBuffs,
        {
            {
                unit       = "focus",
                check      = {Spell.FocusMagic},
                action     = {Spell.FocusMagic},
                onlyMyCast = true,
                extraCond  = function()
                    return VRT.State.IsSpellReady(Spell.FocusMagic) and UnitExists("focus") and not UnitIsDeadOrGhost("focus") and UnitIsFriend("player", "focus")
                end
            }
        }
    )
})
