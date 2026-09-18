local _, ns = ...
local API, UI = ns.API, ns.UI
FishMaster.ItemSlot = {}

function FishMaster.ItemSlot:Create(parent, slot)
    local button = UI.IconButton(parent, 38)
    button.slot = slot
    button:SetID(slot.id)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button.label = UI.Text(button, slot.label or slot.name, "GameFontNormalSmall")
    button.label:SetWidth(105)
    if slot.side == "right" then
        button.label:SetPoint("RIGHT", button, "LEFT", -8, 0)
        button.label:SetJustifyH("RIGHT")
    elseif slot.side == "left" then
        button.label:SetPoint("LEFT", button, "RIGHT", 8, 0)
    else
        button.label:SetPoint("TOP", button, "BOTTOM", 0, -6)
        button.label:SetJustifyH("CENTER")
    end
    button:SetScript("OnReceiveDrag", function(self) FishMaster.ItemSlot:Receive(self) end)
    button:SetScript("OnClick", function(self, mouse)
        if FishMaster:CheckCombat() then return end
        if mouse == "RightButton" then
            FishMaster.db.char.outfit[slot.name] = nil
            FishMaster.equipment:Refresh()
        else
            FishMaster.ItemSlot:Receive(self)
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local item = FishMaster.db.char.outfit[slot.name]
        if item then GameTooltip:SetItemByID(item)
        else
            GameTooltip:SetText(slot.label or slot.name)
            GameTooltip:AddLine(FishMaster:translate("outfit.empty"), 1, 1, 1, true)
        end
        GameTooltip:AddLine(FishMaster:translate("outfit.slotHelp"), .65, .65, .65, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

function FishMaster.ItemSlot:Receive(button)
    if FishMaster:CheckCombat() then return end
    local kind, itemID = GetCursorInfo()
    if kind ~= "item" or not itemID then return end
    if not API.CursorFits(button.slot.id) then
        FishMaster:Print(FishMaster:translate("error.slot"))
        return
    end
    FishMaster.db.char.outfit[button.slot.name] = itemID
    ClearCursor()
    FishMaster.equipment:Refresh()
end

function FishMaster.ItemSlot:Refresh(button)
    local item = FishMaster.db.char.outfit[button.slot.name]
    local _, texture = API.SlotInfo(button.slot.name)
    local quality
    if item then
        local _, _, rarity, _, _, _, _, _, _, icon = API.ItemInfo(item)
        quality = rarity
        texture = icon or C_Item.GetItemIconByID(item) or 134400
    end
    button.icon:SetTexture(texture or 134400)
    local color = ITEM_QUALITY_COLORS[quality or 1] or ITEM_QUALITY_COLORS[1]
    button:GetNormalTexture():SetVertexColor(color.r, color.g, color.b)
    button.icon:SetDesaturated(false)
end
