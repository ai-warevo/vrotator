VRT = VRT or {}
VRT.Spells = VRT.Spells or {}
VRT.Spells.Mage = VRT.Spells.Mage or {
    MoltenArmor = 43046,
    ArcaneIntellect = 42995,
    
    ArcaneBrilliance = 43002,
    DalaranIntellect = 61024,
    DalaranBrilliance = 61316,
    
    FocusMagic = 54646,
    
    MirrorImage = 55342,
    Combustion = 11129,
    
    HotStreakProc = 48108,
    Pyroblast = 42891,
    Fireball = 42833,
    FrostfireBolt = 47610,
    FireBlast = 42873,
    IceLance  = 42914,
    
    ScorchSpell = 42859,
    ScorchDebuff = 22959,
    ShadowMastery = 17800,
    
    LivingBomb = 55360,
    IcyVeins = 12472,
    ColdSnap = 11958,

    Evocation = 12051,
    ConjureManaGem = 42985,
    ManaGemItem = 33312,
}

VRT.Spells.Mage.Recovery = VRT.Spells.Mage.Recovery  or {
    { 
        id   = VRT.Spells.Mage.ManaGemItem, 
        type = "usable_item",
        cond = function() 
            local currentMana = UnitMana("player")
            local maxMana = UnitManaMax("player")
            return (maxMana - currentMana) >= 5000
        end 
    },
    {
        id   = VRT.Spells.Mage.Evocation,
        cond = function()
            local Spell = VRT.Spells.Mage
            if not VRT.State.IsSpellReady(Spell.Evocation) then return false end

            local currentMana = UnitMana("player")
            local maxMana = UnitManaMax("player")
            local manaPercent = (currentMana / maxMana) * 100

            if manaPercent <= 10 then return true end

            if manaPercent <= 20 then
                local hasActiveBurst = VRT.State.HasBuff("player", Spell.Combustion)
                    or VRT.State.HasBuff("player", 12472)  -- Icy Veins
                    or VRT.State.HasBuff("player", 2825)   -- Bloodlust
                    or VRT.State.HasBuff("player", 32182)  -- Heroism
                    or VRT.State.HasBuff("player", 54758)  -- Hyperspeed Acceleration
                
                return not hasActiveBurst
            end
            return false
        end
    }
}

VRT.Spells.Mage.Movement = VRT.Spells.Mage.Movement or {}
VRT.Spells.Mage.Movement.FireBlast = VRT.Spells.Mage.Movement.FireBlast or {
    id   = VRT.Spells.Mage.FireBlast,
    cond = function() return VRT.State.IsMoving() end
}

VRT.Spells.Mage.Movement.IceLance = VRT.Spells.Mage.Movement.IceLance or {
    id   = VRT.Spells.Mage.IceLance,
    cond = function() return VRT.State.IsMoving() end
}

VRT.Spells.Mage.CommonBuffs = VRT.Spells.Mage.CommonBuffs or {
    {
        unit       = "player",
        check      = {VRT.Spells.Mage.MoltenArmor},
        action     = {VRT.Spells.Mage.MoltenArmor},
        onlyMyCast = false,
        extraCond  = nil
    },
    {
        unit       = "player",
        check      = {VRT.Spells.Mage.ArcaneIntellect, VRT.Spells.Mage.ArcaneBrilliance, VRT.Spells.Mage.DalaranIntellect, VRT.Spells.Mage.DalaranBrilliance},
        action     = {VRT.Spells.Mage.ArcaneIntellect, VRT.Spells.Mage.ArcaneBrilliance, VRT.Spells.Mage.DalaranIntellect, VRT.Spells.Mage.DalaranBrilliance},
        onlyMyCast = false,
        extraCond  = nil
    },
    {
        unit       = "player",
        check      = {},
        action     = {VRT.Spells.Mage.ConjureManaGem},
        onlyMyCast = false,
        extraCond  = function()
            local charges = GetItemCount(VRT.Spells.Mage.ManaGemItem, nil, true) or 0
            
            return charges < 3 
                   and not UnitAffectingCombat("player") 
                   and VRT.State.IsSpellReady(VRT.Spells.Mage.ConjureManaGem)
        end
    }
}