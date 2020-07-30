local name, _FishMaster = ...;
local Locale = LibStub("AceLocale-3.0"):GetLocale(name, true)

_FishMaster.enabled = nil;

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

function FishMaster:enable()
    _FishMaster.mainButton:Show();
end

function FishMaster:disable()
    _FishMaster.mainButton:Hide();
end

function FishMaster:CheckEnabled()
    if not _FishMaster.enabled and FishMaster.db.char.enabled then
        _FishMaster.enabled = true;
        FishMaster:enable()
    elseif _FishMaster.enabled and not FishMaster.db.char.enabled then
        _FishMaster.enabled = false;
        FishMaster:disable()
    elseif _FishMaster.enabled == nil and not FishMaster.db.char.enabled then
        _FishMaster.enabled = false;
        FishMaster:disable()
    end
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
    for key, lure in pairs(_FishMaster.lures) do
        local itemID = FishMaster:FindItemInBags(lure.item);
        local count = GetItemCount(lure.item);
        if itemID and count > 0 then
            return lure;
        end
    end
    return nil;
end

function FishMaster:EventHandler(event, ...)
    if event == "BAG_UPDATE" or event == "PLAYER_EQUIPMENT_CHANGED" then
        FishMaster:CheckEnabled()
    end

    if event == "SKILL_LINES_CHANGED" then
        _G[_FishMaster.frame:GetName() .. "Outfit"].RankFrame.RankLevel:SetText(FishMaster:GetProfessionLevel("fishing") .. "/" .. 300)
        _G[_FishMaster.frame:GetName() .. "Outfit"].RankFrame:SetValue(FishMaster:GetProfessionLevel("fishing"));
    end

end

function FishMaster:ItemSlotChange(event, slot, item)
    FishMaster.db.char.outfit[slot] = item;
end