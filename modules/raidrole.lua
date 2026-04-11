local roleIcons = {
    DAMAGER = INLINE_DAMAGER_ICON,
    HEALER = INLINE_HEALER_ICON,
    TANK = INLINE_TANK_ICON,
}

local roleFrames = {}

local function GetRaidButton(index)
    return _G["RaidGroupButton" .. index]
end

local function CreateRoleAnchor(index, promote, role)
    local anchor = CreateFrame("Frame", "RaidEnhAnchor" .. index, UIParent)
    anchor:SetSize(16, 16)
    anchor:SetFrameStrata("HIGH")
    anchor:Hide()
    
    local text = anchor:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    text:SetPoint("LEFT", anchor, 0, 0)
    text:SetText("|Tinterface/groupframe/ui-group-leadericon.blp:0|t") --..roleIcons[role]
    
    anchor.text = text
    roleFrames[index] = anchor
    return anchor
end

local function UpdateRoleDisplay()
    local numGroup = GetNumGroupMembers()
    
    for i, f in pairs(roleFrames) do
        f:Hide()
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
        local promote = ""

        promote = (UnitIsGroupLeader(unit) and "|Tinterface/groupframe/ui-group-leadericon.blp:0|t")
        or (UnitIsGroupAssistant(unit) and "|Tinterface/groupframe/ui-group-assistanticon.blp:0|t")
        or (GetPartyAssignment("MAINTANK", unit) and "|Tinterface/groupframe/ui-group-maintank.blp:0|t")
        or ""
        
        if role and role ~= "NONE" then
            local f = roleFrames[i]
            if not f then
                f = CreateRoleAnchor(i, promote, role)
            end
            
            local raidBtn = GetRaidButton(i)
            if raidBtn and raidBtn:IsShown() then
                f:ClearAllPoints()
                f:SetPoint("LEFT", raidBtn, "LEFT", 2, -1)
                f.text:SetText(promote..roleIcons[role])
                f:Show()
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

print("RaidEnhance role module loaded.")