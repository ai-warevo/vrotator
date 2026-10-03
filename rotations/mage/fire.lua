VRT = VRT or {}
VRT.Rotations = VRT.Rotations or {}

local Spell = VRT.Spells.Mage

local function CheckMirrorImage()
    if VRT.IsSpellReady(Spell.MirrorImage) then
        local bind = VRT.MyBinds[Spell.MirrorImage]
        if bind then VRT.SendBindSignal(bind) return true end
    end
    return false
end

local function CheckCombustion()
    if VRT.IsSpellReady(Spell.Combustion) then
        local bind = VRT.MyBinds[Spell.Combustion]
        if bind then VRT.SendBindSignal(bind) return true end
    end
    return false
end

local function CheckHotStreak()
    if VRT.HasBuff("player", Spell.HotStreakProc) then
        local bind = VRT.MyBinds[Spell.Pyroblast]
        if bind then VRT.SendBindSignal(bind) return true end
    end
    return false
end

local function CheckScorch()
    local hasShadowMastery = VRT.HasDebuff("target", Spell.ShadowMastery)
    local hasScorch = VRT.HasDebuff("target", Spell.ScorchDebuff)
    
    if not hasShadowMastery and not hasScorch then
        local bind = VRT.MyBinds[Spell.ScorchSpell]
        if bind then VRT.SendBindSignal(bind) return true end
    end
    return false
end

local function CheckLivingBomb()
    if IsSpellKnown(Spell.LivingBomb) then
        local hasBomb, bombCaster = VRT.HasDebuff("target", Spell.LivingBomb)
        if not hasBomb or bombCaster ~= "player" then
            local bind = VRT.MyBinds[Spell.LivingBomb]
            if bind then VRT.SendBindSignal(bind) return true end
        end
    end
    return false
end

local function CastFiller()
    local fireballBind = VRT.MyBinds[Spell.Fireball]
    if fireballBind then 
        VRT.SendBindSignal(fireballBind) 
        return true 
    end
    return false
end

local function MageFireBuffs()
    if VRT.CheckBuffAndSend("player", {Spell.MoltenArmor}, {Spell.MoltenArmor}) then
        return true
    end

    local intellects = {Spell.ArcaneIntellect, Spell.ArcaneBrilliance, Spell.DalaranIntellect, Spell.DalaranBrilliance}
    if VRT.CheckBuffAndSend("player", intellects, intellects) then
        return true
    end

    if VRT.IsSpellReady(Spell.FocusMagic) and UnitExists("focus") and not UnitIsDeadOrGhost("focus") and UnitIsFriend("player", "focus") then
        if VRT.CheckBuffAndSend("focus", {Spell.FocusMagic}, {Spell.FocusMagic}, true) then return true end
    end

    return false
end

local function MageFireCombat()        
    if CheckHotStreak() then return true end
    if CheckScorch() then return true end
    if CheckLivingBomb() then return true end
    if CheckMirrorImage() then return true end
    if CheckCombustion() then return true end
    if CastFiller() then return true end

    return false
end

function VRT.Rotations.MageFire()
    if MageFireBuffs() then return true end
    if MageFireCombat() then return true end
    return false
end
