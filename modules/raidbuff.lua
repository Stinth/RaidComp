RaidComp.ClassInfo = {
    [1] = { name = "Warrior", icon = 626008 },
    [2] = { name = "Paladin", icon = 626003 },
    [3] = { name = "Hunter", icon = 626000 },
    [4] = { name = "Rogue", icon = 626005 },
    [5] = { name = "Priest", icon = 626004 },
    [6] = { name = "Death Knight", icon = 625998 },
    [7] = { name = "Shaman", icon = 626006 },
    [8] = { name = "Mage", icon = 626001 },
    [9] = { name = "Warlock", icon = 626007 },
    [10] = { name = "Monk", icon = 626002 },
    [11] = { name = "Druid", icon = 625999 },
    [12] = { name = "Demon Hunter", icon = 1260827 },
    [13] = { name = "Evoker", icon = 4574311 },
}

local classInfo = RaidComp.ClassInfo
local iconFrames = {}
local NUM_CLASSES = #classInfo
local raidFrame

RaidComp.ClassGridLayout = {
    iconSize = 29,
    gap = 1,
    columns = 2,
    xInset = 4,
    yInset = 5,
}

local function HideIconFrames()
    for _, iconFrame in ipairs(iconFrames) do
        iconFrame:Hide()
    end
end

function RaidComp.GetRaidClassCounts()
    local classCounts = {}
    for i = 1, NUM_CLASSES do
        classCounts[i] = 0
    end
    
    local numGroup = GetNumGroupMembers()
    if not IsInRaid() or not numGroup or numGroup == 0 then
        return classCounts
    end
    
    for i = 1, numGroup do
        local _, _, classId = UnitClass("raid" .. i)
        if classId then
            classCounts[classId] = (classCounts[classId] or 0) + 1
        end
    end

    return classCounts
end

function RaidComp.FormatClassCount(currentAmount, requiredAmount)
    local color
    if currentAmount == 0 then
        color = "|cFFFF3030"
    elseif currentAmount < requiredAmount then
        color = "|cFFFFD700"
    else
        color = "|cFF50C878"
    end
    return color .. math.min(currentAmount, requiredAmount) .. "/" .. requiredAmount .. "|r"
end

function RaidComp.CreateClassIndicator(parent, info, globalName)
    local indicator = CreateFrame("Frame", globalName, parent)
    local layout = RaidComp.ClassGridLayout
    indicator:SetSize(layout.iconSize, layout.iconSize)

    local texture = indicator:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture(info.icon)

    local text = indicator:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    text:SetPoint("BOTTOM", 0, 2)

    indicator.iconTex = texture
    indicator.text = text
    return indicator
end

function RaidComp.PositionClassIndicator(indicator, anchor, relativePoint, visibleIndex)
    local layout = RaidComp.ClassGridLayout
    local gridIndex = visibleIndex - 1
    local column = gridIndex % layout.columns
    local row = math.floor(gridIndex / layout.columns)
    local xOffset = layout.xInset + column * (layout.iconSize + layout.gap)
    local yOffset = -layout.yInset - row * (layout.iconSize + layout.gap)

    indicator:ClearAllPoints()
    indicator:SetPoint("TOPLEFT", anchor, relativePoint, xOffset, yOffset)
end

local function CreateIconFrames()
    raidFrame = SocialUIFrame and SocialUIFrame.RaidFrame
    if not raidFrame then
        return false
    end

    if #iconFrames > 0 then
        return true
    end

    for i = 1, NUM_CLASSES do
        local info = classInfo[i]
        iconFrames[i] = RaidComp.CreateClassIndicator(raidFrame, info, "RaidCompBuffIcon" .. i)
    end

    return true
end

local function UpdateDisplay()
    if #iconFrames == 0 or not IsInRaid() then
        HideIconFrames()
        return
    end

    
    local classCounts = RaidComp.GetRaidClassCounts()
    
    local visibleIndex = 0
    local raidTab = SocialUIFrame:GetTabByType(SocialUITabType.RaidList)
    if not raidTab then
        HideIconFrames()
        return
    end
    
    for i = 1, NUM_CLASSES do
        local f = iconFrames[i]
        local req = RaidComp.db.selectedBuffs[i] and 1 or 0
        local current = classCounts[i] or 0
        
        local shouldShow = req > 0 and not (RaidComp.db.hidePresent and current >= req)
        if shouldShow then
            visibleIndex = visibleIndex + 1
            RaidComp.PositionClassIndicator(f, raidTab, "BOTTOMLEFT", visibleIndex)
            f.text:SetText(RaidComp.FormatClassCount(current, req))
        end

        f:SetShown(shouldShow)
    end
end

RaidComp.UpdateDisplay = UpdateDisplay

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")

local function InitializeForSocialUI()
    if CreateIconFrames() and not frame.raidFrameHooked then
        frame.raidFrameHooked = true
        raidFrame:HookScript("OnShow", UpdateDisplay)
        UpdateDisplay()
    end
end

frame:SetScript("OnEvent", function(self, event, addonLoaded)
    if event == "ADDON_LOADED" then
        if addonLoaded == "Blizzard_SocialUI" then
            InitializeForSocialUI()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        InitializeForSocialUI()
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateDisplay()
    end
end)

InitializeForSocialUI()
