local slotGroups = setmetatable({}, { __mode = "k" })

local PLAYERS_PER_RAID_GROUP = 5
local PLAYER_ROW_HEIGHT = 20
local PLAYER_ROW_SPACING = 1
local GROUP_INSET = 4
local FIRST_ROW_Y_OFFSET = -28

local function CreateSlot(groupFrame, slotIndex)
    local slot = CreateFrame("Frame", nil, groupFrame)
    local yOffset = FIRST_ROW_Y_OFFSET - ((slotIndex - 1) * (PLAYER_ROW_HEIGHT + PLAYER_ROW_SPACING))
    slot:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", GROUP_INSET, yOffset)
    slot:SetPoint("TOPRIGHT", groupFrame, "TOPRIGHT", -GROUP_INSET, yOffset)
    slot:SetHeight(PLAYER_ROW_HEIGHT)
    slot:SetFrameLevel(groupFrame:GetFrameLevel() + 1)

    local background = slot:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetAtlas("friends-card-raid")
    background:SetAlpha(0.45)

    local label = slot:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    label:SetPoint("CENTER")
    label:SetText(EMPTY)

    return slot
end

local function GetSlots(groupFrame)
    local slots = slotGroups[groupFrame]
    if slots then
        return slots
    end

    slots = {}
    for slotIndex = 1, PLAYERS_PER_RAID_GROUP do
        slots[slotIndex] = CreateSlot(groupFrame, slotIndex)
    end
    slotGroups[groupFrame] = slots
    return slots
end

local function HideSlots(slots)
    for _, slot in ipairs(slots) do
        slot:Hide()
    end
end

local function UpdateSlots()
    local raidFrame = SocialUIFrame and SocialUIFrame.RaidFrame
    local db = RaidComp and RaidComp.db or {}
    if db.showEmptySlots == false or not IsInRaid() or not raidFrame or type(raidFrame.groups) ~= "table" then
        for _, slots in pairs(slotGroups) do
            HideSlots(slots)
        end
        return
    end

    local activeGroups = {}
    for _, groupFrame in ipairs(raidFrame.groups) do
        activeGroups[groupFrame] = true
        local slots = GetSlots(groupFrame)
        local numPlayers = groupFrame.numPlayers or 0
        for slotIndex, slot in ipairs(slots) do
            slot:SetShown(slotIndex > numPlayers)
        end
    end

    for groupFrame, slots in pairs(slotGroups) do
        if not activeGroups[groupFrame] then
            HideSlots(slots)
        end
    end
end

local updateQueued = false
local function QueueUpdate()
    if updateQueued then
        return
    end

    updateQueued = true
    C_Timer.After(0, function()
        updateQueued = false
        UpdateSlots()
    end)
end

local raidFrameHooked = false
local function InitializeForSocialUI()
    local raidFrame = SocialUIFrame and SocialUIFrame.RaidFrame
    if not raidFrame or raidFrameHooked then
        return
    end

    raidFrameHooked = true
    raidFrame:HookScript("OnShow", QueueUpdate)
    hooksecurefunc(raidFrame, "UpdateContents", QueueUpdate)
    QueueUpdate()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event, addonLoaded)
    if event == "ADDON_LOADED" then
        if addonLoaded == "Blizzard_SocialUI" then
            InitializeForSocialUI()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        InitializeForSocialUI()
        QueueUpdate()
    else
        QueueUpdate()
    end
end)

InitializeForSocialUI()

RaidComp.UpdateSlotDisplay = QueueUpdate
