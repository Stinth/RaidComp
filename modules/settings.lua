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

local NUM_CLASSES = 13

local frame = CreateFrame("Frame")
frame.name = "RaidEnhance"

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("RaidEnhance")

local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetText("Track classes in your group")

local hideCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
hideCheck:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
hideCheck:SetScript("OnClick", function(self)
    RaidEnhance.db.hidePresent = self:GetChecked()
    if RaidEnhance.UpdateDisplay then
        RaidEnhance.UpdateDisplay()
    end
end)

local hideText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hideText:SetPoint("LEFT", hideCheck, "RIGHT", 5, 0)
hideText:SetText("Hide when requirement met")

local classLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
classLabel:SetPoint("TOPLEFT", hideCheck, "BOTTOMLEFT", 0, -25)
classLabel:SetText("Track Classes:")

local checks = {}
for i = 1, NUM_CLASSES do
    local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    local row = math.floor((i - 1) / 2)
    local col = (i - 1) % 2
    check:SetPoint("TOPLEFT", classLabel, "BOTTOMLEFT", (col * 120), -25 - (row * 30))
    check:SetScript("OnClick", function(self)
        RaidEnhance.db.selectedBuffs[i] = self:GetChecked()
        if RaidEnhance.UpdateDisplay then
            RaidEnhance.UpdateDisplay()
        end
    end)
    
    local tex = check:CreateTexture(nil, "OVERLAY")
    tex:SetSize(20, 20)
    tex:SetPoint("LEFT", check, "RIGHT", 5, 0)
    tex:SetTexture(classInfo[i].icon)
    
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", tex, "RIGHT", 3, 0)
    text:SetText(classInfo[i].name)
    
    checks[i] = check
end

frame:SetScript("OnShow", function()
    hideCheck:SetChecked(RaidEnhance.db.hidePresent)
    for i = 1, NUM_CLASSES do
        if checks[i] and RaidEnhance.db.selectedBuffs then
            checks[i]:SetChecked(RaidEnhance.db.selectedBuffs[i])
        end
    end
end)

local category = Settings.RegisterCanvasLayoutCategory(frame, "RaidEnhance")
Settings.RegisterAddOnCategory(category)

SLASH_RAIDENHANCE1 = "/re"

SlashCmdList["RAIDENHANCE"] = function(msg)
    Settings.OpenToCategory(category:GetID())
end