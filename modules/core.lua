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
