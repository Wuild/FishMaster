local name, _FishMaster = ...;

FishMaster.ItemSlot = {}

function FishMaster.ItemSlot:Clear(self)
    button.name = nil;
    button.item = nil;
    button.texture = nil;
    button.color = nil;
end

function FishMaster.ItemSlot:OnLoad(self)
    local id, textureName = GetInventorySlotInfo(self:GetAttribute("slot") .. "Slot");
    self:SetID(id);
    self.backgroundTextureName = textureName;
    SetItemButtonTexture(self, self.backgroundTextureName);
    self:RegisterForDrag("LeftButton");
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    self:RegisterEvent("CURSOR_UPDATE");
    self:SetFrameLevel(self:GetFrameLevel() + 3);


    if FishMaster.db.char.outfit[self:GetAttribute("slot")] then
        self:SetAttribute("itemID", FishMaster.db.char.outfit[self:GetAttribute("slot")]);
        FishMaster.ItemSlot:OnChange(self);
    end

end

function FishMaster.ItemSlot:OnClick(self)
    --print(self:GetAttribute("slot"))
end

function FishMaster.ItemSlot:Tooltip(button)
    if button:GetAttribute("itemID") then
        local name, link = GetItemInfo(button:GetAttribute("itemID"))

        GameTooltip:SetOwner(button, "ANCHOR_LEFT");
        GameTooltip:SetHyperlink(link);
        GameTooltip:Show();
    end
end

function FishMaster.ItemSlot:OnEnter(self)
    GameTooltip:ClearLines();

    FishMaster.ItemSlot:Tooltip(self);
    self.hovering = true;
end

function FishMaster.ItemSlot:OnLeave(self)
    GameTooltip:ClearLines();
    GameTooltip:Hide();
    self.hovering = false;
end

function FishMaster.ItemSlot:OnUpdate(self)
    --print(self)
end

function FishMaster.ItemSlot:OnChange(self)
    local itemID = self:GetAttribute("itemID");
    if (itemID) then
        local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(itemID);
        SetItemButtonTexture(self, texture);
    else
        SetItemButtonTexture(self, self.backgroundTextureName);
    end

    FishMaster.db.char.outfit[self:GetAttribute("slot")] = itemID;

    if self.hovering then
        FishMaster.ItemSlot:Tooltip(self)
    end
end

function FishMaster.ItemSlot:OnReceiveDrag(button)
    local parent = button:GetParent();
    local pname = parent:GetName();

    local slotnames = FishMaster:GetSlotInfo();
    if (not FishMaster:CursorCanGoInSlot(button)) then
        button = nil;
        for _, si in ipairs(slotnames) do
            local temp = _G[pname .. si.name];
            if (temp and FishMaster:CursorCanGoInSlot(temp)) then
                button = temp;
            end
        end
    end

    if (button) then
        button:SetAttribute("itemID", _FishMaster.dragging.item);
        FishMaster.ItemSlot:OnChange(button)
    end

    if (_FishMaster.dragging.bag) then
        SavedPickupContainerItem(_FishMaster.dragging.bag, _FishMaster.dragging.slot);
    elseif (_FishMaster.dragging.slot) then
        SavedPickupInventoryItem(_FishMaster.dragging.slot);
    end

end