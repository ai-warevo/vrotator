local Spell = VRT.Spells.Mage

local FireFFBCoreCombat = {
    {
        id   = Spell.Pyroblast,
        cond = function() 
            return VRT.State.HasBuff("player", Spell.HotStreakProc) 
        end
    },
    {
        id   = Spell.LivingBomb,
        cond = function() 
            return IsSpellKnown(Spell.LivingBomb) 
                and not VRT.State.HasDebuff("target", Spell.LivingBomb, true) 
        end
    },
    VRT.Spells.Mage.Movement.FireBlast,
    VRT.Spells.Mage.Movement.IceLance,
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
    },
    {
        id   = Spell.IcyVeins,
        cond = nil
    },
    {
        id   = Spell.ColdSnap,
        cond = function()
            if not IsSpellKnown(Spell.ColdSnap) then return false end
            
            local start, duration = GetSpellCooldown(Spell.IcyVeins)
            return (start > 0 and duration > 0)
        end
    }
}

local FireFFBBaseFiller = {
    {
        id   = Spell.FrostfireBolt,
        cond = nil
    }
}

VRT.Pipeline.RegisterRotation({
    name      = "MageFire_FFB",
    className = "mage",
    
    isActive  = function() 
        return IsSpellKnown(Spell.IcyVeins) 
    end,

    combatPipeline = VRT.Pipeline.Merge(
        VRT.Spells.CommonBurst,
        FireFFBCoreCombat,
        VRT.Spells.Mage.Recovery,
        FireFFBBaseFiller
    ),
    
    buffsPipeline = VRT.Pipeline.Merge(
        VRT.Spells.Mage.CommonBuffs
    )
})
