local roleIcons = {
    DAMAGER = INLINE_DAMAGER_ICON,
    HEALER = INLINE_HEALER_ICON,
    TANK = INLINE_TANK_ICON,
}

local roleFonts = {}

local function GetRaidButton(index)
    return _G["RaidGroupButton" .. index]
end

local function CreateRoleText(index)
    local f = GetRaidButton(index)
    if not f then
        return nil
    end
    
    local text = f:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    text:SetPoint("LEFT", f, "LEFT", 0, 0)
    text:SetText(roleIcons.DAMAGER)
    text:Show()
    
    roleFonts[index] = text
    return text
end

local function UpdateRoleDisplay()
    local numGroup = GetNumGroupMembers()
    
    for i, text in pairs(roleFonts) do
        text:Hide()
    end
    
    if not numGroup or numGroup == 0 then
        return
    end
    
    local inRaid = IsInRaid()
    
    for i = 1, numGroup do
        local unit = inRaid and "raid" .. i or (i == 1 and "player" or "party" .. (i - 1))
        
        if not UnitExists(unit) then
            break
        end
        
        local role = UnitGroupRolesAssigned(unit)
        
        if role and role ~= "NONE" then
            local text = roleFonts[i]
            if not text then
                text = CreateRoleText(i)
            end
            
            if text then
                text:SetText(roleIcons[role])
                text:Show()
            end
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")

f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
    UpdateRoleDisplay()
end)

RaidEnhance.UpdateRoleDisplay = function()
    UpdateRoleDisplay()
end
