local Spell = VRT.Spells.Mage

VRT.Pipeline.RegisterRotation({
    name      = "MageFrostfire_FFB",
    className = "mage",
    
    isActive  = function() 
        return IsSpellKnown(Spell.IcyVeins) 
    end,
    
    combatPipeline  = {
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
        },
        {
            id   = Spell.FrostfireBolt ,
            cond = nil
        }
    },
    
    buffsPipeline = {
        {
            unit       = "player",
            check      = {Spell.MoltenArmor},
            action     = {Spell.MoltenArmor},
            onlyMyCast = false,
            extraCond  = nil
        },
        {
            unit       = "player",
            check      = {Spell.ArcaneIntellect, Spell.ArcaneBrilliance, Spell.DalaranIntellect, Spell.DalaranBrilliance},
            action     = {Spell.ArcaneIntellect, Spell.ArcaneBrilliance, Spell.DalaranIntellect, Spell.DalaranBrilliance},
            onlyMyCast = false,
            extraCond  = nil
        }
    }
})
