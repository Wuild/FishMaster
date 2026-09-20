local _, ns = ...
local UI = {}
ns.UI = UI

function UI.Text(parent, text, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    label:SetText(text or "")
    label:SetJustifyH("LEFT")
    return label
end

function UI.Background(parent, r, g, b, a)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetColorTexture(r, g, b, a or 1)
    return texture
end

-- Thin metal edging, drawn without adding another mouse-intercepting frame.
function UI.Border(parent, r, g, b, alpha)
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local line = parent:CreateTexture(nil, "BORDER")
        line:SetColorTexture(r, g, b, alpha or 1)
        if edge == "TOP" or edge == "BOTTOM" then
            line:SetPoint(edge .. "LEFT")
            line:SetPoint(edge .. "RIGHT")
            line:SetHeight(1)
        else
            line:SetPoint("TOP" .. edge)
            line:SetPoint("BOTTOM" .. edge)
            line:SetWidth(1)
        end
    end
end

function UI.Atlas(texture, atlas)
    if C_Texture.GetAtlasInfo(atlas) then texture:SetAtlas(atlas); return true end
    return false
end

function UI.Button(parent, text, width, action)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 140, 26)
    button:SetText(text)
    button:SetScript("OnClick", action)
    return button
end

function UI.Check(parent, text, get, set)
    local check = CreateFrame("CheckButton", nil, parent, "CheckboxWithLabelTemplate")
    check:SetSize(30, 29)
    check.Text:SetText(text)
    check.Text:SetFontObject("GameFontHighlight")
    check:SetScript("OnShow", function(self) self:SetChecked(get()) end)
    check:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
        FishMaster:SettingsChanged()
    end)
    check:SetChecked(get())
    return check
end

function UI.Section(parent, text, width)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, 32)
    local background = UI.Background(frame, .15, .15, .15, .8)
    UI.Atlas(background, "UI-Character-Info-Title")
    frame.Text = UI.Text(frame, text, "GameFontNormal")
    frame.Text:SetPoint("CENTER")
    return frame
end

function UI.Tooltip(frame, title, body)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title)
        if body then GameTooltip:AddLine(body, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function UI.IconButton(parent, size, secure, name, borderless)
    local button = CreateFrame("Button", name, parent, secure and "SecureActionButtonTemplate" or nil)
    button:SetSize(size, size)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(.07, .93, .07, .93)
    if not borderless then
        button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
        button:GetNormalTexture():SetSize(size * 1.65, size * 1.65)
        button:GetNormalTexture():ClearAllPoints()
        button:GetNormalTexture():SetPoint("CENTER", 0, -1)
    end
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button.count = UI.Text(button, "", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -2, 2)
    return button
end

function UI.Scroll(parent, name)
    local scroll = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(600, 1)
    scroll:SetScrollChild(content)
    scroll.content = content
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScroll() - delta * 32, self:GetVerticalScrollRange())))
    end)
    return scroll
end

function UI.SavePosition(frame, key)
    local point, _, relativePoint, x, y = frame:GetPoint()
    FishMaster.db.char[key] = { point, relativePoint, x, y }
end

function UI.Position(frame, key, x, y)
    frame:ClearAllPoints()
    local saved = FishMaster.db.char[key]
    if saved and saved[1] then frame:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
    else frame:SetPoint("CENTER", UIParent, "CENTER", x or 0, y or 0) end
end

function UI.Drag(frame, key, handle)
    handle = handle or frame
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        if not InCombatLockdown() then frame:StartMoving() end
    end)
    handle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        UI.SavePosition(frame, key)
    end)
end

function UI.CatchRow(parent, width, plain)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, 34)
    if not plain then
        row.background = UI.Background(row, 1, 1, 1, .035)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    end
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(26, 26)
    row.icon:SetPoint("LEFT", 6, 0)
    row.item = UI.Text(row)
    row.item:SetPoint("LEFT", 42, 0)
    row.item:SetWidth(width - 120)
    row.count = UI.Text(row, "", "GameFontHighlight")
    row.count:SetPoint("RIGHT", -12, 0)
    row:SetScript("OnEnter", function(self)
        if not self.entry then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.entry.link then GameTooltip:SetHyperlink(self.entry.link)
        elseif self.entry.itemID then GameTooltip:SetItemByID(self.entry.itemID)
        else GameTooltip:SetText(self.entry.item or "") end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

function UI.SetCatch(row, entry)
    row.entry = entry
    row.icon:SetTexture(entry.icon or 134400)
    row.item:SetText(entry.item or "")
    local color = ITEM_QUALITY_COLORS[entry.quality or 1] or ITEM_QUALITY_COLORS[1]
    row.item:SetTextColor(color.r, color.g, color.b)
    row.count:SetText(entry.quantity)
    row:Show()
end
