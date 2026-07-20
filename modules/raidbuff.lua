RaidComp = RaidComp or {}

local defaults = {
    selectedBuffs = {[1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true},
    hidePresent = false,
    showRoleIcons = true,
    showPromoteIcons = true,
}

local function ApplyDefaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            ApplyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

RaidCompDB = type(RaidCompDB) == "table" and RaidCompDB or {}
ApplyDefaults(RaidCompDB, defaults)
RaidComp.db = RaidCompDB

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
local classCounts = {}
local NUM_CLASSES = #classInfo
local raidFrame
local ICON_SIZE = 29
local ICON_GAP = 1
local ICON_COLUMNS = 2

local function HideIconFrames()
    for _, iconFrame in ipairs(iconFrames) do
        iconFrame:Hide()
    end
end

local function ScanGroup()
    for i = 1, NUM_CLASSES do
        classCounts[i] = 0
    end
    
    local numGroup = GetNumGroupMembers()
    if not numGroup or numGroup == 0 then
        return
    end
    
    for i = 1, numGroup do
        local _, _, classId = UnitClass("raid" .. i)
        if classId then
            classCounts[classId] = (classCounts[classId] or 0) + 1
        end
    end
end

local function FormatText(currentAmount, requiredAmount)
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
        
        local f = CreateFrame("Frame", "RaidCompBuffIcon" .. i, raidFrame)
        f:SetSize(ICON_SIZE, ICON_SIZE)
        
        local tex = f:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(info.icon)
        
        local text = f:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        text:SetPoint("BOTTOM", 0, 2)
        
        f.iconTex = tex
        f.text = text
        
        iconFrames[i] = f
    end

    return true
end

local function UpdateDisplay()
    if #iconFrames == 0 or not IsInRaid() then
        HideIconFrames()
        return
    end

    
    ScanGroup()
    
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

            f:ClearAllPoints()

            local gridIndex = visibleIndex - 1
            local column = gridIndex % ICON_COLUMNS
            local row = math.floor(gridIndex / ICON_COLUMNS)
            local xOffset = 4 + column * (ICON_SIZE + ICON_GAP)
            local yOffset = -5 - row * (ICON_SIZE + ICON_GAP)
            f:SetPoint("TOPLEFT", raidTab, "BOTTOMLEFT", xOffset, yOffset)

            f.text:SetText(FormatText(current, req))
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
