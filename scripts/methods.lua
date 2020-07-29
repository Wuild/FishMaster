local name, _FishMaster = ...;
local Locale = LibStub("AceLocale-3.0"):GetLocale(name, true)

_FishMaster.enabled = nil;

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
    print("Set audio")

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
    if not _FishMaster.enabled and FishMaster:IsEnabled() then
        _FishMaster.enabled = true;
        FishMaster:enable()
    elseif _FishMaster.enabled and not FishMaster:IsEnabled() then
        _FishMaster.enabled = false;
        FishMaster:disable()
    elseif _FishMaster.enabled == nil and not FishMaster:IsEnabled() then
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
    for key, pole in pairs(_FishMaster.poles) do
        local itemID, bag, slot = FishMaster:FindItemInBags(pole);
        if itemID then
            return itemID, bag, slot
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
    --print(event)

    if event == "BAG_UPDATE" or event == "PLAYER_EQUIPMENT_CHANGED" then
        FishMaster:CheckEnabled()
        print("check player equipment")
    end
end