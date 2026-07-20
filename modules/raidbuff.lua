local addonName = "RaidComp"

RaidComp = {}
RaidComp.db = {
    selectedBuffs = {[1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true},
    hidePresent = false,
    showRoleIcons = true,
    showPromoteIcons = true,
}

local classInfo = {
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

local iconFrames = {}
local classCounts = {}
local NUM_CLASSES = 13
local raidFrame
local ICON_SIZE = 29
local ICON_GAP = 1
local ICON_COLUMNS = 2

local function BoolToNum(value)
    return value and 1 or 0
end

local function ScanGroup()
    for i = 0, 13 do
        classCounts[i] = 0
    end
    
    local numGroup = GetNumGroupMembers()
    if not numGroup or numGroup == 0 then
        return
    end
    
    local inRaid = IsInRaid()
    for i = 1, numGroup do
        local unit = inRaid and "raid" .. i or (i == 1 and "player" or "party" .. (i - 1))
        local _, _, classId = UnitClass(unit)
        if classId then
            classCounts[classId] = classCounts[classId] + 1
        end
    end
end

local function GetRequiredBuffs()
    local required = {}
    for i = 1, 13 do
        required[i] = BoolToNum(RaidComp.db.selectedBuffs[i])
    end
    return required
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
    if not raidFrame or #iconFrames > 0 then
        return false
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
    for _, f in ipairs(iconFrames) do
        f:Hide()
    end
    local inRaid = IsInRaid()
    if #iconFrames == 0 or not inRaid then
        return
    end

    
    ScanGroup()
    
    local visibleIndex = 0
    local required = GetRequiredBuffs()
    local raidTab = SocialUIFrame:GetTabByType(SocialUITabType.RaidList)
    if not raidTab then
        return
    end
    
    for i = 1, NUM_CLASSES do
        local f = iconFrames[i]
        local req = required[i] or 0
        local current = classCounts[i] or 0
        
        if req > 0 then
            local show = true
            if RaidComp.db.hidePresent and current >= req then
                show = false
            end
            
            if show then
                visibleIndex = visibleIndex + 1
                
                f:ClearAllPoints()

                local gridIndex = visibleIndex - 1
                local column = gridIndex % ICON_COLUMNS
                local row = math.floor(gridIndex / ICON_COLUMNS)
                local xOffset = 4 + column * (ICON_SIZE + ICON_GAP)
                local yOffset = -5 - row * (ICON_SIZE + ICON_GAP)
                f:SetPoint("TOPLEFT", raidTab, "BOTTOMLEFT", xOffset, yOffset)
                
                f:Show()
                f.text:SetText(FormatText(current, req))
            end
        end
    end
end

RaidComp.UpdateDisplay = UpdateDisplay

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")

local function InitializeForSocialUI()
    if CreateIconFrames() then
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
