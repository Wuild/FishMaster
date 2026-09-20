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
local deferred, pendingInventory, pendingUntil, casting, inventoryLocked
local cvars = {}
local names = { [6256] = "Fishing Pole", [6529] = "Shiny Bauble", [6533] = "Attractor" }
local function reset()
    FishMaster.db = copy(ns.configsDefaults)
    equipped, bags, locked = { [16] = 100, [17] = 101 }, { [0] = { 6256, 6529, 6533 } }, {}
    combat, cursor, now, fishingLoot = false, nil, 100, true
    deferred, pendingInventory, pendingUntil, casting, inventoryLocked = false, nil, nil, nil, {}
    FishMaster.gearSwap = nil
    messages = {}
    ns.session, ns.lootRecorded, ns.isCasting = {}, false, false
    ns.refreshPending, ns.lootPending = false, false
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
    IsEquippedItem = function(id)
        for _, item in pairs(equipped) do if item == id then return true end end
        return false
    end,
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
}
C_PaperDollInfo = {
    GetTemporaryEnchantmentInfo = function() return nil end,
    CursorCanGoInSlot = function() return true end,
}
GetInventoryItemID = function(_, slot) return (pendingInventory or equipped)[slot] end
IsInventoryItemLocked = function(slot) return inventoryLocked[slot] or pendingInventory ~= nil end
CursorHasItem = function() return cursor ~= nil end
PickupInventoryItem = function(slot)
    if deferred and not pendingInventory then
        pendingInventory, pendingUntil = copy(equipped), now + .3
    end
    if slot == 16 and cursor == 6256 then assert(not equipped[17], "Off-hand must be stowed before the pole") end
    cursor, equipped[slot] = equipped[slot], cursor
end
ClearCursor = function() assert(not cursor, "Cursor should be empty after a successful operation") end
InCombatLockdown = function() return combat end
UnitAffectingCombat = function() return combat end
UnitCastingInfo = function() return casting end
UnitChannelInfo = function() return nil end
C_CVar = { GetCVar = function(key) return cvars[key] end, SetCVar = function(key, value) cvars[key] = value end }
IsFishingLoot = function() return fishingLoot end
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
-- Exercise the real equipment-event refresh path, with only the UI stubbed.
for _, module in ipairs({ "toolbar", "interaction", "tracker", "equipment" }) do
    FishMaster[module] = { Refresh = function() end }
end
local tests = 0
local function step()
    now = now + .1
    if pendingUntil and now >= pendingUntil then pendingInventory, pendingUntil = nil, nil end
    FishMaster:AdvanceOutfitSwap()
end
local function settle()
    for _ = 1, 400 do
        if not FishMaster.gearSwap then return end
        step()
    end
    error("Outfit operation did not complete or time out")
end
local function toggle()
    FishMaster:Toggle()
    settle()
end
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
    toggle()
    assert(equipped[16] == 6256 and equipped[17] == nil and equipped[1] == 200)
    assert(FishMaster.db.char.storedOutfit.HeadSlot == false)
    toggle()
    assert(equipped[16] == 100 and equipped[17] == 101 and equipped[1] == nil)
    assert(not FishMaster.db.char.enabled and next(FishMaster.db.char.storedOutfit) == nil)
end)
test("missing gear fails before saving or changing equipment", function()
    FishMaster.db.char.outfit.HeadSlot = 9999
    toggle()
    assert(not FishMaster.db.char.enabled)
    assert(equipped[16] == 100)
    assert(next(FishMaster.db.char.storedOutfit) == nil)
end)
test("failed restoration retains the snapshot for retry", function()
    toggle()
    for slot, item in pairs(bags[0]) do if item == 100 then bags[0][slot] = nil end end
    toggle()
    assert(FishMaster.db.char.enabled)
    assert(FishMaster.db.char.storedOutfit.MainHandSlot == 100)
    bags[0][freeSlot()] = 100
    toggle()
    assert(not FishMaster.db.char.enabled and equipped[16] == 100)
end)
test("combat does not mutate outfit state", function()
    combat = true
    toggle()
    assert(not FishMaster.db.char.enabled and equipped[16] == 100)
end)
test("delayed inventory updates finish in order and double toggles keep the snapshot", function()
    deferred = true
    FishMaster.db.char.outfit.HeadSlot = 200
    bags[0][4] = 200
    FishMaster:Toggle()
    assert(FishMaster.gearSwap and GetInventoryItemID("player", 16) == 100)
    FishMaster:Toggle()
    assert(FishMaster.db.char.storedOutfit.MainHandSlot == 100)
    settle()
    assert(equipped[16] == 6256 and not equipped[17] and equipped[1] == 200)
    toggle()
    assert(equipped[16] == 100 and equipped[17] == 101 and not equipped[1])
    assert(not FishMaster.db.char.enabled)
end)
test("locked pole waits for unlock without stopping after removing the off-hand", function()
    locked[1] = true
    FishMaster:Toggle()
    step()
    assert(FishMaster.gearSwap and equipped[16] == 100 and not equipped[17])
    locked[1] = false
    settle()
    assert(equipped[16] == 6256)
end)
test("full bags preserve equipment and the recovery snapshot", function()
    for slot = 4, 20 do bags[0][slot] = 999 end
    toggle()
    assert(equipped[16] == 100 and equipped[17] == 101)
    assert(FishMaster.db.char.storedOutfit.MainHandSlot == 100)
    assert(messages[#messages] == locale["error.equip"])
    bags[0][20] = nil
    toggle()
    assert(not FishMaster.db.char.enabled)
    toggle()
    assert(equipped[16] == 6256)
end)
test("inventory-to-inventory swaps restore rings in the correct slots", function()
    equipped[11], equipped[12] = 201, 202
    FishMaster.db.char.outfit.Finger0Slot = 202
    FishMaster.db.char.outfit.Finger1Slot = 201
    toggle()
    assert(equipped[11] == 202 and equipped[12] == 201)
    toggle()
    assert(equipped[11] == 201 and equipped[12] == 202)
end)
test("duplicate rings require two copies before changing any equipment", function()
    bags[0][4] = 201
    FishMaster.db.char.outfit.Finger0Slot = 201
    FishMaster.db.char.outfit.Finger1Slot = 201
    toggle()
    assert(not FishMaster.db.char.enabled and equipped[16] == 100)
    bags[0][5] = 201
    toggle()
    assert(equipped[11] == 201 and equipped[12] == 201)
    toggle()
    assert(not equipped[11] and not equipped[12])
end)
test("a locked duplicate is not stolen from a completed equipment slot", function()
    equipped[11], bags[0][4], locked[4] = 201, 201, true
    FishMaster.db.char.outfit.Finger0Slot = 201
    FishMaster.db.char.outfit.Finger1Slot = 201
    FishMaster:Toggle()
    for _ = 1, 10 do step() end
    assert(equipped[11] == 201 and not equipped[12] and FishMaster.gearSwap)
    locked[4] = false
    settle()
    assert(equipped[11] == 201 and equipped[12] == 201)
end)
test("casting guard uses live state rather than a stale spell event", function()
    ns.isCasting = true
    toggle()
    assert(equipped[16] == 6256)
    casting = "Fishing"
    toggle()
    assert(equipped[16] == 6256 and messages[#messages] == locale["error.casting"])
end)
test("combat interrupts an in-flight swap without losing recovery data", function()
    deferred = true
    FishMaster:Toggle()
    combat = true
    step()
    assert(not FishMaster.gearSwap and FishMaster.db.char.storedOutfit.MainHandSlot == 100)
    combat = false
    step(); step(); step()
    toggle()
    assert(equipped[16] == 100 and equipped[17] == 101)
end)
test("audio changes preserve original values across refresh and restore", function()
    local before = copy(cvars)
    FishMaster.db.char.audio.enabled = true
    FishMaster.db.char.audio.force = true
    toggle()
    FishMaster.db.char.audio.volume = .2
    FishMaster:SetAudio()
    assert(cvars.Sound_MasterVolume == "0.2")
    toggle()
    for key, value in pairs(before) do assert(cvars[key] == value, key) end
end)
test("manual pole removal restores audio and the next toggle equips again", function()
    local before = copy(cvars)
    FishMaster.db.char.audio.enabled = true
    FishMaster.db.char.audio.force = true
    toggle()
    assert(cvars.Sound_MasterVolume == "1")
    assert(ns.API.Equip(100, 16))
    FishMaster:Refresh()
    assert(not FishMaster.db.char.enabled and not FishMaster:ShouldRestoreOutfit())
    for key, value in pairs(before) do assert(cvars[key] == value, key) end
    assert(next(FishMaster.db.char.defaultAudio) == nil)
    toggle()
    assert(equipped[16] == 6256 and FishMaster.db.char.enabled)
    assert(FishMaster.db.char.storedOutfit.MainHandSlot == 100)
    toggle()
    assert(equipped[16] == 100)
    for key, value in pairs(before) do assert(cvars[key] == value, key) end
end)
test("manually equipping a pole enables audio and can be toggled off without a snapshot", function()
    local before = copy(cvars)
    FishMaster.db.char.audio.enabled = true
    assert(ns.API.EmptySlot(17))
    assert(ns.API.Equip(6256, 16))
    FishMaster:Refresh()
    assert(FishMaster.db.char.enabled and FishMaster:ShouldRestoreOutfit())
    assert(cvars.Sound_MasterVolume == "1")
    assert(next(FishMaster.db.char.storedOutfit) == nil)
    toggle()
    assert(not equipped[16] and not FishMaster.db.char.enabled)
    for key, value in pairs(before) do assert(cvars[key] == value, key) end
end)
test("manual weapon changes restore audio during combat", function()
    local before = copy(cvars)
    FishMaster.db.char.audio.enabled = true
    toggle()
    combat = true
    assert(ns.API.Equip(100, 16))
    FishMaster:Refresh()
    assert(not FishMaster.db.char.enabled and ns.refreshPending)
    for key, value in pairs(before) do assert(cvars[key] == value, key) end
end)
test("refresh repairs stale saved enabled and audio state with no pole", function()
    local before = copy(cvars)
    FishMaster.db.char.enabled = true
    FishMaster.db.char.audio.enabled = true
    FishMaster.db.char.defaultAudio = copy(before)
    for key in pairs(cvars) do cvars[key] = "1" end
    FishMaster:Refresh()
    assert(not FishMaster.db.char.enabled and not FishMaster:ShouldRestoreOutfit())
    for key, value in pairs(before) do assert(cvars[key] == value, key) end
end)
test("failed restoration after removing the pole keeps recovery but stops fishing audio", function()
    local before = copy(cvars)
    FishMaster.db.char.audio.enabled = true
    equipped[1], bags[0][4] = 300, 200
    FishMaster.db.char.outfit.HeadSlot = 200
    toggle()
    local _, oldHatSlot = ns.API.FindItem(300)
    locked[oldHatSlot] = true
    toggle()
    assert(equipped[16] == 100 and equipped[1] == 200)
    assert(not FishMaster.db.char.enabled and FishMaster.db.char.restorePending)
    assert(FishMaster:ShouldRestoreOutfit())
    assert(FishMaster.db.char.storedOutfit.HeadSlot == 300)
    for key, value in pairs(before) do assert(cvars[key] == value, key) end
    locked[oldHatSlot] = false
    toggle()
    assert(equipped[16] == 100 and equipped[1] == 300)
    assert(not FishMaster.db.char.restorePending and next(FishMaster.db.char.storedOutfit) == nil)
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
test("late loot links retry only unresolved slots", function()
    local originalLink = GetLootSlotLink
    GetLootSlotLink = function(index) if index == 1 then return originalLink(index) end end
    FishMaster:OnLoot()
    local _, count = FishMaster:GetCatches(true)
    assert(count == 2 and ns.lootPending)
    FishMaster:OnLoot()
    local _, repeated = FishMaster:GetCatches(true)
    assert(repeated == 2)
    GetLootSlotLink = originalLink
    FishMaster:OnLoot()
    local _, completed = FishMaster:GetCatches(true)
    assert(completed == 3 and not ns.lootPending)
    FishMaster:OnLoot()
    local _, final = FishMaster:GetCatches(false)
    assert(final == 3)
end)

test("late loot names and quality are retried", function()
    local originalInfo = GetLootSlotInfo
    GetLootSlotInfo = function(index)
        if index == 1 then return 123, nil, 2, nil, nil, false, false end
        return originalInfo(index)
    end
    FishMaster:OnLoot()
    assert(ns.lootPending)
    GetLootSlotInfo = originalInfo
    FishMaster:OnLoot()
    local _, count = FishMaster:GetCatches(true)
    assert(count == 3 and not ns.lootPending)
end)

test("outfit status checks saved pieces and ignores incompatible offhand", function()
    equipped[16], equipped[17] = 6256, nil
    assert(not FishMaster:IsOutfitEquipped())
    FishMaster.db.char.outfit = { MainHandSlot = 6256, HeadSlot = 200, SecondaryHandSlot = 101 }
    assert(not FishMaster:IsOutfitEquipped())
    equipped[1] = 200
    assert(FishMaster:IsOutfitEquipped())
    equipped[16] = 100
    assert(not FishMaster:IsOutfitEquipped())
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
reset() -- Leave a clean fixture for the UI smoke suite.
print(tests .. " core regression checks passed")
return ns
