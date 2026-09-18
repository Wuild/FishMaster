-- Run from the repository root: lua tests/core.lua
local ns = {}
local locale = {}
local messages = {}
FishMaster = {}
LibStub = function(library)
    if library == "AceAddon-3.0" then return { NewAddon = function() return FishMaster end } end
    if library == "AceLocale-3.0" then
        return { GetLocale = function() return locale end, NewLocale = function() return locale end }
    end
    error("Unexpected library " .. library)
end
C_AddOns = { GetAddOnMetadata = function() return "test" end }
assert(loadfile("scripts/configs.lua"))("FishMaster", ns)
assert(loadfile("locales/enUS.lua"))("FishMaster", ns)
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, entry in pairs(value) do result[key] = copy(entry) end
    return result
end
local equipped, bags, locked, combat, cursor, now, fishingLoot, loot
local cvars = {}
local names = { [6256] = "Fishing Pole", [6529] = "Shiny Bauble", [6533] = "Attractor" }
local function reset()
    FishMaster.db = copy(ns.configsDefaults)
    equipped, bags, locked = { [16] = 100, [17] = 101 }, { [0] = { 6256, 6529, 6533 } }, {}
    combat, cursor, now, fishingLoot = false, nil, 100, true
    ns.session, ns.lootRecorded, ns.isCasting = {}, false, false
    loot = { { id = 55, item = "Trout", quantity = 2, quality = 1 },
        { id = 56, item = "Boot", quantity = 1, quality = 0 } }
    cvars = { Sound_EnableAllSound = "0", Sound_EnableSFX = "0", Sound_EnableAmbience = "1",
        Sound_MasterVolume = ".7", Sound_SFXVolume = ".5", Sound_MusicVolume = ".4" }
end
local function freeSlot()
    for i = 1, 20 do if not bags[0][i] then return i end end
end
NUM_BAG_SLOTS = 0
PROFESSIONS_FISHING = "Fishing"
GetProfessions = function() return nil, nil, nil, 4 end
GetProfessionInfo = function() return "Fishing", 123, 100, 150, 1, 0, 356, 20 end
C_Spell = { GetSpellName = function(id) return id == 7620 and "Fishing" or "Other spell" end }
C_Container = {
    GetContainerNumSlots = function() return 20 end,
    GetContainerItemID = function(bag, slot) return bags[bag][slot] end,
    GetContainerItemInfo = function(bag, slot)
        return bags[bag][slot] and { itemID = bags[bag][slot], isLocked = locked[slot] }
    end,
    GetContainerNumFreeSlots = function()
        local n = 0
        for i = 1, 20 do if not bags[0][i] then n = n + 1 end end
        return n, 0
    end,
    PickupContainerItem = function(bag, slot)
        cursor, bags[bag][slot] = bags[bag][slot], cursor
    end,
}
C_Item = {
    GetItemInfo = function(id) return names[id] or ("Item " .. id), "item:" .. id, 1, 1, 1, "", "", 1, "", 123 end,
    GetItemCount = function(id)
        local n = 0
        for _, item in pairs(bags[0]) do if item == id then n = n + 1 end end
        for _, item in pairs(equipped) do if item == id then n = n + 1 end end
        return n
    end,
    GetItemInfoInstant = function(id)
        return id, "", "", id == 6256 and "INVTYPE_2HWEAPON" or "INVTYPE_WEAPON", 123, 2, id == 6256 and 20 or 0
    end,
    EquipItemByName = function(id, slot)
        for bagSlot, item in pairs(bags[0]) do
            if item == id then
                equipped[slot], bags[0][bagSlot] = id, equipped[slot]
                if slot == 16 and id == 6256 and equipped[17] then
                    local empty = freeSlot()
                    assert(empty, "No space for off-hand mock")
                    bags[0][empty], equipped[17] = equipped[17], nil
                end
                return
            end
        end
    end,
}
C_PaperDollInfo = { GetTemporaryEnchantmentInfo = function() return nil end }
GetInventoryItemID = function(_, slot) return equipped[slot] end
CursorHasItem = function() return cursor ~= nil end
PickupInventoryItem = function(slot) cursor, equipped[slot] = equipped[slot], cursor end
ClearCursor = function() assert(not cursor, "Cursor should be empty after a successful operation") end
InCombatLockdown = function() return combat end
UnitAffectingCombat = function() return combat end
C_CVar = { GetCVar = function(key) return cvars[key] end, SetCVar = function(key, value) cvars[key] = value end }
C_Loot = { IsFishingLoot = function() return fishingLoot end }
GetNumLootItems = function() return #loot end
GetLootSlotLink = function(index) return "item:" .. loot[index].id end
GetLootSlotInfo = function(index)
    local item = loot[index]
    return 123, item.item, item.quantity, nil, item.quality, false, false
end
GetMinimapZoneText = function() return "Lake" end
GetTime = function() return now end
FishMaster.Print = function(_, message) table.insert(messages, message) end
assert(loadfile("scripts/api.lua"))("FishMaster", ns)
assert(loadfile("scripts/methods.lua"))("FishMaster", ns)
assert(loadfile("scripts/main.lua"))("FishMaster", ns)
FishMaster.Refresh = function() end
local tests = 0
local function test(label, fn)
    reset()
    fn()
    tests = tests + 1
    print("PASS " .. label)
end

test("missing legacy globals are not needed for item and skill lookup", function()
    assert(GetItemInfo == nil and GetSpellInfo == nil and GetNumSkillLines == nil)
    assert(FishMaster:GetProfessionLevel("Fishing") == 120)
    assert(FishMaster:FindBestPole() == 6256)
end)
test("lures respect skill and lowest/strongest preference", function()
    assert(FishMaster:FindBestLure().item == 6529)
    FishMaster.db.char.lowestLure = false
    assert(FishMaster:FindBestLure().item == 6533)
    GetProfessionInfo = function() return "Fishing", 123, 1, 75, 1, 0, 356, 0 end
    assert(FishMaster:FindBestLure().item == 6529)
    GetProfessionInfo = function() return "Fishing", 123, 100, 150, 1, 0, 356, 20 end
end)
test("bag search skips locked items", function()
    locked[1] = true
    assert(ns.API.FindItem(6256) == nil)
end)
test("equip and restore main/off-hand and originally empty slots", function()
    FishMaster.db.char.outfit.HeadSlot = 200
    bags[0][4] = 200
    FishMaster:Toggle()
    assert(equipped[16] == 6256 and equipped[17] == nil and equipped[1] == 200)
    assert(FishMaster.db.char.storedOutfit.HeadSlot == false)
    FishMaster:Toggle()
    assert(equipped[16] == 100 and equipped[17] == 101 and equipped[1] == nil)
    assert(not FishMaster.db.char.enabled and next(FishMaster.db.char.storedOutfit) == nil)
end)
test("missing gear fails before saving or changing equipment", function()
    FishMaster.db.char.outfit.HeadSlot = 9999
    FishMaster:Toggle()
    assert(not FishMaster.db.char.enabled)
    assert(equipped[16] == 100)
    assert(next(FishMaster.db.char.storedOutfit) == nil)
end)
test("failed restoration retains the snapshot for retry", function()
    FishMaster:Toggle()
    for slot, item in pairs(bags[0]) do if item == 100 then bags[0][slot] = nil end end
    FishMaster:Toggle()
    assert(FishMaster.db.char.enabled)
    assert(FishMaster.db.char.storedOutfit.MainHandSlot == 100)
    bags[0][freeSlot()] = 100
    FishMaster:Toggle()
    assert(not FishMaster.db.char.enabled and equipped[16] == 100)
end)
test("combat does not mutate outfit state", function()
    combat = true
    FishMaster:Toggle()
    assert(not FishMaster.db.char.enabled and equipped[16] == 100)
end)
test("audio changes preserve original values across refresh and restore", function()
    local before = copy(cvars)
    FishMaster.db.char.audio.enabled = true
    FishMaster.db.char.audio.force = true
    FishMaster:Toggle()
    FishMaster.db.char.audio.volume = .2
    FishMaster:SetAudio()
    assert(cvars.Sound_MasterVolume == "0.2")
    FishMaster:Toggle()
    for key, value in pairs(before) do assert(cvars[key] == value, key) end
end)
test("LOOT_READY and LOOT_OPENED count the same catch once", function()
    FishMaster:OnLoot()
    FishMaster:OnLoot()
    local entries, count = FishMaster:GetCatches(true)
    assert(#entries == 2 and count == 3)
    local filtered, filteredCount = FishMaster:GetCatches(true, "Lake", true)
    assert(#filtered == 1 and filteredCount == 2)
    ns.lootRecorded = false
    FishMaster:OnLoot()
    local _, updated = FishMaster:GetCatches(false)
    assert(updated == 6)
end)
test("ordinary loot is ignored", function()
    fishingLoot = false
    FishMaster:OnLoot()
    assert(#ns.session == 0)
end)
test("old catches and settings survive migration", function()
    FishMaster.db.char.firstRun = false
    FishMaster.db.char.hideTrash = false
    FishMaster.db.char.loot = { { item = "Old catch", quantity = 9, quality = 1, zone = "Old zone" } }
    FishMaster.db.char.outfit.HeadSlot = 333
    FishMaster:MigrateSettings()
    assert(FishMaster.db.char.tracker.hideTrash == false)
    assert(FishMaster.db.char.outfit.HeadSlot == 333)
    local _, total = FishMaster:GetCatches(false)
    assert(total == 9)
end)
print(tests .. " core regression checks passed")
return ns
