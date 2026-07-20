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

local function GetRoleAnchor(playerFrame)
    local anchor = roleFrames[playerFrame]
    if anchor then
        return anchor
    end

    anchor = CreateFrame("Frame", nil, playerFrame)
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

local function HideInactiveRoleAnchors(activeAnchors)
    for _, anchor in pairs(roleFrames) do
        if not activeAnchors or not activeAnchors[anchor] then
            anchor:Hide()
        end
    end
end

local function SortFramesByPosition(frame1, frame2)
    local top1, top2 = frame1:GetTop() or 0, frame2:GetTop() or 0
    if math.abs(top1 - top2) > 1 then
        return top1 > top2
    end

    return (frame1:GetLeft() or 0) < (frame2:GetLeft() or 0)
end

local function GetSortedChildren(parent, predicate)
    local result = {}
    if not parent then
        return result
    end

    for _, child in ipairs({ parent:GetChildren() }) do
        if child:IsShown() and (not predicate or predicate(child)) then
            table.insert(result, child)
        end
    end

    table.sort(result, SortFramesByPosition)
    return result
end

local function GetRaidMembersBySubgroup()
    local members = {}
    local numRaidGroups = NUM_RAID_GROUPS or 8
    for subgroup = 1, numRaidGroups do
        members[subgroup] = {}
    end

    for raidIndex = 1, GetNumGroupMembers() do
        local _, _, subgroup = GetRaidRosterInfo(raidIndex)
        if subgroup and members[subgroup] then
            table.insert(members[subgroup], "raid" .. raidIndex)
        end
    end

    return members
end

local function UpdatePooledRoleDisplay(raidFrame, activeAnchors)
    local groupsFrame = raidFrame and raidFrame.GroupsFrame
    if not groupsFrame then
        return false
    end

    -- Blizzard assigns the current raid unit directly to every acquired row.
    if raidFrame.players then
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

    local groupFrames = GetSortedChildren(groupsFrame, function(groupFrame)
        return groupFrame.PlayersFrame ~= nil
    end)
    if #groupFrames == 0 then
        return false
    end

    local membersBySubgroup = GetRaidMembersBySubgroup()
    for subgroup, groupFrame in ipairs(groupFrames) do
        local playerFrames = GetSortedChildren(groupFrame.PlayersFrame, function(playerFrame)
            return playerFrame.CharacterClass ~= nil
        end)
        local subgroupMembers = membersBySubgroup[subgroup]

        for playerIndex, playerFrame in ipairs(playerFrames) do
            local unit = subgroupMembers and subgroupMembers[playerIndex]
            local roleAtlas, promotionAtlas, xOffset
            if unit then
                roleAtlas, promotionAtlas, xOffset = GetRoleDisplayInfo(unit)
            end
            if roleAtlas then
                local anchor = GetRoleAnchor(playerFrame)
                SetRoleAnchorDisplay(anchor, playerFrame, roleAtlas, promotionAtlas, xOffset)
                activeAnchors[anchor] = true
            end
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

local function UpdateRoleDisplay()
    local db = RaidComp and RaidComp.db or {}
    if db.showRoleIcons == false or not IsInRaid() then
        HideInactiveRoleAnchors()
        return
    end

    local activeAnchors = {}
    local raidFrame = SocialUIFrame and SocialUIFrame.RaidFrame
    if not UpdatePooledRoleDisplay(raidFrame, activeAnchors) then
        UpdateLegacyRoleDisplay(activeAnchors)
    end
    HideInactiveRoleAnchors(activeAnchors)
end

local updateQueued = false
local function QueueRoleDisplayUpdate()
    if updateQueued then
        return
    end

    updateQueued = true
    C_Timer.After(0, function()
        updateQueued = false
        UpdateRoleDisplay()
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("ROLE_CHANGED_INFORM")

local raidFrameHooked = false
local contentsUpdateHooked = false
local function InitializeForSocialUI()
    local raidFrame = SocialUIFrame and SocialUIFrame.RaidFrame
    if raidFrame and not raidFrameHooked then
        raidFrameHooked = true
        raidFrame:HookScript("OnShow", QueueRoleDisplayUpdate)
        QueueRoleDisplayUpdate()
    end

    if raidFrame and not contentsUpdateHooked then
        contentsUpdateHooked = true
        hooksecurefunc(raidFrame, "UpdateContents", QueueRoleDisplayUpdate)
    end
end

eventFrame:SetScript("OnEvent", function(self, event, addonLoaded)
    if event == "ADDON_LOADED" then
        if addonLoaded == "Blizzard_SocialUI" then
            InitializeForSocialUI()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        InitializeForSocialUI()
        QueueRoleDisplayUpdate()
    else
        QueueRoleDisplayUpdate()
    end
end)

InitializeForSocialUI()

RaidComp.UpdateRoleDisplay = QueueRoleDisplayUpdate
