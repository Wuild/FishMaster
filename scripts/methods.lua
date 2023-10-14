local name, _fish = ...;
local Locale = LibStub("AceLocale-3.0"):GetLocale(name, true)

FishMaster.slotInfo = {
    [1] = { name = "HeadSlot", tooltip = HEADSLOT, id = INVSLOT_HEAD },
    [2] = { name = "NeckSlot", tooltip = NECKSLOT, id = INVSLOT_NECK },
    [3] = { name = "ShoulderSlot", tooltip = SHOULDERSLOT, id = INVSLOT_SHOULDER },
    [4] = { name = "BackSlot", tooltip = BACKSLOT, id = INVSLOT_BACK },
    [5] = { name = "ChestSlot", tooltip = CHESTSLOT, id = INVSLOT_CHEST },
    [6] = { name = "ShirtSlot", tooltip = SHIRTSLOT, id = INVSLOT_BODY },
    [7] = { name = "TabardSlot", tooltip = TABARDSLOT, id = INVSLOT_TABARD },
    [8] = { name = "WristSlot", tooltip = WRISTSLOT, id = INVSLOT_WRIST },
    [9] = { name = "HandsSlot", tooltip = HANDSSLOT, id = INVSLOT_HAND },
    [10] = { name = "WaistSlot", tooltip = WAISTSLOT, id = INVSLOT_WAIST },
    [11] = { name = "LegsSlot", tooltip = LEGSSLOT, id = INVSLOT_LEGS },
    [12] = { name = "FeetSlot", tooltip = FEETSLOT, id = INVSLOT_FEET },
    [13] = { name = "Finger0Slot", tooltip = FINGER0SLOT, id = INVSLOT_FINGER1 },
    [14] = { name = "Finger1Slot", tooltip = FINGER1SLOT, id = INVSLOT_FINGER2 },
    [15] = { name = "Trinket0Slot", tooltip = TRINKET0SLOT, id = INVSLOT_TRINKET1 },
    [16] = { name = "Trinket1Slot", tooltip = TRINKET1SLOT, id = INVSLOT_TRINKET2 },
    [17] = { name = "MainHandSlot", tooltip = MAINHANDSLOT, id = INVSLOT_MAINHAND },
    [18] = { name = "SecondaryHandSlot", tooltip = SECONDARYHANDSLOT, id = INVSLOT_OFFHAND },
    [19] = { name = "RangedSlot", tooltip = RANGEDSLOT, id = INVSLOT_RANGED },
    [20] = { name = "AmmoSlot", tooltip = AMMOSLOT, id = INVSLOT_AMMO },
}

function FishMaster:translate(key, ...)
    local arg = { ... };

    if Locale[key] == nil then
        return key
    end

    for i, v in ipairs(arg) do
        arg[i] = tostring(v);
    end
    return string.format(Locale[key], unpack(arg))
end

function FishMaster:TableLength(T)
    local count = 0
    if T then
        for _ in pairs(T) do
            count = count + 1
        end
    end
    return count
end

function FishMaster:TableFilter(t, filterIter)
    local out = {}

    for k, v in pairs(t) do
        if filterIter(v, k, t) then
            out[k] = v;
        end
    end

    return out
end

function FishMaster:translate(key, ...)
    local arg = { ... };

    if Locale[key] == nil then
        return key
    end

    for i, v in ipairs(arg) do
        arg[i] = tostring(v);
    end
    return string.format(Locale[key], unpack(arg))
end

function FishMaster:IsInCombat()
    return InCombatLockdown() or UnitAffectingCombat("player") or UnitAffectingCombat("pet")
end

function FishMaster:IsPoleEquipped()
    local mainHandID = GetInventoryItemID("player", INVSLOT_MAINHAND);
    for key, pole in pairs(FishMaster.poles) do
        if pole == mainHandID then
            return true;
        end
    end
    return false;
end

function FishMaster:GetCurrentPole(id)
    for key, item in pairs(FishMaster.poles) do
        if item == id then
            return FishMaster.poles[key]
        end
    end
    return nil;
end

function FishMaster:FindLure(item)
    for key, lure in pairs(FishMaster.lures) do
        if lure.item == item then
            return lure;
        end
    end
    return nil;
end

function FishMaster:FindBestLure()
    for key, lure in pairs(FishMaster.lures) do
        local itemID = self:FindItemInBags(lure.item);
        local count = GetItemCount(lure.item);
        if itemID and count > 0 then
            return lure;
        end
    end
    return nil;
end

function FishMaster:FindItemInBags(itemID)
    for i = 0, NUM_BAG_SLOTS do
        for z = 1, C_Container.GetContainerNumSlots(i) do
            if C_Container.GetContainerItemID(i, z) == itemID then
                return itemID, i, z
            end
        end
    end
    return nil, nil, nil
end

function FishMaster:IsLured()
    if not self:IsPoleEquipped() then
        return false, nil;
    end
    local mainHand, mainHandExpires, _, mainHandEnchantID = GetWeaponEnchantInfo();
    return mainHand, mainHandExpires;
end

function FishMaster:GetProfessionInfo(name)
    local numSkills = GetNumSkillLines();
    for i = 1, numSkills do
        local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription = GetSkillLineInfo(i)
        if skillName:lower() == name:lower() then
            return skillName, skillRank, numTempPoints, skillMaxRank, skillModifier, skillDescription
        end
    end

    return nil
end

function FishMaster:AddLoot()
    local loot = {};
    local count = GetNumLootItems()

    for i = 1, count do
        local lIcon, lName, lQuantity, currencyID, lQuality, locked, isQuestItem = GetLootSlotInfo(i)
        local lLink = GetLootSlotLink(i)
        local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
        itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID,
        isCraftingReagent = GetItemInfo(lLink);

        if not isQuestItem then
            FishMaster:AddToDatabase(itemName, tonumber(lQuantity), itemIcon, lQuality);
            FishMaster:AddToSession(itemName, tonumber(lQuantity), itemIcon, lQuality);
            FishMaster:debug("Added loot to database", itemName)
        end
    end
end

function FishMaster:FindInDatabase(name, zone)
    for key, loot in pairs(FishMaster.db.char.loot) do
        if loot.item == name and zone == zone then
            return FishMaster.db.char.loot[key];
        end
    end
    return nil;
end

function FishMaster:FindInSession(name, zone)
    for key, loot in pairs(FishMaster.sessionLoot) do
        if loot.item == name and zone == zone then
            return FishMaster.sessionLoot[key];
        end
    end
    return nil;
end

function FishMaster:AddToDatabase(name, quantity, icon, quality)
    local zone = GetMinimapZoneText();
    local loot = FishMaster:FindInDatabase(name, zone);
    if loot then
        loot.quantity = loot.quantity + quantity;
    else
        loot = {
            item = name,
            quantity = quantity,
            quality = quality,
            icon = icon,
            zone = zone
        }

        table.insert(FishMaster.db.char.loot, loot)
    end
end

function FishMaster:AddToSession(name, quantity, icon, quality)
    local zone = GetMinimapZoneText();
    local loot = FishMaster:FindInSession(name, zone);
    if loot then
        loot.quantity = loot.quantity + quantity;
    else
        loot = {
            item = name,
            quantity = quantity,
            quality = quality,
            icon = icon,
            zone = zone
        }

        table.insert(FishMaster.sessionLoot, loot)
    end
end

function FishMaster:HasPole()
    local itemID, bag, slot
    for key, pole in pairs(FishMaster.poles) do
        if GetItemCount(pole) > 0 then
            return true;
        end
    end
end

function FishMaster:FindBestPole()
    local itemID, bag, slot
    for key, pole in pairs(FishMaster.poles) do
        itemID, bag, slot = FishMaster:FindItemInBags(pole);
        if itemID then
            return itemID, bag, slot
        end
    end

    if not itemID then
        local mainHandID = GetInventoryItemID("player", INVSLOT_MAINHAND);

        for key, pole in pairs(FishMaster.poles) do
            if pole == mainHandID then
                return pole;
            end
        end
    end
end

function FishMaster:Toggle()
    if FishMaster.IsCasting then
        return ;
    end

    FishMaster:ToggleGear();
end

function FishMaster:SaveGearSet()
    for key, slot in pairs(FishMaster:SlotInfo()) do
        FishMaster.db.char.storedOutfit[slot.name] = GetInventoryItemID("player", slot.id);
    end
end

local gearThread;

function FishMaster:ToggleGear()
    if FishMaster:IsInCombat() then
        return
    end

    if not FishMaster.IsEnabled then

        if not FishMaster:HasPole() then
            return
        end

        if FishMaster.db.char.autoEquip then
            FishMaster:SaveGearSet()

            EquipItemByName(FishMaster:FindBestPole(), INVSLOT_MAINHAND);
            return
        end

        FishMaster:SaveGearSet()

        for slot, item in pairs(FishMaster.db.char.outfit) do
            local s = FishMaster:FindSlotInfo(slot);
            if s and FishMaster:FindItemInBags(item) then
                EquipItemByName(item, s.id);
            end
        end

    else
        gearThread = coroutine.create(FishMaster.EquipGear)
    end
end

local frame = CreateFrame("Frame", nil)
frame:SetScript("OnUpdate", function()
    if gearThread then
        coroutine.resume(gearThread)
    end
end)

function FishMaster:EquipGear()
    for key, slot in pairs(FishMaster:SlotInfo()) do
        if GetInventoryItemID("player", slot.id) ~= FishMaster.db.char.storedOutfit[slot.name] then

            ClearCursor()

            local itemID, bagId, slotId;
            while true do
                itemID, bagId, slotId = FishMaster:FindItemInBags(FishMaster.db.char.storedOutfit[slot.name]);
                local info = C_Container.GetContainerItemInfo(bagId, slotId)

                if info.isLocked then
                    coroutine.yield()
                else
                    break
                end
            end

            C_Container.PickupContainerItem(bagId, slotId)
            EquipCursorItem(slot.id)
        end
    end
end

function FishMaster:SlotInfo()
    local slots = FishMaster.slotInfo;
    table.sort(slots, function(a, b)
        return a.id > b.id
    end);
    return slots;
end

function FishMaster:FindSlotInfo(name)
    for index, slot in pairs(FishMaster:SlotInfo()) do
        if slot.name == name then
            return slot;
        end
    end
end

function FishMaster:SetAudio()
    local variables = {
        "Sound_MasterVolume",
        "Sound_MusicVolume",
        "Sound_AmbienceVolume",
        "Sound_SFXVolume",
        "Sound_EnableSoundWhenGameIsInBG",
        "particleDensity",
        "Sound_EnableAllSound",
        "Sound_EnableSFX"
    }

    if FishMaster.db.char.turnOnSound then
        for key, var in pairs(variables) do
            FishMaster.db.char.defaultAudio[var] = GetCVar(var);
        end
    end

end

function FishMaster:UnsetAudio()
    for key, value in pairs(FishMaster.db.char.defaultAudio) do
        SetCVar(key, FishMaster.db.char.defaultAudio[key]);
        FishMaster.db.char.defaultAudio[key] = nil;
    end
end