local _, ns = ...
local API, UI = ns.API, ns.UI
FishMaster.ItemSlot = {}

function FishMaster.ItemSlot:Create(parent, slot)
    local native = _G["Character" .. slot.name]
    local size = native and native:GetWidth() or (slot.id == 0 and 27 or 37)
    local button = UI.IconButton(parent, size, false, nil, true)
    button.icon:SetTexCoord(0, 1, 0, 1)
    -- ItemButton's icon is below its normal border. ARTWORK would obscure it.
    button.icon:SetDrawLayer("BORDER")
    button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    local normal = button:GetNormalTexture()
    normal:SetSize(64, 64)
    normal:ClearAllPoints()
    normal:SetPoint("CENTER", 0, -1)
    -- Forever 1.60.1.69913: Blizzard_UIPanels_Game/Camelot/PaperDollFrame.xml.
    -- Mainline's Char-* texture templates are NOT the Camelot paper-doll border.
    button.slotFrame = button:CreateTexture(nil, "BACKGROUND")
    button.slotFrame:SetAtlas(slot.id == 0 and "UI-Character-Info-GearSlotSmall" or "UI-Character-Info-GearSlot", true)
    button.slotFrame:SetPoint("CENTER")
    if slot.id == 0 then
        local arrow = button:CreateTexture(nil, "OVERLAY")
        arrow:SetAtlas("UI-Character-Info-GearSlot-Arrow", true)
        arrow:SetPoint("RIGHT", button, "LEFT", 6, 0)
    end
    button.slot = slot
    button:SetID(slot.id)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button.label = UI.Text(button, slot.label or slot.name, "GameFontNormalSmall")
    button.label:SetWidth(slot.side == "bottom" and 88 or 94)
    if slot.side == "right" then
        button.label:SetPoint("RIGHT", button, "LEFT", -8, 0)
        button.label:SetJustifyH("RIGHT")
    elseif slot.side == "left" then
        button.label:SetPoint("LEFT", button, "RIGHT", 8, 0)
    else
        -- Native weapon grouping is compact; slot names remain in the tooltip.
        button.label:Hide()
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
        if item then
            GameTooltip:SetItemByID(item)
            GameTooltip:AddLine(slot.label or slot.name, .8, .7, .5)
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
    button.icon:SetDesaturated(false)
    button.icon:SetAlpha(1)
    button.label:SetTextColor(item and color.r or .72, item and color.g or .64, item and color.b or .49)
end
