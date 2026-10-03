VRT = VRT or {}
VRT.Signal = VRT.Signal or {}

--- @private UI Frame Infrastructure Elements
local signalFrame = CreateFrame("Frame", "VR_SignalPixelFrame", UIParent)
signalFrame:SetSize(5, 5)
signalFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
signalFrame:SetFrameStrata("TOOLTIP")

local signalTexture = signalFrame:CreateTexture(nil, "BACKGROUND")
signalTexture:SetTexture(1, 1, 1, 1)
signalTexture:SetAllPoints(signalFrame)
signalFrame.texture = signalTexture

---
-- @public Low-Level Frame Hardware Painter
-- @param r number Crimson color channel integer value mapped (0..255).
-- @param g number Emerald color channel integer value mapped (0..255).
-- @param b number Sapphire color channel integer value mapped (0..255).
---
function VRT.Signal.SetSignalColor(r, g, b)
    signalFrame.texture:SetVertexColor(
        (tonumber(r) or 0) / 255,
        (tonumber(g) or 0) / 255,
        (tonumber(b) or 0) / 255,
        1
    )
end

---
-- @public Automation RGB Data Signal Link
-- @param bindString string Hardware key configuration extracted from scanning layers (e.g., "CTRL-ALT-5").
---
function VRT.Signal.SendBind(bindString)
    if not bindString or bindString == "NOT_BOUND" or bindString == "IDLE" then
        VRT.Signal.SetSignalColor(0, 0, 0)
        return
    end

    local hasShift = string.find(bindString, "SHIFT%-") and 1 or 0
    local hasCtrl  = string.find(bindString, "CTRL%-")  and 1 or 0
    local hasAlt   = string.find(bindString, "ALT%-")   and 1 or 0

    local mainKey = string.match(bindString, "([^-]+)$")
    if not mainKey then
        VRT.Signal.SetSignalColor(0, 0, 0)
        return
    end
    
    local keyCode = VRT.KeyCodes[mainKey]

    if not keyCode then
        VRT.Signal.SetSignalColor(0, 0, 0)
        return
    end

    local modifierCode = (hasShift * 1) + (hasCtrl * 2) + (hasAlt * 4)

    if VRT.DebugMode then
        local modText = (hasCtrl == 1 and "CTRL+" or "") .. (hasAlt == 1 and "ALT+" or "") .. (hasShift == 1 and "SHIFT+" or "")
        VRT.Utils.Log(string.format("Send: |cffffffff%s|r -> RGB(%d, %d, 255) -> Press: |cff00ff00%s%s|r", bindString, keyCode, modifierCode, modText, mainKey))
    end

    VRT.Signal.SetSignalColor(keyCode, modifierCode, 255)
end

VRT.Signal.SetSignalColor(0, 0, 0)
