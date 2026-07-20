RaidComp = RaidComp or {}

local defaults = {
    selectedBuffs = {
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
    },
    hidePresent = false,
    showRoleIcons = true,
    showPromoteIcons = true,
    showEmptySlots = true,
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

local raidFrameUpdaters = {}
local updateQueued = false
local hookedRaidFrame

local function RunRaidFrameUpdaters()
    updateQueued = false
    local raidFrame = SocialUIFrame and SocialUIFrame.RaidFrame

    for _, updater in ipairs(raidFrameUpdaters) do
        xpcall(function()
            updater(raidFrame)
        end, geterrorhandler())
    end
end

function RaidComp.RequestRaidFrameUpdate()
    if updateQueued then
        return
    end

    updateQueued = true
    C_Timer.After(0, RunRaidFrameUpdaters)
end

function RaidComp.RegisterRaidFrameUpdater(updater)
    table.insert(raidFrameUpdaters, updater)
    RaidComp.RequestRaidFrameUpdate()
end

local function InitializeSocialRaidFrame()
    local raidFrame = SocialUIFrame and SocialUIFrame.RaidFrame
    if not raidFrame or raidFrame == hookedRaidFrame then
        return raidFrame ~= nil
    end

    hookedRaidFrame = raidFrame
    raidFrame:HookScript("OnShow", RaidComp.RequestRaidFrameUpdate)
    hooksecurefunc(raidFrame, "UpdateContents", RaidComp.RequestRaidFrameUpdate)
    RaidComp.RequestRaidFrameUpdate()
    return true
end

local lifecycleFrame = CreateFrame("Frame")
lifecycleFrame:RegisterEvent("ADDON_LOADED")
lifecycleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
lifecycleFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
lifecycleFrame:RegisterEvent("RAID_ROSTER_UPDATE")
lifecycleFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
lifecycleFrame:RegisterEvent("ROLE_CHANGED_INFORM")
lifecycleFrame:RegisterEvent("PARTY_LEADER_CHANGED")
lifecycleFrame:SetScript("OnEvent", function(self, event, addonLoaded)
    if event == "ADDON_LOADED" then
        if addonLoaded ~= "Blizzard_SocialUI" and addonLoaded ~= "Blizzard_RaidFrame" then
            return
        end

        if InitializeSocialRaidFrame() then
            self:UnregisterEvent("ADDON_LOADED")
        end
        return
    end

    InitializeSocialRaidFrame()
    RaidComp.RequestRaidFrameUpdate()
end)

if InitializeSocialRaidFrame() then
    lifecycleFrame:UnregisterEvent("ADDON_LOADED")
end
