VRT = VRT or {}
VRT.Scanner = VRT.Scanner or {}
VRT.Scanner.Tooltip = {}

local InternalTooltip = nil

---
-- @public Thread-Safe Tooltip Localizer
-- @param slotID number Native action button engine index pointer
-- @return string Resolved human-readable localized spell/item name text wrapper
---
function VRT.Scanner.Tooltip.ResolveLocalizedName(slotID)
    if not InternalTooltip then
        InternalTooltip = CreateFrame("GameTooltip", "PixelBotScannerTooltip", nil, "GameTooltipTemplate")
        InternalTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end

    InternalTooltip:ClearLines()
    InternalTooltip:SetAction(slotID)
    
    local textFrame = _G["PixelBotScannerTooltipTextLeft1"]
    return textFrame and textFrame:GetText() or "Unknown"
end
