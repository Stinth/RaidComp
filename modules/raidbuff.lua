local addonName = "RaidEnhance"

local db = {
    selectedBuffs = {[1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true},
    hidePresent = false,
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

local function BoolToNum(value)
    return value and 1 or 0
end

local function CreateIconFrames()
    for i = 1, NUM_CLASSES do
        local info = classInfo[i]
        
        local f = CreateFrame("Frame", "RaidBuffIcon" .. i, FriendsFrame)
        f:SetSize(36, 36)
        f:SetParent(FriendsFrame)
        
        local bg = f:CreateTexture()
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        
        local tex = f:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(info.icon)
        
        local text = f:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        text:SetPoint("CENTER", 0, 0)
        
        f.iconTex = tex
        f.text = text
        f.bg = bg
        
        iconFrames[i] = f
    end
    
    UpdateDisplay()
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
        required[i] = BoolToNum(db.selectedBuffs[i])
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

local function UpdateDisplay()
    for _, f in ipairs(iconFrames) do
        f:Hide()
    end
    
    if #iconFrames == 0 then
        return
    end
    
    ScanGroup()
    
    local visibleIndex = 0
    local required = GetRequiredBuffs()
    
    for i = 1, NUM_CLASSES do
        local f = iconFrames[i]
        local req = required[i] or 0
        local current = classCounts[i - 1] or 0
        
        if req > 0 then
            local show = true
            if db.hidePresent and current >= req then
                show = false
            end
            
            if show then
                visibleIndex = visibleIndex + 1
                
                f:ClearAllPoints()
                
                if visibleIndex == 1 then
                    f:SetPoint("TOPLEFT", FriendsFrame, "TOPRIGHT", 10, 0)
                else
                    f:SetPoint("TOPLEFT", iconFrames[visibleIndex - 1], "BOTTOMLEFT", 0, -2)
                end
                
                f:Show()
                f.text:SetText(FormatText(current, req))
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        CreateIconFrames()
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateDisplay()
    end
end)

SLASH_RAIDENHANCE1 = "/re"
SLASH_RAIDENHANCE2 = "/raidenhance"

SlashCmdList["RAIDENHANCE"] = function(msg)
    local cmd, arg = strsplit(" ", msg, 2)
    cmd = cmd or msg
    
    if cmd == "hidepresent" then
        db.hidePresent = not db.hidePresent
        print("hidePresent = " .. tostring(db.hidePresent))
        UpdateDisplay()
    elseif cmd == "set" then
        if arg then
            for i, info in ipairs(classInfo) do
                if string.find(string.lower(info.name), string.lower(arg)) then
                    db.selectedBuffs[i] = not db.selectedBuffs[i]
                    print(info.name .. " = " .. tostring(db.selectedBuffs[i]))
                    UpdateDisplay()
                    return
                end
            end
        end
    elseif cmd == "list" then
        for i, info in ipairs(classInfo) do
            if db.selectedBuffs[i] then
                print("+ " .. info.name)
            end
        end
    elseif cmd == "reset" then
        db.selectedBuffs = {}
        db.hidePresent = false
        print("reset")
        UpdateDisplay()
    else
        print("/re set <class> - toggle tracking")
        print("/re hidepresent - toggle hiding when met")
        print("/re list - show tracked")
        print("/re reset - reset all")
    end
end

print("RaidEnhance loaded.")