local name, _FishMaster = ...;

--_FishMaster.callbacks = LibStub("CallbackHandler-1.0"):New(_FishMaster)

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local minimapIcon = LibStub("LibDataBroker-1.1"):NewDataObject("FishMasterMinimapIcon", {
    type = "data source",
    text = _FishMaster.name,
    icon = _FishMaster.iconPath .. "Fishhook",

    OnClick = function(self, button)
        if button == "LeftButton" then
            FishMaster:Toggle();
        elseif button == "RightButton" then
            FishMaster.equipment:Toggle()
            --InterfaceOptionsFrame_OpenToCategory(name)
            --InterfaceOptionsFrame_OpenToCategory(name) -- run it again to set the correct tab
        end
    end,

    OnTooltipShow = function(tooltip)
        tooltip:SetText(_FishMaster.name .. " |cFF00FF00" .. _FishMaster.version .. "|r");
        tooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.left_click"), 'gray') .. ": " .. FishMaster:translate("minimap.left_click_text"));
        tooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.right_click"), 'gray') .. ": " .. FishMaster:translate("minimap.right_click_text"));
    end,
});

function FishMaster:CreateMainButton()
    local texture = "Interface\\Icons\\inv_fishingpole_02";
    local button = CreateFrame("BUTTON", "Poisoner_FreeButton", UIParent, "SecureActionButtonTemplate");

    local size = 42
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton");
    button:SetMovable(true);
    button:SetSize(size, size)
    button:SetScale(1)
    button:SetAlpha(1)

    button:SetScript("OnEnter", function(self)
        GameTooltip:ClearLines();
        GameTooltip:SetOwner(self, "ANCHOR_MIDDLELEFT");

        GameTooltip:SetText(_FishMaster.name .. " |cFF00FF00" .. _FishMaster.version .. "|r");
        GameTooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.left_click"), 'gray') .. ": " .. FishMaster:translate("button.left_click_text"));
        GameTooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.right_click"), 'gray') .. ": " .. FishMaster:translate("button.right_click_text"));

        GameTooltip:Show();
    end);

    button:SetScript("OnLeave", function(self)
        GameTooltip:ClearLines();
        GameTooltip:Hide();
    end);

    button:ClearAllPoints();

    button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(1)

    button.Texture = button:CreateTexture(button:GetName() .. "Icon", "ARTWORK");
    button.Texture:SetTexture(texture)
    button.Texture:ClearAllPoints()
    button.Texture:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.Texture:SetTexCoord(0, 1, 0, 1)

    button.Texture:SetSize(size, size)
    button:SetNormalTexture(texture)
    button:SetHighlightTexture(texture)
    local tex = button:GetNormalTexture()
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", button, "CENTER", 0, 0)
    tex:SetSize(size, size)

    local t = FishMaster.db.char.point
    button:SetPoint(t.p, t.rf, t.rp, t.x / button:GetScale(), t.y / button:GetScale());

    button:Hide()

    button:SetAttribute("type", "macro");

    button:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self.IsMoving = true
    end);
    button:SetScript("OnDragStop", function(self)
        if self.IsMoving == true then
            self:StopMovingOrSizing()
            self.IsMoving = false
            FishMaster:SavePosition(self)
        end
    end);

    button:SetScript("OnUpdate", function(self)

        local text = "";

        local lured = FishMaster:IsLured();

        local lure = FishMaster:FindBestLure();

        if not lured and lure and FishMaster.db.char.autoLure then
            local name, rank, icon = GetSpellInfo(lure.spell)
            text = text .. "/use " .. name .. "\n";
            text = text .. "/use 16\n";
        else
            if lure then
                local name, rank, icon = GetSpellInfo(lure.spell)
                text = text .. "/use [button:2] " .. name .. "\n";
                text = text .. "/use [button:2] 16\n";
            end
            text = text .. "/use [button:1] Fishing\n";
        end

        self:SetAttribute("macrotext", text)
    end);
    button:SetClampedToScreen(true);

    _FishMaster.mainButton = button;
end

function FishMaster:CreateLureButtons()
    for key, lure in pairs(_FishMaster.lures) do
        local button = CreateFrame("BUTTON", "FishMasterLure_" .. key, Poisoner_FreeButton, "BagBuddyItemTemplate");

        local size = 32
        button:RegisterForClicks("AnyUp")
        button:RegisterForDrag("LeftButton");
        button:SetMovable(true);
        button:SetSize(size, size)
        button:SetScale(1)
        button:SetAlpha(1)

        if key == 1 then
            button:SetPoint("TOPLEFT", Poisoner_FreeButton, "TOPRIGHT", 5, 0)
        else
            button:SetPoint("TOPLEFT", _G["FishMasterLure_" .. key - 1], "TOPRIGHT", 2, 0)
        end

        button:SetFrameStrata("MEDIUM")
        button:SetFrameLevel(1)

        button:SetAttribute("lure", lure);

        button:SetScript("OnEnter", function(self)
            GameTooltip:ClearLines();
            GameTooltip:SetOwner(self, "ANCHOR_LEFT");

            local name, link = GetItemInfo(self:GetAttribute("item"))

            GameTooltip:SetHyperlink(link);
            GameTooltip:Show();
        end);

        button:SetScript("OnLeave", function(self)
            GameTooltip:ClearLines();
            GameTooltip:Hide();
        end);

        button:SetScript("OnUpdate", function(self)
            local lure = self:GetAttribute("lure");
            local count = GetItemCount(lure.item);

            _G[self:GetName() .. "Count"]:SetText(count);

            if count == 0 then
                self:SetAlpha(.2);
                self:EnableMouse(false);
            elseif FishMaster:GetProfessionLevel("fishing") < lure.skill then
                self:SetAlpha(.2);
                self:EnableMouse(false);
            else
                self:SetAlpha(1);
                self:EnableMouse(true);
            end
        end);

        _G["FishMasterLure_" .. key .. "IconTexture"]:SetTexture(lure.icon)
        _G["FishMasterLure_" .. key .. "Count"]:SetText(2)
        _G["FishMasterLure_" .. key .. "Count"]:Show()

        local spellName, rank, icon = GetSpellInfo(lure.spell)
        local text = "";
        text = text .. "/use " .. spellName .. "\n";
        text = text .. "/use 16\n";
        button:SetAttribute("name", spellName)
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", text)
        button:SetAttribute("item", lure.item)
        button:SetClampedToScreen(true);
    end
end

function FishMaster:Toggle()
    FishMaster.db.char.enabled = not FishMaster.db.char.enabled;
    FishMaster:CheckEnabled();
    FishMaster:ToggleGear();
end

function FishMaster:ToggleGear()
    if FishMaster.db.char.enabled then
        for key, slot in pairs(FishMaster:SlotInfo()) do
            FishMaster.db.char.storedOutfit[slot.name] = GetInventoryItemID("player", slot.id);
        end

        for slot, item in pairs(FishMaster.db.char.outfit) do
            local s = FishMaster:FindSlotInfo(slot);
            if s and FishMaster:FindItemInBags(item) then
                EquipItemByName(item, s.id);
            end
        end
    else
        for key, slot in pairs(FishMaster:SlotInfo()) do
            --FishMaster.db.char.storedOutfit[slot.name] = GetInventoryItemID("player", slot.id);
            --
            --print(s.name, GetItemInfo(itemID))
            if GetInventoryItemID("player", slot.id) ~= FishMaster.db.char.storedOutfit[slot.name] then
                EquipItemByName(FishMaster.db.char.storedOutfit[slot.name], slot.id);
            end
        end
    end
end

function FishMaster:GatherSlash(input)
    input = string.trim(input, " ");
    if input == "" or not input then
        FishMaster:Toggle()
        return ;
    elseif input == "config" then
        FishMaster.equipment:Toggle()
    end
end

function FishMaster:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("FishMasterSettings", _FishMaster.configsDefaults, true)
    self.minimap = LibStub("LibDBIcon-1.0")
    FishMaster.minimap:Register("FishMasterMinimapIcon", minimapIcon, self.db.profile.minimap)

    FishMaster:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "EventHandler")
    FishMaster:RegisterEvent("BAG_UPDATE", "EventHandler")
    FishMaster:RegisterEvent("LOOT_OPENED", "EventHandler")
    FishMaster:RegisterEvent("SKILL_LINES_CHANGED", "EventHandler")
    FishMaster:RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler")

    FishMaster:On("OnItemSlotChange", "ItemSlotChange")

    FishMaster:RegisterChatCommand("fmaster", "GatherSlash")
    FishMaster:RegisterChatCommand("fishmaster", "GatherSlash")

    if FishMaster.db.char.firstRun then
        local pole = FishMaster:FindBestPole();
        if pole then
            FishMaster.db.char.outfit["MainHandSlot"] = pole;
        end
        FishMaster.db.char.firstRun = false;
    end

    FishMaster:CreateMainButton()
    FishMaster:CreateLureButtons()
    FishMaster.equipment:OnLoad()
    FishMaster:CheckEnabled();

end