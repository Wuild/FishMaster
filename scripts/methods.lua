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

function FishMaster:debug(...)
    if self.db and self.db.global.debug then self:Print(...) end
end

function FishMaster:GetProfessionInfo(profession)
    return API.Profession(profession)
end

function FishMaster:GetProfessionLevel(profession)
    local _, rank, _, _, bonus = API.Profession(profession)
    return (rank or 0) + (bonus or 0)
end

function FishMaster:GetItemCount(item)
    return API.ItemCount(item)
end

function FishMaster:CheckCombat()
    return InCombatLockdown() or UnitAffectingCombat("player")
end

function FishMaster:IsPoleEquipped()
    return API.IsPole(GetInventoryItemID("player", 16))
end

function FishMaster:IsLured()
    if not self:IsPoleEquipped() then return false end
    if C_PaperDollInfo.GetTemporaryEnchantmentInfo then
        local enchant = C_PaperDollInfo.GetTemporaryEnchantmentInfo(16)
        return enchant ~= nil, enchant and enchant.remainingTimeMs or 0
    end
    return GetWeaponEnchantInfo()
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

function FishMaster:HasPole()
    return self:FindBestPole() ~= nil
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
    if self:CheckCombat() then self:Print(self:translate("error.combat")); return end
    if ns.isCasting then return end
    if CursorHasItem() then self:Print(self:translate("error.cursor")); return end
    if self.db.char.enabled then
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
    for _, slot in ipairs(ns.slots) do
        local item = settings.outfit[slot.name]
        if item and GetInventoryItemID("player", slot.id) ~= item and not API.FindItem(item) then
            self:Print(self:translate("error.missingItem", API.ItemInfo(item) or tostring(item)))
            return
        end
    end
    settings.storedOutfit = {}
    for _, slot in ipairs(ns.slots) do
        settings.storedOutfit[slot.name] = GetInventoryItemID("player", slot.id) or false
    end
    settings.enabled = true
    -- Equip the main hand first: two-handed poles can displace the off hand.
    local success = true
    if settings.outfit.MainHandSlot then
        success = API.Equip(settings.outfit.MainHandSlot, 16)
    end
    local _, _, _, equipLocation = C_Item.GetItemInfoInstant(settings.outfit.MainHandSlot or GetInventoryItemID("player", 16) or 0)
    for _, slot in ipairs(ns.slots) do
        local item = settings.outfit[slot.name]
        if slot.id ~= 16 and item and not (slot.id == 17 and equipLocation == "INVTYPE_2HWEAPON") then
            if not API.Equip(item, slot.id) then success = false end
        end
    end
    if not success then self:Print(self:translate("error.equip")) end
    self:SetAudio()
end

function FishMaster:RestoreOutfit()
    local settings = self.db.char
    local success = true
    -- Restore weapons before other slots; restore originally empty slots too.
    local order = { "MainHandSlot", "SecondaryHandSlot" }
    for _, slot in ipairs(ns.slots) do
        if slot.id ~= 16 and slot.id ~= 17 then table.insert(order, slot.name) end
    end
    for _, slotName in ipairs(order) do
        for _, slot in ipairs(ns.slots) do
            if slot.name == slotName then
                local item = settings.storedOutfit[slotName]
                if item == false then
                    if not API.EmptySlot(slot.id) then success = false end
                elseif item then
                    if not API.Equip(item, slot.id) then success = false end
                end
                break
            end
        end
    end
    if not success then
        self:Print(self:translate("error.restore"))
        return
    end
    settings.enabled = false
    settings.storedOutfit = {}
    self:UnsetAudio()
end

local soundValues = {
    Sound_EnableAllSound = "1", Sound_EnableSFX = "1", Sound_EnableAmbience = "0",
    Sound_MasterVolume = "1", Sound_SFXVolume = "1", Sound_MusicVolume = "0",
}

function FishMaster:SetAudio()
    local settings = self.db.char
    if not settings.enabled or not settings.audio.enabled then self:UnsetAudio(); return end
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
    if ns.lootRecorded then return end
    local fishingLoot
    if C_Loot and C_Loot.IsFishingLoot then
        fishingLoot = C_Loot.IsFishingLoot()
    elseif IsFishingLoot then
        fishingLoot = IsFishingLoot()
    else
        fishingLoot = ns.lastFishingCast and GetTime() - ns.lastFishingCast < 30 and self:IsPoleEquipped()
    end
    if not fishingLoot then return end
    local total = GetNumLootItems()
    if total == 0 then return end
    ns.lootRecorded = true
    ns.lastFishingCast = nil
    for index = 1, total do
        local link = GetLootSlotLink(index)
        if link then
            local icon, lootName, quantity, _, quality, _, quest = GetLootSlotInfo(index)
            if not quest then
                local itemID = tonumber(link:match("item:(%d+)"))
                local catch = {
                    itemID = itemID, link = link, item = lootName,
                    quantity = tonumber(quantity) or 1, icon = icon,
                    quality = quality or 0, zone = GetMinimapZoneText(),
                }
                if catch.item then
                    addCatch(self.db.char.loot, catch)
                    addCatch(ns.session, catch)
                end
            end
        end
    end
    self:Refresh()
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

function FishMaster:OnSpellStart(_, unit, _, spellID)
    if unit ~= "player" then return end
    if self:CheckCombat() then return end
    ns.isCasting = true
    if API.SpellName(spellID) == API.FishingName() then ns.lastFishingCast = GetTime() end
end

function FishMaster:OnSpellStop(event, unit)
    if unit ~= "player" then return end
    ns.isCasting = false
    if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        ns.lastFishingCast = nil
    end
end

function FishMaster:Refresh()
    if not self.db then return end
    if self:CheckCombat() then ns.refreshPending = true; return end
    ns.refreshPending = false
    self.toolbar:Refresh()
    self.tracker:Refresh()
    self.equipment:Refresh()
end

function FishMaster:SettingsChanged()
    self:SetAudio()
    if self.db.profile.minimap.hide then self.minimap:Hide("FishMasterMinimapIcon")
    else self.minimap:Show("FishMasterMinimapIcon") end
    self:Refresh()
end
