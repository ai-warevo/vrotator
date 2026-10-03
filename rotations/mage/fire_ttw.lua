local Spell = VRT.Spells.Mage

VRT.RegisterRotation({
    name      = "MageFrostfire_TTW",
    className = "mage",
    
    isActive  = function() 
        return IsSpellKnown(Spell.LivingBomb) and not IsSpellKnown(Spell.IcyVeins) 
    end,
    
    combatPipeline  = {
        { id = 13, type = "item",  cond = nil },
        { id = 14, type = "item",  cond = nil },
        { id = 10, type = "item",  cond = nil },
        {
            id   = Spell.Pyroblast,
            cond = function() 
                return VRT.HasBuff("player", Spell.HotStreakProc) 
            end
        },
        {
            id   = Spell.LivingBomb,
            cond = function() 
                return not VRT.HasDebuff("target", Spell.LivingBomb, true) 
            end
        },
        {
            id   = Spell.ScorchSpell,
            cond = function() 
                return not VRT.HasDebuff("target", Spell.ShadowMastery) 
                and not VRT.HasDebuff("target", Spell.ScorchDebuff) 
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
            id   = Spell.Fireball,
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
        },
        {
            unit       = "focus",
            check      = {Spell.FocusMagic},
            action     = {Spell.FocusMagic},
            onlyMyCast = true,
            extraCond  = function()
                return VRT.IsSpellReady(Spell.FocusMagic) 
                       and UnitExists("focus") 
                       and not UnitIsDeadOrGhost("focus") 
                       and UnitIsFriend("player", "focus")
            end
        }
    }
})
