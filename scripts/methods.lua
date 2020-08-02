local name, _FishMaster = ...;
local Locale = LibStub("AceLocale-3.0"):GetLocale(name, true)

_FishMaster.enabled = nil;
_FishMaster.session = {}
_FishMaster.isCasting = false;
_FishMaster.isFishing = false;

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

table.length = function(T)
    local count = 0
    if T then
        for _ in pairs(T) do
            count = count + 1
        end
    end
    return count
end

table.filter = function(t, filterIter)
    local out = {}

    for k, v in pairs(t) do
        if filterIter(v, k, t) then
            out[k] = v;
        end
    end

    return out
end

table.reverse = function(t)
    local out = {}
    local length = table.length(t);
    for k, v in pairs(t) do
        out[(length + 1) - k] = v;
    end
    return out
end

function FishMaster:debug(...)
    if (FishMaster.db.global.debug) then
        print(FishMaster:Colorize("<" .. FishMaster.name .. " - Debug>", "blue"), ...)
    end
end

function FishMaster:SlotInfo()
    return FishMaster.slotInfo;
end

function FishMaster:FindSlotInfo(name)
    for index, slot in pairs(FishMaster:SlotInfo()) do
        if slot.name == name then
            return slot;
        end
    end
end

function FishMaster:Colorize(str, color)
    local c = '';
    if color == 'red' then
        c = '|cffff0000';
    elseif color == 'gray' then
        c = '|cFFCFCFCF';
    elseif color == 'purple' then
        c = '|cFFB900FF';
    elseif color == 'blue' then
        c = '|cB900FFFF';
    elseif color == 'yellow' then
        c = '|cFFFFB900';
    elseif color == 'green' then
        c = "|cFF00FF00";
    elseif color == 'white' then
        c = "|cffffffff"
    elseif color == 'cyan' then
        c = "|cff00FFFF"
    end
    return c .. str .. "|r"
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

function FishMaster:GetPole(id)
    for key, item in pairs(_FishMaster.poles) do
        if item == id then
            return _FishMaster.poles[key]
        end
    end
    return false;
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

function FishMaster:SetFrameText(frame, string)
    frame:SetText(FishMaster:translate(string))
end

function FishMaster:CheckEnabled()

    if FishMaster:CheckCombat() then
        return
    end

    securecall(function()
        if FishMaster:IsPoleEquipped() then
            _G['FishMaster_Toolbar']:Show()
            if FishMaster.db.char.tracker.enabled then
                _G['FishMaster_Tracker']:Show()
            else
                _G['FishMaster_Tracker']:Hide()
            end
        else
            _G['FishMaster_Toolbar']:Hide()
            _G['FishMaster_Tracker']:Hide()
        end
    end)
end

function FishMaster:IsEnabled()
    local mainHandID = GetInventoryItemID("player", GetInventorySlotInfo("MainHandSlot"));
    return FishMaster:GetPole(mainHandID);
end

function FishMaster:IsLured()
    if not FishMaster:IsEnabled() then
        return false, nil;
    end
    local mainHand, mainHandExpires, _, mainHandEnchantID = GetWeaponEnchantInfo();
    return mainHand, mainHandExpires;
end

function FishMaster:GetProfessionLevel(name)
    local numSkills = GetNumSkillLines();
    for i = 1, numSkills do
        local skillname, _, _, skillrank, _, skillmodifier = GetSkillLineInfo(i)
        if skillname:lower() == name:lower() then
            return (skillrank or 0 + skillmodifier or 0)
        end
    end

    return 0
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

function FishMaster:IsBodySlotOneHanded(bodyslot)
    if (bodyslot == "INVTYPE_2HWEAPON" or bodyslot == INVTYPE_2HWEAPON) then
        return false;
    end
    return true;
end

function FishMaster:GetSlotButton(button, slotName)

    local children = { button:GetParent():GetChildren() }

    for _, child in ipairs(children) do
        if (child:GetAttribute("slot") == slotName) then
            return child;
        end
    end
end

function FishMaster:IsItemOneHanded(item)
    if (item) then
        local _, _, _, _, _, _, _, _, bodyslot, _ = GetItemInfo(item);
        return FishMaster:IsBodySlotOneHanded(bodyslot);
    end
    return true;
end

function FishMaster:CursorCanGoInSlot(button)
    local secondary = FishMaster:GetSlotButton(button, "SecondaryHand");
    local mainbutton = FishMaster:GetSlotButton(button, "MainHand");

    if (button == secondary and mainbutton and mainbutton.item) then
        return FishMaster:IsItemOneHanded(mainbutton.item);
    end
    return CursorCanGoInSlot(button:GetID())
end

function FishMaster:SavePosition(frame)
    local centerx, centery = frame:GetCenter()
    local scale = frame:GetScale()
    local p, f, rp, x, y = "CENTER", "UIParent", "BOTTOMLEFT", centerx * scale, centery * scale
    FishMaster.db.char.point = {
        p = p, rf = f, rp = rp, x = x, y = y,
    }
end

function FishMaster:FindItemInBags(itemID)
    for i = 0, NUM_BAG_SLOTS do
        for z = 1, GetContainerNumSlots(i) do
            if GetContainerItemID(i, z) == itemID then
                return itemID, i, z
            end
        end
    end
    return nil, nil, nil
end

function FishMaster:HasPole()
    local itemID, bag, slot
    for key, pole in pairs(_FishMaster.poles) do
        if GetItemCount(pole) > 0 then
            return true;
        end
    end
end

function FishMaster:FindBestPole()
    local itemID, bag, slot
    for key, pole in pairs(_FishMaster.poles) do
        itemID, bag, slot = FishMaster:FindItemInBags(pole);
        if itemID then
            return itemID, bag, slot
        end
    end

    if not itemID then
        local mainHandID = GetInventoryItemID("player", INVSLOT_MAINHAND);

        for key, pole in pairs(_FishMaster.poles) do
            if pole == mainHandID then
                return pole;
            end
        end
    end
end

function FishMaster:FindBestLure()

    local t;

    if FishMaster.db.char.lowestLure then
        t = table.reverse(_FishMaster.lures);
    else
        t = _FishMaster.lures;
    end

    for key, lure in pairs(t) do
        local itemID = FishMaster:FindItemInBags(lure.item);
        local count = GetItemCount(lure.item);
        if itemID and count > 0 then
            return lure;
        end
    end
    return nil;
end

function FishMaster:IsPoleEquipped()
    local mainHandID = GetInventoryItemID("player", INVSLOT_MAINHAND);
    for key, pole in pairs(_FishMaster.poles) do
        if pole == mainHandID then
            return true;
        end
    end
    return false;
end

function FishMaster:FindInSession(name, zone)
    for key, loot in pairs(_FishMaster.session) do
        if loot.item == name and zone == zone then
            return _FishMaster.session[key];
        end
    end
    return nil;
end

function FishMaster:FindInDatabase(name, zone)
    for key, loot in pairs(FishMaster.db.char.loot) do
        if loot.item == name and zone == zone then
            return FishMaster.db.char.loot[key];
        end
    end
    return nil;
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

        table.insert(_FishMaster.session, loot)
    end
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

    FishMaster:AddToSession(name, quantity, icon, quality);

    FishMaster:Trigger("LootAdded", loot);
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
        end
    end
end

function FishMaster:FindLure(item)
    for key, lure in pairs(_FishMaster.lures) do
        if lure.item == item then
            return lure;
        end
    end
    return nil;
end

function FishMaster:CheckCombat()
    return InCombatLockdown() or UnitAffectingCombat("player") or UnitAffectingCombat("pet")
end

function FishMaster:CheckForDoubleClick(button)
    if (button and button ~= "RightButton") then
        return false;
    end
    if (not LootFrame:IsShown() and self.lastClickTime) then
        local pressTime = GetTime();
        local doubleTime = pressTime - self.lastClickTime;
        if ((doubleTime < 0.4) and (doubleTime > 0.05)) then
            self.lastClickTime = nil;
            return true;
        end
    end
    self.lastClickTime = GetTime();
    return false;
end

local function SafeHookScript(frame, handlername, newscript)
    local oldValue = frame:GetScript(handlername);
    frame:SetScript(handlername, newscript);
    return oldValue;
end

local function FM_OnMouseDown(...)
    -- Only steal 'right clicks' (self is arg #1!)
    local button = select(2, ...);
    if (FishMaster.db.char.easyCast and not FishMaster:CheckCombat() and FishMaster:IsPoleEquipped()) then
        if (FishMaster:CheckForDoubleClick(button)) then
            -- We're stealing the mouse-up event, make sure we exit MouseLook
            if (IsMouselooking()) then
                MouselookStop();
            end
            FishMaster:SetOverride()
        end
        if (SavedWFOnMouseDown) then
            SavedWFOnMouseDown(...);
        end
    end
end

function FishMaster:SetOverride()

    local toolbar = _G['FishMaster_Toolbar'];
    local button = toolbar.cast;
    button:SetScript("PostClick", function()
        FishMaster_CastFrame:Show();
    end);
    SetOverrideBindingClick(button, true, "BUTTON2", button:GetName());
end

function FishMaster:ResetOverride()
    button:SetScript("PostClick", nil);
    ClearOverrideBindings(FishMaster_Toolbar.cast);
    FishMaster_CastFrame:Hide();
end

function FishMaster:EventHandler(event, ...)
    if event == "BAG_UPDATE" or event == "PLAYER_EQUIPMENT_CHANGED" then
        FishMaster:CheckEnabled()
        FishMaster:UpdateModel();

        FishMaster:Toolbar()
        FishMaster:CheckEnabled()
    elseif event == "SKILL_LINES_CHANGED" then
        FishMaster:Trigger("SkillLineChanged");
    elseif event == "LOOT_OPENED" then
        if IsFishingLoot() then
            FishMaster:AddLoot()
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_START" then

        local target = select(1, ...);
        local spell = select(3, ...);

        if target == "player" and GetSpellInfo(spell) ~= PROFESSIONS_FISHING then
            _FishMaster.isCasting = true;
        elseif target == "player" and GetSpellInfo(spell) == PROFESSIONS_FISHING then
            _FishMaster.isFishing = true;
            _FishMaster.isCasting = false;
        elseif target == "player" then
            _FishMaster.isCasting = false;
        end

    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_STOP" then
        _FishMaster.isCasting = false;
        _FishMaster.isFishing = true;
    elseif event == "PLAYER_ENTERING_WORLD" then
        FishMaster:Trigger("loaded");
    elseif event == "VARIABLES_LOADED" then
        if (WorldFrame.OnMouseDown) then
            hooksecurefunc(WorldFrame, "OnMouseDown", FM_OnMouseDown)
        else
            SavedWFOnMouseDown = SafeHookScript(WorldFrame, "OnMouseDown", FM_OnMouseDown);
        end
    end
end

function FishMaster:ItemSlotChange(event, slot, item)
    FishMaster.db.char.outfit[slot] = item;
end

function FishMaster:SaveAudio()
    FishMaster.db.char.defaultAudio["Sound_EnableAllSound"] = GetCVar("Sound_EnableAllSound");
    FishMaster.db.char.defaultAudio["Sound_EnableSFX"] = GetCVar("Sound_EnableSFX");
    FishMaster.db.char.defaultAudio["Sound_EnableAmbience"] = GetCVar("Sound_EnableAmbience");
    FishMaster.db.char.defaultAudio["Sound_MasterVolume"] = GetCVar("Sound_MasterVolume");
    FishMaster.db.char.defaultAudio["Sound_SFXVolume"] = GetCVar("Sound_SFXVolume");
    FishMaster.db.char.defaultAudio["Sound_MusicVolume"] = GetCVar("Sound_MusicVolume");
end

function FishMaster:SetAudio(save)

    if not FishMaster.db.char.enabled then
        return
    end

    if not FishMaster.db.char.audio.enabled then
        FishMaster:UnsetAudio();
        return
    end

    if save then
        FishMaster:SaveAudio();

    end

    if FishMaster.db.char.audio.force then
        SetCVar("Sound_EnableAllSound", true);
    end
    SetCVar("Sound_EnableSFX", true);
    SetCVar("Sound_EnableAmbience", false);
    SetCVar("Sound_MasterVolume", FishMaster.db.char.audio.volume);
    SetCVar("Sound_SFXVolume", FishMaster.db.char.audio.volume);
    SetCVar("Sound_MusicVolume", 0);

end

function FishMaster:UnsetAudio()
    for key, value in pairs(FishMaster.db.char.defaultAudio) do
        SetCVar(key, FishMaster.db.char.defaultAudio[key]);
        FishMaster.db.char.defaultAudio[key] = nil;
    end
end

function FishMasterFrameTab_OnClick(self)
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
    FishMasterSwitchTabs(self:GetID());
end

function FishMasterSwitchTabs(newID)

    local FISHMASTERFRAME_SUBFRAMES = {
        _FishMaster.frame:GetName() .. "Outfit",
        _FishMaster.frame:GetName() .. "Settings"
    };

    local newFrame = _G[FISHMASTERFRAME_SUBFRAMES[newID]];
    local oldFrame = _G[FISHMASTERFRAME_SUBFRAMES[PanelTemplates_GetSelectedTab(_FishMaster.frame)]];
    if (newFrame) then
        if (oldFrame) then
            oldFrame:Hide();
        end
        PanelTemplates_SetTab(_FishMaster.frame, newID);
        newFrame:Show();
    end
end