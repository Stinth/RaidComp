local roleFrames = {}

-- Use Blizzard's micro role atlases, which are designed for compact unit rows.
local function GetRoleAtlas(role)
    if role and role ~= "NONE" then
        return GetMicroIconForRole(role)
    end

    return nil
end

local function GetPromotionAtlas(unit)
    if UnitIsGroupLeader(unit) then
        return "friends-icon-raidLead", 2
    elseif UnitIsGroupAssistant(unit) then
        return "friends-icon-raidAssist", 2
    elseif GetPartyAssignment("MAINTANK", unit) then
        return "RaidFrame-Icon-MainTank", 4
    end

    return nil, 2
end

local function GetRoleDisplayInfo(unit)
    local roleAtlas = GetRoleAtlas(UnitGroupRolesAssigned(unit))
    if not roleAtlas then
        return nil
    end

    local db = RaidComp and RaidComp.db or {}
    local promotionAtlas
    local xOffset = 2
    if db.showPromoteIcons then
        promotionAtlas, xOffset = GetPromotionAtlas(unit)
    end

    return roleAtlas, promotionAtlas, xOffset
end

local function CreateRoleAnchor(playerFrame)
    local anchor = CreateFrame("Frame", nil, playerFrame)
    anchor:SetSize(36, 20)
    anchor:SetPoint("LEFT", playerFrame, "LEFT", 2, 0)
    anchor:SetFrameLevel(playerFrame:GetFrameLevel() + 10)
    anchor:Hide()

    local promotionTexture = anchor:CreateTexture(nil, "OVERLAY")
    promotionTexture:SetPoint("LEFT", anchor, "LEFT")
    promotionTexture:Hide()

    local roleTexture = anchor:CreateTexture(nil, "OVERLAY")
    roleTexture:SetSize(17, 17)

    anchor.promotionTexture = promotionTexture
    anchor.roleTexture = roleTexture
    return anchor
end

local function GetRoleAnchor(playerFrame)
    local anchor = roleFrames[playerFrame]
    if anchor then
        return anchor
    end

    anchor = CreateRoleAnchor(playerFrame)
    roleFrames[playerFrame] = anchor
    return anchor
end

local function SetRoleAnchorDisplay(anchor, playerFrame, roleAtlas, promotionAtlas, xOffset)
    anchor:ClearAllPoints()
    anchor:SetPoint("LEFT", playerFrame, "LEFT", xOffset, 0)

    anchor.roleTexture:ClearAllPoints()
    if promotionAtlas then
        anchor.promotionTexture:SetAtlas(promotionAtlas)
        if promotionAtlas == "RaidFrame-Icon-MainTank" then
            anchor.promotionTexture:SetSize(14, 14)
        else
            anchor.promotionTexture:SetSize(17, 15)
        end
        anchor.promotionTexture:Show()
        local roleIconSpacing = promotionAtlas == "RaidFrame-Icon-MainTank" and 0 or -1
        anchor.roleTexture:SetPoint("LEFT", anchor.promotionTexture, "RIGHT", roleIconSpacing, 0)
    else
        anchor.promotionTexture:Hide()
        anchor.roleTexture:SetPoint("LEFT", anchor, "LEFT")
    end

    anchor.roleTexture:SetAtlas(roleAtlas)
    anchor:Show()
end

function RaidComp.CreateRolePreviewAnchor(playerFrame)
    return CreateRoleAnchor(playerFrame)
end

function RaidComp.SetRolePreviewAnchor(anchor, playerFrame, role, promotionAtlas)
    local roleAtlas = GetRoleAtlas(role)
    if not roleAtlas then
        anchor:Hide()
        return
    end

    local xOffset = promotionAtlas == "RaidFrame-Icon-MainTank" and 4 or 2
    SetRoleAnchorDisplay(anchor, playerFrame, roleAtlas, promotionAtlas, xOffset)
end

local function HideInactiveRoleAnchors(activeAnchors)
    for _, anchor in pairs(roleFrames) do
        if not activeAnchors or not activeAnchors[anchor] then
            anchor:Hide()
        end
    end
end

local function UpdateSocialRoleDisplay(raidFrame, activeAnchors)
    if not raidFrame or type(raidFrame.players) ~= "table" then
        return false
    end

    -- Blizzard assigns the current raid unit directly to every acquired row.
    for _, playerFrame in ipairs(raidFrame.players) do
        local roleAtlas, promotionAtlas, xOffset
        if playerFrame.unit then
            roleAtlas, promotionAtlas, xOffset = GetRoleDisplayInfo(playerFrame.unit)
        end
        if roleAtlas then
            local anchor = GetRoleAnchor(playerFrame)
            SetRoleAnchorDisplay(anchor, playerFrame, roleAtlas, promotionAtlas, xOffset)
            activeAnchors[anchor] = true
        end
    end

    return true
end

local function UpdateLegacyRoleDisplay(activeAnchors)
    for raidIndex = 1, GetNumGroupMembers() do
        local playerFrame = _G["RaidGroupButton" .. raidIndex]
        local unit = "raid" .. raidIndex
        local roleAtlas, promotionAtlas, xOffset
        if playerFrame then
            roleAtlas, promotionAtlas, xOffset = GetRoleDisplayInfo(unit)
        end
        if roleAtlas then
            local anchor = GetRoleAnchor(playerFrame)
            SetRoleAnchorDisplay(anchor, playerFrame, roleAtlas, promotionAtlas, xOffset)
            activeAnchors[anchor] = true
        end
    end
end

local function UpdateRoleDisplay(raidFrame)
    local db = RaidComp and RaidComp.db or {}
    if db.showRoleIcons == false or not IsInRaid() then
        HideInactiveRoleAnchors()
        return
    end

    local activeAnchors = {}
    if not UpdateSocialRoleDisplay(raidFrame, activeAnchors) then
        UpdateLegacyRoleDisplay(activeAnchors)
    end
    HideInactiveRoleAnchors(activeAnchors)
end

RaidComp.RegisterRaidFrameUpdater(UpdateRoleDisplay)
RaidComp.UpdateRoleDisplay = RaidComp.RequestRaidFrameUpdate
