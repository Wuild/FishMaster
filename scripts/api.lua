local _, ns = ...
local API = {}
ns.API = API

-- Forever uses the Mainline namespaces; keep client-facing calls together.
function API.ItemInfo(item)
    return C_Item.GetItemInfo(item)
end

function API.ItemCount(item)
    return C_Item.GetItemCount(item) or 0
end

function API.SpellName(id)
    return C_Spell.GetSpellName(id)
end

function API.FishingName()
    return PROFESSIONS_FISHING or API.SpellName(7620) or "Fishing"
end

function API.SlotInfo(name)
    return C_PaperDollInfo.GetInventorySlotInfo(name)
end

function API.CursorFits(slotID)
    return C_PaperDollInfo.CursorCanGoInSlot(slotID)
end

function API.FindItem(itemID, includeLocked)
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            if C_Container.GetContainerItemID(bag, slot) == itemID then
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and (includeLocked or not info.isLocked) then return bag, slot end
            end
        end
    end
end

function API.Equip(itemID, slotID)
    if GetInventoryItemID("player", slotID) == itemID then return true end
    if CursorHasItem() or IsInventoryItemLocked(slotID) then return false end
    local bag, slot = API.FindItem(itemID)
    local source
    if bag then
        C_Container.PickupContainerItem(bag, slot)
    else
        -- A locked bag copy may be arriving from the preceding swap. Do not
        -- steal an identical item from a slot that has already been restored.
        if API.FindItem(itemID, true) then return false end
        -- Rings, trinkets and weapons may be in another equipment slot.
        for _, entry in ipairs(ns.slots) do
            if entry.id ~= slotID and GetInventoryItemID("player", entry.id) == itemID
                and not IsInventoryItemLocked(entry.id) then
                source = entry.id
                PickupInventoryItem(source)
                break
            end
        end
    end
    if not CursorHasItem() then return false end
    if not API.CursorFits(slotID) then ClearCursor(); return false end
    PickupInventoryItem(slotID)
    if CursorHasItem() then
        if bag then C_Container.PickupContainerItem(bag, slot)
        elseif source then PickupInventoryItem(source) end
    end
    ClearCursor()
    -- A submitted swap is not necessarily reflected in inventory until later.
    return true
end

function API.EmptySlot(slotID)
    if not GetInventoryItemID("player", slotID) then return true end
    if CursorHasItem() or IsInventoryItemLocked(slotID) then return false end
    -- A general-purpose bag avoids specialty-bag restrictions.
    for bag = 0, NUM_BAG_SLOTS or 4 do
        local free, family = C_Container.GetContainerNumFreeSlots(bag)
        if free > 0 and family == 0 then
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                if not C_Container.GetContainerItemID(bag, slot) then
                    PickupInventoryItem(slotID)
                    if not CursorHasItem() then return false end
                    C_Container.PickupContainerItem(bag, slot)
                    ClearCursor()
                    return true
                end
            end
        end
    end
    return false
end

function API.Profession(requestedName)
    if not requestedName then return nil end
    local requested = requestedName:lower()
    local fishing = requested == "fishing" or requested == API.FishingName():lower()
    -- Primary professions can be nil even when fishing is learned.
    for _, index in pairs({ GetProfessions() }) do
        local name, _, rank, maximum, _, _, skillLine, bonus = GetProfessionInfo(index)
        if name and (name:lower() == requested or (fishing and skillLine == 356)) then
            return name, rank or 0, 0, maximum or 0, bonus or 0, nil
        end
    end
end

function API.IsPole(itemID)
    if not itemID then return false end
    for _, pole in ipairs(ns.poles) do
        if itemID == pole then return true end
    end
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
    return classID == 2 and subclassID == 20
end

-- Slot IDs retain Forever's ranged slot even when Mainline globals are absent.
ns.slots = {
    { name = "HeadSlot", id = 1, label = HEADSLOT, side = "left" },
    { name = "NeckSlot", id = 2, label = NECKSLOT, side = "left" },
    { name = "ShoulderSlot", id = 3, label = SHOULDERSLOT, side = "left" },
    { name = "BackSlot", id = 15, label = BACKSLOT, side = "left" },
    { name = "ChestSlot", id = 5, label = CHESTSLOT, side = "left" },
    { name = "ShirtSlot", id = 4, label = SHIRTSLOT, side = "left" },
    { name = "TabardSlot", id = 19, label = TABARDSLOT, side = "left" },
    { name = "WristSlot", id = 9, label = WRISTSLOT, side = "left" },
    { name = "HandsSlot", id = 10, label = HANDSSLOT, side = "right" },
    { name = "WaistSlot", id = 6, label = WAISTSLOT, side = "right" },
    { name = "LegsSlot", id = 7, label = LEGSSLOT, side = "right" },
    { name = "FeetSlot", id = 8, label = FEETSLOT, side = "right" },
    { name = "Finger0Slot", id = 11, label = FINGER0SLOT, side = "right" },
    { name = "Finger1Slot", id = 12, label = FINGER1SLOT, side = "right" },
    { name = "Trinket0Slot", id = 13, label = TRINKET0SLOT, side = "right" },
    { name = "Trinket1Slot", id = 14, label = TRINKET1SLOT, side = "right" },
    { name = "MainHandSlot", id = 16, label = MAINHANDSLOT, side = "bottom" },
    { name = "SecondaryHandSlot", id = 17, label = SECONDARYHANDSLOT, side = "bottom" },
    { name = "RangedSlot", id = 18, label = RANGEDSLOT or "Ranged", side = "bottom" },
    { name = "AmmoSlot", id = 0, label = AMMOSLOT or "Ammo", side = "bottom" },
}

function API.AvailableSlots()
    local result = {}
    for _, slot in ipairs(ns.slots) do
        if C_PaperDollInfo.IsInventorySlotEnabled(slot.name) then
            table.insert(result, slot)
        end
    end
    return result
end
