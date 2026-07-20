local classInfo = RaidComp.ClassInfo
local NUM_CLASSES = #classInfo

local frame = CreateFrame("Frame")
frame.name = "RaidComp"

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("RaidComp")

local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetText("Track classes in your group")

local hideCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
hideCheck:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
hideCheck:SetScript("OnClick", function(self)
    RaidComp.db.hidePresent = self:GetChecked()
    if RaidComp.UpdateDisplay then
        RaidComp.UpdateDisplay()
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
    local classID = i
    local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    local row = math.floor((classID - 1) / 2)
    local col = (classID - 1) % 2
    check:SetPoint("TOPLEFT", classLabel, "BOTTOMLEFT", (col * 120), -25 - (row * 30))
    check:SetScript("OnClick", function(self)
        RaidComp.db.selectedBuffs[classID] = self:GetChecked()
        if RaidComp.UpdateDisplay then
            RaidComp.UpdateDisplay()
        end
    end)
    
    local tex = check:CreateTexture(nil, "OVERLAY")
    tex:SetSize(20, 20)
    tex:SetPoint("LEFT", check, "RIGHT", 5, 0)
    tex:SetTexture(classInfo[classID].icon)
    
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", tex, "RIGHT", 3, 0)
    text:SetText(classInfo[classID].name)
    
    checks[classID] = check
end

local roleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
roleLabel:SetPoint("TOPLEFT", checks[NUM_CLASSES], "BOTTOMLEFT", -10, -30)
roleLabel:SetText("Role Icons:")

local showRolesCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
showRolesCheck:SetPoint("TOPLEFT", roleLabel, "BOTTOMLEFT", 0, -15)
showRolesCheck:SetScript("OnClick", function(self)
    RaidComp.db.showRoleIcons = self:GetChecked()
    if RaidComp.UpdateRoleDisplay then
        RaidComp.UpdateRoleDisplay()
    end
end)

local showRolesText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
showRolesText:SetPoint("LEFT", showRolesCheck, "RIGHT", 5, 0)
showRolesText:SetText("Show role icons (Tank/Healer/DPS)")

local promoteCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
promoteCheck:SetPoint("TOPLEFT", showRolesCheck, "BOTTOMLEFT", 0, -15)
promoteCheck:SetScript("OnClick", function(self)
    RaidComp.db.showPromoteIcons = self:GetChecked()
    if RaidComp.UpdateRoleDisplay then
        RaidComp.UpdateRoleDisplay()
    end
end)

local promoteText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
promoteText:SetPoint("LEFT", promoteCheck, "RIGHT", 5, 0)
promoteText:SetText("Show promote icons (Leader/Assistant/Main Tank)")

frame:SetScript("OnShow", function()
    hideCheck:SetChecked(RaidComp.db.hidePresent)
    for i = 1, NUM_CLASSES do
        if checks[i] and RaidComp.db.selectedBuffs then
            checks[i]:SetChecked(RaidComp.db.selectedBuffs[i])
        end
    end
    showRolesCheck:SetChecked(RaidComp.db.showRoleIcons ~= false)
    promoteCheck:SetChecked(RaidComp.db.showPromoteIcons ~= false)
end)

local category = Settings.RegisterCanvasLayoutCategory(frame, "RaidComp")
Settings.RegisterAddOnCategory(category)

SLASH_RAIDCOMP1 = "/rcomp"
SLASH_RAIDCOMP2 = "/raidcomp"
SLASH_RAIDCOMP3 = "/comp"

SlashCmdList["RAIDCOMP"] = function(msg)
    Settings.OpenToCategory(category:GetID())
end
