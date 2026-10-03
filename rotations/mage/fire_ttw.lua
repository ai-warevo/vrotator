local Spell = VRT.Spells.Mage

VRT.Pipeline.RegisterRotation({
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
        },
        { 
            id   = Spell.ManaGemItem, 
            type = "usable_item",
            cond = function() 
                local currentMana = UnitMana("player")
                local maxMana = UnitManaMax("player")
                
                return (maxMana - currentMana) >= 5000
            end 
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
            unit       = "player",
            check      = {},
            action     = {Spell.ConjureManaGem},
            onlyMyCast = false,
            extraCond  = function()
                local charges = GetItemCount(Spell.ManaGemItem, nil, true) or 0
                
                return charges < 3 
                       and not UnitAffectingCombat("player") 
                       and VRT.State.IsSpellReady(Spell.ConjureManaGem)
            end
        },
        {
            unit       = "focus",
            check      = {Spell.FocusMagic},
            action     = {Spell.FocusMagic},
            onlyMyCast = true,
            extraCond  = function()
                return VRT.State.IsSpellReady(Spell.FocusMagic) 
                       and UnitExists("focus") 
                       and not UnitIsDeadOrGhost("focus") 
                       and UnitIsFriend("player", "focus")
            end
        }
    }
})
