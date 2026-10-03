VRT = VRT or {}
VRT.Scanner = VRT.Scanner or {}

---
-- @public Client Input Binding Evaluator
-- @param barPrefix string Native Blizzard bar frame identifier string hash.
-- @param index number Vertical/Horizontal button positioning matrix index (1..12).
-- @return string Normalized system keyboard bind string mapped directly to engine matrix.
---
function VRT.Scanner.ResolveKeyBind(barPrefix, index)
    local bindPrefixes = {
        ["ActionButton"]              = "ACTIONBUTTON",
        ["MultiBarBottomLeftButton"]  = "MULTIACTIONBAR1BUTTON",
        ["MultiBarBottomRightButton"] = "MULTIACTIONBAR2BUTTON",
        ["MultiBarRightButton"]       = "MULTIACTIONBAR3BUTTON",
        ["MultiBarLeftButton"]        = "MULTIACTIONBAR4BUTTON",
    }
    
    local internalPrefix = bindPrefixes[barPrefix]
    if not internalPrefix then return "NOT_BOUND" end
    
    local key1, key2 = GetBindingKey(internalPrefix .. index)
    return key1 or key2 or "NOT_BOUND"
end
