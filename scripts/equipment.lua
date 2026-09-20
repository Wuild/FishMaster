local _, ns = ...
local API, UI = ns.API, ns.UI
local Equipment = {}
FishMaster.equipment = Equipment

local function text(key) return FishMaster:translate(key) end

function Equipment:Create()
    if self.frame then return end
    local frame = CreateFrame("Frame", "FishMasterFrame", UIParent, "ButtonFrameTemplate")
    self.frame, ns.frame = frame, frame
    frame:Hide()
    frame:SetSize(540, 620)
    frame:EnableMouse(true)
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:SetTitle("FishMaster")
    frame:SetPortraitToAsset(ns.iconPath .. "Fishhook")
    ButtonFrameTemplate_HideButtonBar(frame)
    frame.Inset:ClearAllPoints()
    frame.Inset:SetPoint("TOPLEFT", 4, -62)
    frame.Inset:SetPoint("BOTTOMRIGHT", -6, 28)
    -- Forever's shared UIParentPanelManager owns placement and panel stacking.
    RegisterUIPanel(frame, { area = "left", pushable = 3, whileDead = 1, width = 540 })
    frame.CloseButton:SetScript("OnClick", function() HideUIPanel(frame) end)

    frame.skill = CreateFrame("StatusBar", nil, frame)
    frame.skill:SetPoint("TOPLEFT", 76, -37)
    frame.skill:SetPoint("TOPRIGHT", -22, -37)
    frame.skill:SetHeight(16)
    frame.skill:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.skill:SetStatusBarColor(.68, .45, .16)
    UI.Background(frame.skill, .03, .03, .03, .9)
    frame.skill.text = UI.Text(frame.skill, "", "GameFontHighlightSmall")
    frame.skill.text:SetPoint("CENTER")

    frame.pages, frame.tabs = {}, {}
    local labels = { text("tab.outfit"), text("tab.settings"), text("tab.loot") }
    for index, label in ipairs(labels) do
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", 20, -76)
        page:SetPoint("BOTTOMRIGHT", -20, 42)
        page:Hide()
        frame.pages[index] = page
        local tab = CreateFrame("Button", "FishMasterFrameTab" .. index, frame, "PanelTabButtonTemplate")
        tab:SetID(index)
        tab:SetText(label)
        if index == 1 then tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 14, 2) end
        tab:SetScript("OnClick", function() self:SelectTab(index) end)
        PanelTemplates_TabResize(tab, 16)
        frame.tabs[index] = tab
    end
    PanelTemplates_SetNumTabs(frame, 3)
    self:CreateOutfit(frame.pages[1])
    self:CreateSettings(frame.pages[2])
    self:CreateLog(frame.pages[3])
    frame.version = UI.Text(frame, "Forever  ·  " .. ns.version, "GameFontDisableSmall")
    frame.version:SetPoint("BOTTOMRIGHT", -18, 11)
    frame:SetScript("OnShow", function() self:Refresh() end)
    self:SelectTab(1)
end

function Equipment:SelectTab(index)
    PanelTemplates_SetTab(self.frame, index)
    for key, page in ipairs(self.frame.pages) do page:SetShown(key == index) end
    self:Refresh()
end

function Equipment:CreateOutfit(page)
    self.slots = {}
    local paper = CreateFrame("Frame", nil, page)
    paper:SetPoint("TOPLEFT")
    paper:SetPoint("BOTTOMLEFT")
    paper:SetPoint("TOPRIGHT")
    local background = UI.Background(paper, .065, .052, .038)
    UI.Atlas(background, "character-panel-background")
    background:SetVertexColor(1, .88, .70)
    UI.Border(paper, .55, .39, .19, .55)
    -- Recessed equipment rails frame the model without a colored panel fill.
    for _, edge in ipairs({ "LEFT", "RIGHT" }) do
        local rail = paper:CreateTexture(nil, "BORDER")
        rail:SetColorTexture(.015, .012, .009, .48)
        rail:SetPoint("TOP" .. edge, 0, -65)
        rail:SetPoint("BOTTOM" .. edge, 0, 94)
        rail:SetWidth(60)
    end
    local header = CreateFrame("Frame", nil, paper)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(60)
    UI.Background(header, .08, .058, .033, .75)
    local crest = header:CreateTexture(nil, "ARTWORK")
    crest:SetTexture(ns.iconPath .. "Fishhook")
    crest:SetSize(38, 38)
    crest:SetPoint("LEFT", 14, 0)
    local crestRing = header:CreateTexture(nil, "OVERLAY")
    crestRing:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    crestRing:SetSize(60, 60)
    crestRing:SetPoint("CENTER", crest, "CENTER", 0, -1)
    crestRing:SetVertexColor(.85, .65, .32)
    local title = UI.Text(header, UnitName("player"), "GameFontNormalHuge")
    title:SetPoint("TOP", 20, -7)
    title:SetTextColor(.95, .81, .52)
    title:SetWidth(400)
    title:SetJustifyH("CENTER")
    self.savedGear = UI.Text(header, "", "GameFontHighlightSmall")
    self.savedGear:SetPoint("TOP", 20, -37)
    self.savedGear:SetTextColor(.67, .60, .48)
    local trim = header:CreateTexture(nil, "OVERLAY")
    trim:SetColorTexture(.72, .56, .26, .8)
    trim:SetPoint("BOTTOMLEFT")
    trim:SetPoint("BOTTOMRIGHT")
    trim:SetHeight(1)

    local model = CreateFrame("DressUpModel", nil, paper)
    self.model = model
    model:SetPoint("TOPLEFT", 86, -65)
    model:SetPoint("BOTTOMRIGHT", -86, 145)
    model:SetFrameLevel(paper:GetFrameLevel() + 1)
    model.rotation, model.zoom = 0, 0
    model:EnableMouse(true)
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self.dragX = GetCursorPosition() end
    end)
    model:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    model:SetScript("OnHide", function(self) self.dragX = nil end)
    model:SetScript("OnUpdate", function(self)
        if not self.dragX then return end
        local x = GetCursorPosition()
        self.rotation = self.rotation + (x - self.dragX) / 100
        self:SetFacing(self.rotation)
        self.dragX = x
    end)
    model:SetScript("OnMouseWheel", function(self, delta)
        self.zoom = math.max(0, math.min(.8, self.zoom + delta * .1))
        self:SetPortraitZoom(self.zoom)
    end)
    local counts = { left = 0, right = 0 }
    local weapons = CreateFrame("Frame", nil, paper)
    weapons:SetPoint("BOTTOM", 0, 85)
    weapons:SetHeight(37)
    local weaponWidth, previousWeapon = 0, nil
    for _, slot in ipairs(ns.slots) do
        local button = FishMaster.ItemSlot:Create(paper, slot)
        button:SetFrameLevel(model:GetFrameLevel() + 2)
        if slot.side == "bottom" then
            -- Camelot uses a 6px gap between weapons and 19px for the ammo arrow.
            local gap = previousWeapon and (slot.id == 0 and 19 or 6) or 0
            if previousWeapon then
                button:SetPoint("LEFT", previousWeapon, "RIGHT", gap, 0)
            else
                button:SetPoint("LEFT", weapons, "LEFT", 0, 0)
            end
            weaponWidth = weaponWidth + gap + button:GetWidth()
            previousWeapon = button
        else
            local index = counts[slot.side]
            counts[slot.side] = index + 1
            if slot.side == "left" then button:SetPoint("TOPLEFT", 14, -72 - index * 43)
            else button:SetPoint("TOPRIGHT", -14, -72 - index * 43) end
        end
        self.slots[slot.name] = button
    end
    weapons:SetWidth(math.max(1, weaponWidth))
    local help = UI.Text(paper, text("outfit.help"), "GameFontDisableSmall")
    help:SetPoint("BOTTOM", 0, 51)
    help:SetWidth(460)
    help:SetJustifyH("CENTER")

    self.status = UI.Text(paper, "", "GameFontHighlightSmall")
    self.status:SetPoint("BOTTOM", 0, 133)
    self.status:SetWidth(460)
    self.status:SetJustifyH("CENTER")
    self.equip = UI.Button(paper, text("outfit.equip"), 150, function() FishMaster:Toggle() end)
    self.equip:SetPoint("BOTTOMLEFT", 17, 14)
    local capture = UI.Button(paper, text("outfit.capture"), 150, function()
        if FishMaster:CheckCombat() then return end
        for _, slot in ipairs(ns.slots) do
            FishMaster.db.char.outfit[slot.name] = GetInventoryItemID("player", slot.id)
        end
        self:Refresh()
    end)
    capture:SetPoint("LEFT", self.equip, "RIGHT", 8, 0)
    UI.Tooltip(capture, text("outfit.capture"), text("outfit.captureHelp"))
    local reset = UI.Button(paper, text("outfit.resetView"), 150, function()
        model.rotation, model.zoom = 0, 0
        model:SetFacing(0)
        model:SetPortraitZoom(0)
    end)
    reset:SetPoint("LEFT", capture, "RIGHT", 8, 0)
end

function Equipment:CreateSettings(page)
    self.settingsScroll = UI.Scroll(page, "FishMasterSettingsScroll")
    self.settingsScroll:SetPoint("TOPLEFT", 0, -4)
    self.settingsScroll:SetPoint("BOTTOMRIGHT", -26, 12)
    -- All settings live in one column; only the content grows vertically.
    page = self.settingsScroll.content
    page:SetSize(454, 1)
    local cursor = 0
    self.checks = {}
    local function section(key, icon)
        local heading = UI.Section(page, text(key), 454)
        heading:SetPoint("TOPLEFT", 0, -cursor)
        cursor = cursor + 43
        heading.Text:ClearAllPoints()
        heading.Text:SetPoint("LEFT", 46, 0)
        local art = heading:CreateTexture(nil, "ARTWORK")
        art:SetTexture(icon)
        art:SetSize(24, 24)
        art:SetPoint("LEFT", 12, 0)
        return heading
    end
    local function check(parent, key, get, set)
        local control = UI.Check(parent, text(key), get, set)
        control:SetPoint("TOPLEFT", 6, -cursor)
        control.Text:ClearAllPoints()
        control.Text:SetPoint("LEFT", control, "RIGHT", 8, 0)
        control.Text:SetWidth(382)
        control.Text:SetJustifyH("LEFT")
        control.Text:SetWordWrap(true)
        -- Include the label in the native checkbox's clickable area.
        control:SetHitRectInsets(0, -398, 0, 0)
        local highlight = control:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetPoint("TOPLEFT", -4, 2)
        highlight:SetSize(436, 33)
        highlight:SetAlpha(.25)
        local description = UI.Text(parent, text(key .. "Help"), "GameFontDisableSmall")
        description:SetPoint("TOPLEFT", 44, -cursor - 30)
        description:SetWidth(392)
        description:SetWordWrap(true)
        cursor = cursor + 30 + description:GetStringHeight() + 18
        table.insert(self.checks, { control = control, get = get, description = description })
        return control
    end
    local settings = FishMaster.db.char
    section("settings.general", ns.iconPath .. "Fishhook")
    check(page, "settings.minimap",
        function() return not FishMaster.db.profile.minimap.hide end,
        function(value) FishMaster.db.profile.minimap.hide = not value end)
    local keys = { "autoGear", "autoLure", "lowestLure", "easyCast" }
    local fields = { "autoEquip", "autoLure", "lowestLure", "easyCast" }
    for index, key in ipairs(keys) do
        local field = fields[index]
        local control = check(page, "settings." .. key,
            function() return settings[field] end, function(value) settings[field] = value end)
        if field == "easyCast" then UI.Tooltip(control, text("settings.easyCast"), text("settings.easyCastDescription")) end
    end
    section("settings.soundTitle", "Interface\\Icons\\INV_Misc_Bell_01")
    check(page, "settings.sound.enhance",
        function() return settings.audio.enabled end, function(value) settings.audio.enabled = value end)
    check(page, "settings.sound.force",
        function() return settings.audio.force end, function(value) settings.audio.force = value end)
    local volumeLabel = UI.Text(page, text("settings.volumeTitle"), "GameFontHighlightSmall")
    volumeLabel:SetPoint("TOPLEFT", 16, -cursor)
    local slider = CreateFrame("Frame", nil, page, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("TOPLEFT", 16, -cursor - 22)
    slider:SetWidth(295)
    slider:Init(settings.audio.volume * 100, 0, 100, 100, {
        [MinimalSliderWithSteppersMixin.Label.Right] = function(value) return string.format("%d%%", value) end,
    })
    slider:RegisterCallback("OnValueChanged", function(_, value)
        settings.audio.volume = value / 100
        FishMaster:SetAudio()
    end, self)
    self.volume = slider
    local volumeHelp = UI.Text(page, text("settings.volumeTitleHelp"), "GameFontDisableSmall")
    volumeHelp:SetPoint("TOPLEFT", 16, -cursor - 54)
    volumeHelp:SetWidth(420)
    volumeHelp:SetWordWrap(true)
    cursor = cursor + 54 + volumeHelp:GetStringHeight() + 24

    section("settings.trackingTitle", "Interface\\Icons\\INV_Misc_Fish_02")
    local trackKeys = { "show", "session", "trash" }
    local trackFields = { "enabled", "session", "hideTrash" }
    for index, key in ipairs(trackKeys) do
        local field = trackFields[index]
        check(page, "settings.tracker." .. key,
            function() return settings.tracker[field] end,
            function(value) settings.tracker[field] = value end)
    end
    section("settings.bobberTitle", "Interface\\Icons\\Trade_Fishing")
    local captureKey
    local keyButton = UI.Button(page, "", 205, function()
        if FishMaster:CheckCombat() then return end
        FishMaster.interaction.suspended = true
        FishMaster.interaction:Refresh()
        self.bobberKey.listening = true
        self.bobberKey:SetText(text("settings.pressKey"))
        self.bobberKey:SetScript("OnKeyDown", captureKey)
        self.bobberKey:EnableKeyboard(true)
        self.bobberKey:SetPropagateKeyboardInput(false)
    end)
    self.bobberKey = keyButton
    keyButton:SetPoint("TOPLEFT", 16, -cursor)
    keyButton:EnableKeyboard(false)
    keyButton:SetPropagateKeyboardInput(true)
    local function stopListening()
        keyButton.listening = false
        keyButton:SetScript("OnKeyDown", nil)
        keyButton:EnableKeyboard(false)
        keyButton:SetPropagateKeyboardInput(true)
        FishMaster.interaction.suspended = false
        FishMaster.interaction:Refresh()
        keyButton:SetText(FishMaster.interaction:KeyLabel())
    end
    -- Attach keyboard handling only while explicitly capturing a binding.
    captureKey = function(_, key)
        if not keyButton.listening then return end
        if key == "ESCAPE" or FishMaster:CheckCombat() then stopListening(); return end
        if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL"
            or key == "LALT" or key == "RALT" then return end
        if IsShiftKeyDown() then key = "SHIFT-" .. key end
        if IsControlKeyDown() then key = "CTRL-" .. key end
        if IsAltKeyDown() then key = "ALT-" .. key end
        FishMaster.interaction:SetKey(key)
        stopListening()
    end
    keyButton:SetScript("OnHide", function() if keyButton.listening then stopListening() end end)
    local clear = UI.Button(page, text("settings.clearKey"), 90, function()
        if FishMaster:CheckCombat() then return end
        FishMaster.interaction:SetKey(nil)
        stopListening()
    end)
    clear:SetPoint("LEFT", keyButton, "RIGHT", 8, 0)
    local keyHelp = UI.Text(page, text("settings.bobberHelp"), "GameFontHighlightSmall")
    keyHelp:SetPoint("TOPLEFT", 16, -cursor - 42)
    keyHelp:SetWidth(420)
    keyHelp:SetWordWrap(true)
    cursor = cursor + 42 + keyHelp:GetStringHeight() + 24
    local note = UI.Text(page, text("settings.saved"), "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", 16, -cursor)
    note:SetWidth(420)
    note:SetWordWrap(true)
    page:SetHeight(cursor + note:GetStringHeight() + 20)
end

function Equipment:CreateLog(page)
    self.logSession = true
    self.logRows = {}
    local title = UI.Text(page, text("log.title"), "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 4, -4)
    self.logTotal = UI.Text(page, "", "GameFontHighlight")
    self.logTotal:SetPoint("TOPLEFT", 4, -32)
    self.sessionButton = UI.Button(page, text("log.session"), 130, function()
        self.logSession = true; self.logScroll:SetVerticalScroll(0); self:RefreshLog()
    end)
    self.sessionButton:SetPoint("TOPLEFT", 0, -58)
    self.lifetimeButton = UI.Button(page, text("log.lifetime"), 130, function()
        self.logSession = false; self.logScroll:SetVerticalScroll(0); self:RefreshLog()
    end)
    self.lifetimeButton:SetPoint("LEFT", self.sessionButton, "RIGHT", 8, 0)
    self.logScroll = UI.Scroll(page, "FishMasterCatchLogScroll")
    self.logScroll:SetPoint("TOPLEFT", 0, -100)
    self.logScroll:SetPoint("BOTTOMRIGHT", -26, 12)
    self.logScroll.content:SetWidth(454)
    self.logEmpty = UI.Text(page, text("log.empty"), "GameFontDisable")
    self.logEmpty:SetPoint("CENTER")
    self.logEmpty:SetWidth(460)
    self.logEmpty:SetJustifyH("CENTER")
end

function Equipment:RefreshLog()
    local entries, total = FishMaster:GetCatches(self.logSession, nil, FishMaster.db.char.tracker.hideTrash)
    self.logTotal:SetText(text("log.total"):format(total))
    self.sessionButton:SetEnabled(not self.logSession)
    self.lifetimeButton:SetEnabled(self.logSession)
    self.logEmpty:SetShown(#entries == 0)
    for _, row in ipairs(self.logRows) do row:Hide() end
    for index, entry in ipairs(entries) do
        local row = self.logRows[index]
        if not row then
            row = UI.CatchRow(self.logScroll.content, 454)
            row:SetHeight(50)
            row.item:SetWordWrap(true)
            row:SetPoint("TOPLEFT", 0, -(index - 1) * 52)
            self.logRows[index] = row
        end
        UI.SetCatch(row, entry)
    end
    self.logScroll.content:SetHeight(math.max(1, #entries * 52))
end

function Equipment:RefreshModel()
    local signature, links = {}, {}
    for _, slot in ipairs(ns.slots) do
        if slot.id ~= 0 then
            local item = FishMaster.db.char.outfit[slot.name]
            local link
            if item then
                local itemName
                itemName, link = API.ItemInfo(item)
            end
            signature[#signature + 1] = tostring(GetInventoryItemID("player", slot.id) or 0)
            signature[#signature + 1] = tostring(item or 0)
            signature[#signature + 1] = link or ""
            if link then links[#links + 1] = link end
        end
    end
    local key = table.concat(signature, ";")
    if self.modelSignature == key then return end
    -- Cache before touching the model: item-info events can arrive during dressing.
    self.modelSignature = key
    self.model:SetUnit("player")
    self.model:Dress()
    for _, link in ipairs(links) do self.model:TryOn(link) end
    self.model:SetFacing(self.model.rotation)
    self.model:SetPortraitZoom(self.model.zoom)
end

function Equipment:Refresh()
    local frame = self.frame
    if not frame or not frame:IsShown() then return end
    local name, rank, _, maximum, bonus = API.Profession(API.FishingName())
    frame.skill:SetMinMaxValues(0, math.max(1, maximum or 1))
    frame.skill:SetValue(rank or 0)
    local skill = name and string.format("%s  %d / %d", name, rank, maximum) or text("outfit.unlearned")
    if bonus and bonus > 0 then skill = skill .. string.format("  |cffe8c477+%d|r", bonus) end
    frame.skill.text:SetText(skill)
    if frame.pages[1]:IsShown() then
        local saved = 0
        for _, slot in ipairs(ns.slots) do
            if FishMaster.db.char.outfit[slot.name] then saved = saved + 1 end
        end
        self.savedGear:SetText(text("outfit.savedGear"):format(saved))
        for _, button in pairs(self.slots) do FishMaster.ItemSlot:Refresh(button) end
        self:RefreshModel()
        self.status:SetText(FishMaster.gearSwap and text("outfit.changing")
            or (FishMaster.db.char.restorePending and text("outfit.recovery")) or "")
        self.equip:SetEnabled(not FishMaster.gearSwap)
        self.equip:SetText(FishMaster:ShouldRestoreOutfit() and text("outfit.restore") or text("outfit.equip"))
    elseif frame.pages[2]:IsShown() then
        for _, entry in ipairs(self.checks) do entry.control:SetChecked(entry.get()) end
        if not self.bobberKey.listening then self.bobberKey:SetText(FishMaster.interaction:KeyLabel()) end
    else
        self:RefreshLog()
    end
end

function Equipment:Toggle()
    if not self.frame then self:Create() end
    if self.frame:IsShown() then HideUIPanel(self.frame) else ShowUIPanel(self.frame) end
end
