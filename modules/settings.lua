local classInfo = RaidComp.ClassInfo
local NUM_CLASSES = #classInfo
local UpdatePreview
local UpdateRoleSettingDependencies

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
    if UpdatePreview then
        UpdatePreview()
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
        if UpdatePreview then
            UpdatePreview()
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
    UpdateRoleSettingDependencies()
    if RaidComp.UpdateRoleDisplay then
        RaidComp.UpdateRoleDisplay()
    end
    if UpdatePreview then
        UpdatePreview()
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
    if UpdatePreview then
        UpdatePreview()
    end
end)

local promoteText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
promoteText:SetPoint("LEFT", promoteCheck, "RIGHT", 5, 0)
promoteText:SetText("Show promote icons (Leader/Assistant/Main Tank)")

UpdateRoleSettingDependencies = function()
    local roleIconsEnabled = showRolesCheck:GetChecked()
    promoteCheck:SetEnabled(roleIconsEnabled)
    promoteText:SetFontObject(roleIconsEnabled and GameFontNormal or GameFontDisable)
end

local slotsCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
slotsCheck:SetPoint("TOPLEFT", promoteCheck, "BOTTOMLEFT", 0, -15)
slotsCheck:SetScript("OnClick", function(self)
    RaidComp.db.showEmptySlots = self:GetChecked()
    if RaidComp.UpdateSlotDisplay then
        RaidComp.UpdateSlotDisplay()
    end
    if UpdatePreview then
        UpdatePreview()
    end
end)

local slotsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
slotsText:SetPoint("LEFT", slotsCheck, "RIGHT", 5, 0)
slotsText:SetText("Show empty player slots")

local preview = CreateFrame("Frame", nil, frame)
preview:SetPoint("TOPLEFT", frame, "TOPLEFT", 310, -45)
preview:SetSize(250, 260)

local previewBackground = preview:CreateTexture(nil, "BACKGROUND")
previewBackground:SetAllPoints()
previewBackground:SetColorTexture(0.025, 0.025, 0.025, 0.8)

local function AddPreviewBorder(point1, point2, width, height)
    local border = preview:CreateTexture(nil, "BORDER")
    border:SetColorTexture(0.35, 0.35, 0.35, 0.8)
    border:SetPoint(point1)
    border:SetPoint(point2)
    if width then
        border:SetWidth(width)
    end
    if height then
        border:SetHeight(height)
    end
end

AddPreviewBorder("TOPLEFT", "TOPRIGHT", nil, 1)
AddPreviewBorder("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
AddPreviewBorder("TOPLEFT", "BOTTOMLEFT", 1, nil)
AddPreviewBorder("TOPRIGHT", "BOTTOMRIGHT", 1, nil)

local previewTitle = preview:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
previewTitle:SetPoint("TOPLEFT", 10, -8)
previewTitle:SetText("Preview")

local previewGridAnchor = CreateFrame("Frame", nil, preview)
previewGridAnchor:SetPoint("TOPLEFT", preview, "TOPLEFT", 8, -32)
previewGridAnchor:SetSize(70, 220)

local previewIcons = {}
for classID = 1, NUM_CLASSES do
    previewIcons[classID] = RaidComp.CreateClassIndicator(previewGridAnchor, classInfo[classID])
end

local rolePreviewTitle = preview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rolePreviewTitle:SetPoint("TOPLEFT", preview, "TOPLEFT", 88, -38)
rolePreviewTitle:SetText("Player Rows")

local rolePreviewData = {
    { name = "Leader", role = "DAMAGER", promotionAtlas = "friends-icon-raidLead" },
    { name = "Assistant", role = "HEALER", promotionAtlas = "friends-icon-raidAssist" },
    { name = "Main Tank", role = "TANK", promotionAtlas = "RaidFrame-Icon-MainTank" },
}

local rolePreviewRows = {}
for index, data in ipairs(rolePreviewData) do
    local row = CreateFrame("Frame", nil, preview)
    row:SetSize(150, 22)
    row:SetPoint("TOPLEFT", rolePreviewTitle, "BOTTOMLEFT", 0, -6 - ((index - 1) * 25))

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.08, 0.08, 0.08, 0.9)

    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("LEFT", row, "LEFT", 40, 0)
    name:SetText(data.name)

    row.roleAnchor = RaidComp.CreateRolePreviewAnchor(row)
    rolePreviewRows[index] = row
end

local slotPreviewRow = CreateFrame("Frame", nil, preview)
slotPreviewRow:SetSize(150, 20)
slotPreviewRow:SetPoint("TOPLEFT", rolePreviewRows[#rolePreviewRows], "BOTTOMLEFT", 0, -5)

local slotPreviewBackground = slotPreviewRow:CreateTexture(nil, "BACKGROUND")
slotPreviewBackground:SetAllPoints()
slotPreviewBackground:SetAtlas("friends-card-raid")
slotPreviewBackground:SetAlpha(0.45)

local slotPreviewText = slotPreviewRow:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
slotPreviewText:SetPoint("CENTER")
slotPreviewText:SetText(EMPTY)

UpdatePreview = function()
    local classCounts = RaidComp.GetRaidClassCounts()
    local visibleIndex = 0

    for classID = 1, NUM_CLASSES do
        local indicator = previewIcons[classID]
        local current = classCounts[classID] or 0
        local required = RaidComp.db.selectedBuffs[classID] and 1 or 0
        local shouldShow = required > 0 and not (RaidComp.db.hidePresent and current >= required)

        if shouldShow then
            visibleIndex = visibleIndex + 1
            RaidComp.PositionClassIndicator(indicator, previewGridAnchor, "TOPLEFT", visibleIndex)
            indicator.text:SetText(RaidComp.FormatClassCount(current, required))
        end

        indicator:SetShown(shouldShow)
    end

    for index, data in ipairs(rolePreviewData) do
        local row = rolePreviewRows[index]
        if RaidComp.db.showRoleIcons ~= false then
            local promotionAtlas = RaidComp.db.showPromoteIcons ~= false and data.promotionAtlas or nil
            RaidComp.SetRolePreviewAnchor(row.roleAnchor, row, data.role, promotionAtlas)
        else
            row.roleAnchor:Hide()
        end
    end

    slotPreviewRow:SetShown(RaidComp.db.showEmptySlots ~= false)
end

frame:SetScript("OnShow", function()
    hideCheck:SetChecked(RaidComp.db.hidePresent)
    for i = 1, NUM_CLASSES do
        if checks[i] and RaidComp.db.selectedBuffs then
            checks[i]:SetChecked(RaidComp.db.selectedBuffs[i])
        end
    end
    showRolesCheck:SetChecked(RaidComp.db.showRoleIcons ~= false)
    promoteCheck:SetChecked(RaidComp.db.showPromoteIcons ~= false)
    UpdateRoleSettingDependencies()
    slotsCheck:SetChecked(RaidComp.db.showEmptySlots ~= false)
    UpdatePreview()
end)

frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:SetScript("OnEvent", function()
    if frame:IsShown() then
        UpdatePreview()
    end
end)

local category = Settings.RegisterCanvasLayoutCategory(frame, "RaidComp")
Settings.RegisterAddOnCategory(category)

SLASH_RAIDCOMP1 = "/rcomp"
SLASH_RAIDCOMP2 = "/raidcomp"
SLASH_RAIDCOMP3 = "/comp"

SlashCmdList["RAIDCOMP"] = function(msg)
    Settings.OpenToCategory(category:GetID())
end
