local name, ns = ...
local API = ns.API
local L = LibStub("AceLocale-3.0"):GetLocale(name, true)
ns.session = {}
ns.isCasting = false

function FishMaster:translate(key, ...)
    local value = L[key] or key
    if select("#", ...) > 0 then return string.format(value, ...) end
    return value
end

function FishMaster:GetProfessionInfo(profession)
    return API.Profession(profession)
end

function FishMaster:GetProfessionLevel(profession)
    local _, rank, _, _, bonus = API.Profession(profession)
    return (rank or 0) + (bonus or 0)
end

function FishMaster:CheckCombat()
    return InCombatLockdown() or UnitAffectingCombat("player")
end

function FishMaster:IsPoleEquipped()
    return API.IsPole(GetInventoryItemID("player", 16))
end

function FishMaster:IsOutfitEquipped()
    if not self:IsPoleEquipped() then return false end
    local main = GetInventoryItemID("player", 16)
    local _, _, _, location = C_Item.GetItemInfoInstant(main)
    local saved = false
    for _, slot in ipairs(ns.slots) do
        local item = self.db.char.outfit[slot.name]
        if item and not (slot.id == 17 and location == "INVTYPE_2HWEAPON") then
            saved = true
            if GetInventoryItemID("player", slot.id) ~= item then return false end
        end
    end
    return saved
end

function FishMaster:SyncEquipmentState()
    self.db.char.enabled = self:IsPoleEquipped()
    self:SetAudio()
end

function FishMaster:ShouldRestoreOutfit()
    return self:IsPoleEquipped() or self.db.char.restorePending
end

function FishMaster:IsLured()
    if not self:IsPoleEquipped() then return false end
    local enchant = C_PaperDollInfo.GetTemporaryEnchantmentInfo(16)
    return enchant ~= nil, enchant and enchant.remainingTimeMs or 0
end

function FishMaster:FindBestPole()
    -- Preserve the curated pole order, then accept new Forever fishing poles.
    for _, pole in ipairs(ns.poles) do
        if API.FindItem(pole) or GetInventoryItemID("player", 16) == pole then return pole end
    end
    if self:IsPoleEquipped() then return GetInventoryItemID("player", 16) end
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemID(bag, slot)
            if API.IsPole(item) then return item end
        end
    end
end

function FishMaster:FindBestLure()
    local skill = self:GetProfessionLevel(API.FishingName())
    local best
    for _, lure in ipairs(ns.lures) do
        if skill >= lure.skill and API.FindItem(lure.item) then
            if not best or (self.db.char.lowestLure and lure.bonus < best.bonus)
                or (not self.db.char.lowestLure and lure.bonus > best.bonus) then
                best = lure
            end
        end
    end
    return best
end

function FishMaster:Toggle()
    self:SyncEquipmentState()
    if self:CheckCombat() then self:Print(self:translate("error.combat")); return end
    if self.gearSwap then self:Print(self:translate("outfit.changing")); return end
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        self:Print(self:translate("error.casting")); return
    end
    if CursorHasItem() then self:Print(self:translate("error.cursor")); return end
    if self:ShouldRestoreOutfit() then
        self:RestoreOutfit()
    else
        self:EquipOutfit()
    end
    self:Refresh()
end

function FishMaster:EquipOutfit()
    local settings = self.db.char
    if settings.autoEquip then
        local pole = self:FindBestPole()
        if not pole then self:Print(self:translate("error.noPole")); return end
        settings.outfit.MainHandSlot = pole
    end
    if not API.IsPole(settings.outfit.MainHandSlot) and not self:IsPoleEquipped() then
        self:Print(self:translate("error.noPole")); return
    end
    -- Validate before replacing the restoration snapshot.
    local required = {}
    local _, _, _, location = C_Item.GetItemInfoInstant(settings.outfit.MainHandSlot or GetInventoryItemID("player", 16) or 0)
    for _, slot in ipairs(ns.slots) do
        local item = settings.outfit[slot.name]
        if item and not (slot.id == 17 and location == "INVTYPE_2HWEAPON") then
            required[item] = (required[item] or 0) + 1
            if API.ItemCount(item) < required[item] then
                self:Print(self:translate("error.missingItem", API.ItemInfo(item) or tostring(item)))
                return
            end
        end
    end
    settings.storedOutfit = {}
    for _, slot in ipairs(ns.slots) do
        settings.storedOutfit[slot.name] = GetInventoryItemID("player", slot.id) or false
    end
    -- Keep the recovery snapshot even if a swap is interrupted or /reload occurs.
    self:StartOutfitSwap(settings.outfit, false)
end

function FishMaster:RestoreOutfit()
    local outfit = self.db.char.storedOutfit
    -- A manually equipped pole may have no earlier outfit to restore.
    if not next(outfit) and self:IsPoleEquipped() then outfit = { MainHandSlot = false } end
    self:StartOutfitSwap(outfit, true)
end

function FishMaster:StartOutfitSwap(outfit, restoring)
    local steps = {}
    local main = outfit.MainHandSlot
    local mainID = main
    if mainID == nil then mainID = GetInventoryItemID("player", 16) end
    local _, _, _, location = C_Item.GetItemInfoInstant(mainID or 0)
    -- Make room for a two-handed pole before equipping it. Wait for the off-hand
    -- to reach a bag before submitting the next request.
    if location == "INVTYPE_2HWEAPON" then table.insert(steps, { id = 17, item = false }) end
    if main ~= nil then table.insert(steps, { id = 16, item = main }) end
    if outfit.SecondaryHandSlot ~= nil and location ~= "INVTYPE_2HWEAPON" then
        table.insert(steps, { id = 17, item = outfit.SecondaryHandSlot })
    end
    for _, slot in ipairs(ns.slots) do
        if slot.id ~= 16 and slot.id ~= 17 and outfit[slot.name] ~= nil then
            table.insert(steps, { id = slot.id, item = outfit[slot.name] })
        end
    end
    self.db.char.restorePending = true
    self.gearSwap = { steps = steps, index = 1, restoring = restoring, deadline = GetTime() + 8 }
    self:AdvanceOutfitSwap()
end

function FishMaster:AdvanceOutfitSwap()
    local swap = self.gearSwap
    if not swap or swap.processing then return end
    if self:CheckCombat() or GetTime() > swap.deadline then
        self.gearSwap = nil
        self:Print(self:translate(swap.restoring and "error.restore" or "error.equip"))
        self:Refresh()
        return
    end
    if CursorHasItem() or UnitCastingInfo("player") or UnitChannelInfo("player") then return end
    swap.processing = true
    while swap.steps[swap.index] do
        local step = swap.steps[swap.index]
        if IsInventoryItemLocked(step.id) then break end
        if (GetInventoryItemID("player", step.id) or false) == step.item then
            swap.index = swap.index + 1
            swap.deadline = GetTime() + 8
        else
            -- Never replay a submitted swap while waiting for the server.
            if not step.submitted then
                if step.item == false then step.submitted = API.EmptySlot(step.id)
                else step.submitted = API.Equip(step.item, step.id) end
            end
            break
        end
    end
    swap.processing = false
    if not swap.steps[swap.index] then
        self.gearSwap = nil
        for _, step in ipairs(swap.steps) do
            if (GetInventoryItemID("player", step.id) or false) ~= step.item then
                self:Print(self:translate(swap.restoring and "error.restore" or "error.equip"))
                self:Refresh()
                return
            end
        end
        if swap.restoring then
            self.db.char.storedOutfit = {}
        end
        self.db.char.restorePending = false
        self:Refresh()
    end
end

local soundValues = {
    Sound_EnableAllSound = "1", Sound_EnableSFX = "1", Sound_EnableAmbience = "0",
    Sound_MasterVolume = "1", Sound_SFXVolume = "1", Sound_MusicVolume = "0",
}

function FishMaster:SetAudio()
    local settings = self.db.char
    if not self:IsPoleEquipped() or not settings.audio.enabled then self:UnsetAudio(); return end
    for key, default in pairs(soundValues) do
        if key ~= "Sound_EnableAllSound" or settings.audio.force then
            if settings.defaultAudio[key] == nil then
                settings.defaultAudio[key] = C_CVar.GetCVar(key)
            end
            local value = default
            if key == "Sound_MasterVolume" or key == "Sound_SFXVolume" then value = tostring(settings.audio.volume) end
            C_CVar.SetCVar(key, value)
        elseif settings.defaultAudio[key] then
            C_CVar.SetCVar(key, settings.defaultAudio[key])
            settings.defaultAudio[key] = nil
        end
    end
end

function FishMaster:UnsetAudio()
    for key, value in pairs(self.db.char.defaultAudio) do
        C_CVar.SetCVar(key, value)
        self.db.char.defaultAudio[key] = nil
    end
end

local function addCatch(list, catch)
    for _, entry in ipairs(list) do
        if (entry.itemID and entry.itemID == catch.itemID or entry.item == catch.item) and entry.zone == catch.zone then
            entry.quantity = (entry.quantity or 0) + catch.quantity
            entry.itemID, entry.link = catch.itemID, catch.link
            return
        end
    end
    local entry = {}
    for key, value in pairs(catch) do entry[key] = value end
    table.insert(list, entry)
end

function FishMaster:OnLoot()
    if not IsFishingLoot() then return end
    local total = GetNumLootItems()
    if total == 0 then return end
    -- Slot indices remain stable for this loot window. Retry incomplete slots
    -- without recounting the ones already recorded by LOOT_READY/LOOT_OPENED.
    ns.lootRecorded = ns.lootRecorded or {}
    ns.lootPending = false
    local changed = false
    for index = 1, total do
        if not ns.lootRecorded[index] then
            local link = GetLootSlotLink(index)
            local icon, lootName, quantity, _, quality, _, quest = GetLootSlotInfo(index)
            if quest then
                ns.lootRecorded[index] = true
            elseif link and lootName and quality ~= nil then
                local itemID = tonumber(link:match("item:(%d+)"))
                if itemID then
                    local catch = {
                        itemID = itemID, link = link, item = lootName,
                        quantity = tonumber(quantity) or 1, icon = icon,
                        quality = quality, zone = GetMinimapZoneText(),
                    }
                    addCatch(self.db.char.loot, catch)
                    addCatch(ns.session, catch)
                    changed = true
                    ns.lootRecorded[index] = true
                end
            else
                ns.lootPending = true
            end
        end
    end
    if changed then self:Refresh() end
end

function FishMaster:GetCatches(session, zone, hideTrash)
    local totals, result, count = {}, {}, 0
    for _, entry in ipairs(session and ns.session or self.db.char.loot) do
        if (not zone or entry.zone == zone) and (not hideTrash or (entry.quality or 0) > 0) then
            local key = entry.itemID or entry.item
            if key then
                if not totals[key] then
                    totals[key] = { item = entry.item, itemID = entry.itemID, link = entry.link,
                        icon = entry.icon, quality = entry.quality or 0, quantity = 0 }
                    table.insert(result, totals[key])
                end
                totals[key].quantity = totals[key].quantity + (entry.quantity or 0)
                count = count + (entry.quantity or 0)
            end
        end
    end
    table.sort(result, function(a, b)
        if a.quantity == b.quantity then return (a.item or "") < (b.item or "") end
        return a.quantity > b.quantity
    end)
    return result, count
end

function FishMaster:OnSpellStart(_, unit)
    if unit ~= "player" then return end
    if self:CheckCombat() then return end
    ns.isCasting = true
    self.interaction:Refresh()
end

function FishMaster:OnSpellStop(_, unit)
    if unit ~= "player" then return end
    ns.isCasting = false
    self.interaction:Refresh()
end

function FishMaster:Refresh()
    if not self.db then return end
    -- Equipment and audio are safe to reconcile even when protected UI updates
    -- must wait for combat to end (weapons can be changed during combat).
    self:SyncEquipmentState()
    if self:CheckCombat() then ns.refreshPending = true; return end
    ns.refreshPending = false
    self.toolbar:Refresh()
    self.interaction:Refresh()
    self.tracker:Refresh()
    self.equipment:Refresh()
end

function FishMaster:SettingsChanged()
    self:SetAudio()
    if self.db.profile.minimap.hide then self.minimap:Hide("FishMasterMinimapIcon")
    else self.minimap:Show("FishMasterMinimapIcon") end
    self:Refresh()
end
