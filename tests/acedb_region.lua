-- Exercise the bundled libraries themselves: a database mock misses load errors.
GetRealmName = function() return "Forever" end
UnitName = function() return "Angler" end
UnitClass = function() return "Warrior", "WARRIOR" end
UnitRace = function() return "Human", "Human" end
UnitFactionGroup = function() return "Alliance" end
GetLocale = function() return "enUS" end
CreateFrame = function()
    return {
        RegisterEvent = function() end,
        SetScript = function(self, event, callback) self[event] = callback end,
    }
end

local function loadLibraries()
    LibStub = nil
    dofile("libraries/LibStub/LibStub.lua")
    dofile("libraries/CallbackHandler-1.0/CallbackHandler-1.0.lua")
    dofile("libraries/AceDB-3.0/AceDB-3.0.lua")
    return LibStub("AceDB-3.0")
end

local defaults = {
    char = { audio = { enabled = false }, outfit = {}, loot = {}, bobberKey = "" },
    profile = { minimap = { hide = false } },
    factionrealmregion = { marker = "default" },
}
local cases = {
    { label = "nil region", expected = "UNKNOWN" },
    { label = "zero region", id = 0, expected = "UNKNOWN" },
    { label = "unknown region", id = 99, expected = "UNKNOWN" },
    { label = "missing region API", missing = true, expected = "UNKNOWN" },
    { label = "US", id = 1, expected = "US" },
    { label = "KR", id = 2, expected = "KR" },
    { label = "EU", id = 3, expected = "EU" },
    { label = "TW", id = 4, expected = "TW" },
    { label = "CN", id = 5, expected = "CN" },
}
for _, case in ipairs(cases) do
    GetCurrentRegion = not case.missing and function() return case.id end or nil
    local originalRegionAPI = GetCurrentRegion
    local outfit = { MainHandSlot = 6256 }
    local loot = { { item = "Trout", quantity = 7 } }
    FishMasterSettings = {
        char = { ["Angler - Forever"] = { outfit = outfit, loot = loot, audio = { enabled = true } } },
        profileKeys = { ["Angler - Forever"] = "Existing profile" },
        profiles = { ["Existing profile"] = { minimap = { hide = true } } },
    }
    local library = loadLibraries()
    local db = library:New("FishMasterSettings", defaults, true)
    assert(db.keys.char == "Angler - Forever")
    assert(db.keys.factionrealmregion == "Alliance - Forever - " .. case.expected)
    assert(db.char.outfit == outfit and db.char.loot == loot)
    assert(db.char.audio.enabled and db.char.bobberKey == "")
    assert(db:GetCurrentProfile() == "Existing profile" and db.profile.minimap.hide)
    assert(GetCurrentRegion == originalRegionAPI)
    db.factionrealmregion.marker = "saved"
    -- Simulate logout and reload to check defaults cleanup and stable keys.
    library.frame.OnEvent(library.frame, "PLAYER_LOGOUT")
    local reloaded = loadLibraries():New("FishMasterSettings", defaults, true)
    assert(reloaded.factionrealmregion.marker == "saved")
    assert(reloaded.char.outfit.MainHandSlot == 6256 and reloaded.char.loot[1].quantity == 7)
    assert(reloaded.char.audio.enabled and reloaded.profile.minimap.hide)
    print("PASS AceDB " .. case.label .. " initialization and saved-data reload")
end
print(#cases .. " bundled AceDB region checks passed")
