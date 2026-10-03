VRT = VRT or {}
VRT.Signal = VRT.Signal or {}

--- @private UI Frame Infrastructure Elements
local signalFrame = CreateFrame("Frame", "VR_SignalPixelFrame", UIParent)
signalFrame:SetSize(5, 5)
signalFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
signalFrame:SetFrameStrata("TOOLTIP")

local signalTexture = signalFrame:CreateTexture(nil, "BACKGROUND")
signalTexture:SetAllPoints(signalFrame)
signalFrame.texture = signalTexture

---
-- @public Low-Level Frame Hardware Painter
-- @param r number Crimson color channel integer value mapped (0..255).
-- @param g number Emerald color channel integer value mapped (0..255).
-- @param b number Sapphire color channel integer value mapped (0..255).
-- @desc Normalizes integer color payloads to floating-point vectors and updates UI vertex color.
---
function VRT.Signal.SetSignalColor(r, g, b)
    signalFrame.texture:SetTexture(
        (tonumber(r) or 0) / 255,
        (tonumber(g) or 0) / 255,
        (tonumber(b) or 0) / 255,
        1
    )
end

---
-- @public Automation RGB Data Signal Link
-- @param bindString string Hardware key configuration extracted from scanning layers (e.g., "CTRL-ALT-5").
-- @desc Resolves string bindings, arithmetically encodes key modifiers into individual integer channels, 
--       and paints the desktop pixel matrix to bridge data streams into the external Python process.
---
function VRT.Signal.SendBind(bindString)
    if not bindString or bindString == "NOT_BOUND" then
        VRT.Signal.SetSignalColor(0, 0, 0)
        return
    end

    -- Extract active modifiers and main button identities using lazy pattern definitions
    local hasShift = string.match(bindString, "SHIFT%-") and 1 or 0
    local hasCtrl  = string.match(bindString, "CTRL%-")  and 1 or 0
    local hasAlt   = string.match(bindString, "ALT%-")   and 1 or 0

    local mainKey = string.match(bindString, "([^-]+)$")
    local keyCode = VRT.KeyCodes[mainKey]

    -- Guard Clause: Dropping execution path if target key bound lacks hardware ASCII representation
    if not keyCode then
        VRT.Signal.SetSignalColor(0, 0, 0)
        return
    end

    -- Mathematical Flag Assembly: Computes singular numeric value (0..7) out of separate binary states
    local modifierCode = (hasShift * 1) + (hasCtrl * 2) + (hasAlt * 4)

    -- Technical Decoupled Logging Output
    local modText = (hasCtrl == 1 and "CTRL+" or "") .. (hasAlt == 1 and "ALT+" or "") .. (hasShift == 1 and "SHIFT+" or "")
    VRT.Utils.Log(string.format("Send: |cffffffff%s|r -> RGB(%d, %d, 255) -> Press: |cff00ff00%s%s|r", bindString, keyCode, modifierCode, modText, mainKey))

    -- Output Execution: Red Channel = Virtual ASCII Key, Green Channel = Encoded Modifiers, Blue Channel = Data Marker
    VRT.Signal.SetSignalColor(keyCode, modifierCode, 255)
end

-- Native Framework Initialization Default State Flusher
VRT.Signal.SetSignalColor(0, 0, 0)
