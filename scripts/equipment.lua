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
    frame:SetSize(800, 620)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetTitle("FishMaster")
    frame:SetPortraitToAsset(ns.iconPath .. "Fishhook")
    ButtonFrameTemplate_HideButtonBar(frame)
    frame.Inset:ClearAllPoints()
    frame.Inset:SetPoint("TOPLEFT", 4, -62)
    frame.Inset:SetPoint("BOTTOMRIGHT", -6, 28)
    UI.Position(frame, "windowPosition")
    local drag = CreateFrame("Frame", nil, frame)
    drag:SetPoint("TOPLEFT", 65, -2)
    drag:SetPoint("TOPRIGHT", -30, -2)
    drag:SetHeight(28)
    UI.Drag(frame, "windowPosition", drag)
    table.insert(UISpecialFrames, "FishMasterFrame")
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)

    frame.skill = CreateFrame("StatusBar", nil, frame)
    frame.skill:SetPoint("TOPLEFT", 76, -37)
    frame.skill:SetPoint("TOPRIGHT", -22, -37)
    frame.skill:SetHeight(16)
    frame.skill:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.skill:SetStatusBarColor(.12, .42, .65)
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
    paper:SetWidth(520)
    local background = UI.Background(paper, .045, .045, .055)
    UI.Atlas(background, "character-panel-background")

    local model = CreateFrame("DressUpModel", nil, paper)
    self.model = model
    model:SetPoint("TOPLEFT", 106, -24)
    model:SetPoint("BOTTOMRIGHT", -106, 90)
    model:SetFrameLevel(paper:GetFrameLevel() + 1)
    model:SetUnit("player")
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
    local counts = { left = 0, right = 0, bottom = 0 }
    local bottomCount = 0
    for _, slot in ipairs(ns.slots) do
        if slot.side == "bottom" then bottomCount = bottomCount + 1 end
    end
    local bottomStart = (520 - (bottomCount * 38 + (bottomCount - 1) * 54)) / 2
    for _, slot in ipairs(ns.slots) do
        local button = FishMaster.ItemSlot:Create(paper, slot)
        button:SetFrameLevel(model:GetFrameLevel() + 2)
        local index = counts[slot.side]
        counts[slot.side] = index + 1
        if slot.side == "left" then button:SetPoint("TOPLEFT", 14, -14 - index * 47)
        elseif slot.side == "right" then button:SetPoint("TOPRIGHT", -14, -14 - index * 47)
        else button:SetPoint("BOTTOMLEFT", bottomStart + index * 92, 49) end
        self.slots[slot.name] = button
    end
    local help = UI.Text(paper, text("outfit.help"), "GameFontDisableSmall")
    help:SetPoint("BOTTOM", 0, 10)
    help:SetWidth(495)
    help:SetJustifyH("CENTER")

    local side = CreateFrame("Frame", nil, page)
    side:SetPoint("TOPLEFT", paper, "TOPRIGHT", 14, 0)
    side:SetPoint("BOTTOMRIGHT")
    UI.Background(side, .065, .065, .075)
    local section = UI.Section(side, text("outfit.summary"), 220)
    section:SetPoint("TOP", 0, -4)
    self.character = UI.Text(side, UnitName("player"), "GameFontNormalLarge")
    self.character:SetPoint("TOPLEFT", 14, -50)
    self.character:SetWidth(194)
    self.status = UI.Text(side, "", "GameFontHighlight")
    self.status:SetPoint("TOPLEFT", 14, -81)
    self.status:SetWidth(194)
    self.pole = UI.Text(side, "", "GameFontHighlightSmall")
    self.pole:SetPoint("TOPLEFT", 14, -119)
    self.pole:SetWidth(194)
    self.pole:SetWordWrap(true)
    self.lure = UI.Text(side, "", "GameFontHighlightSmall")
    self.lure:SetPoint("TOPLEFT", 14, -176)
    self.lure:SetWidth(194)
    self.lure:SetWordWrap(true)
    self.catches = UI.Text(side, "", "GameFontNormal")
    self.catches:SetPoint("TOPLEFT", 14, -235)
    self.catches:SetWidth(194)
    self.equip = UI.Button(side, text("outfit.equip"), 190, function() FishMaster:Toggle() end)
    self.equip:SetPoint("BOTTOM", 0, 103)
    local capture = UI.Button(side, text("outfit.capture"), 190, function()
        if FishMaster:CheckCombat() then return end
        for _, slot in ipairs(ns.slots) do
            FishMaster.db.char.outfit[slot.name] = GetInventoryItemID("player", slot.id)
        end
        self:Refresh()
    end)
    capture:SetPoint("BOTTOM", 0, 68)
    UI.Tooltip(capture, text("outfit.capture"), text("outfit.captureHelp"))
    local reset = UI.Button(side, text("outfit.resetView"), 190, function()
        model.rotation, model.zoom = 0, 0
        model:SetFacing(0)
        model:SetPortraitZoom(0)
    end)
    reset:SetPoint("BOTTOM", 0, 33)
end

function Equipment:CreateSettings(page)
    self.checks = {}
    local function check(parent, key, x, y, get, set)
        local control = UI.Check(parent, text(key), get, set)
        control:SetPoint("TOPLEFT", x, y)
        table.insert(self.checks, { control = control, get = get })
        return control
    end
    local settings = FishMaster.db.char
    local general = UI.Section(page, text("settings.general"), 355)
    general:SetPoint("TOPLEFT")
    check(page, "settings.minimap", 6, -43,
        function() return not FishMaster.db.profile.minimap.hide end,
        function(value) FishMaster.db.profile.minimap.hide = not value end)
    local keys = { "autoGear", "autoLure", "lowestLure", "easyCast" }
    local fields = { "autoEquip", "autoLure", "lowestLure", "easyCast" }
    for index, key in ipairs(keys) do
        local field = fields[index]
        local control = check(page, "settings." .. key, 6, -43 - index * 38,
            function() return settings[field] end, function(value) settings[field] = value end)
        if field == "easyCast" then UI.Tooltip(control, text("settings.easyCast"), text("settings.easyCastDescription")) end
    end
    check(page, "settings.debug", 6, -251,
        function() return FishMaster.db.global.debug end,
        function(value) FishMaster.db.global.debug = value end)
    local sound = UI.Section(page, text("settings.soundTitle"), 355)
    sound:SetPoint("TOPLEFT", 0, -310)
    check(page, "settings.sound.enhance", 6, -350,
        function() return settings.audio.enabled end, function(value) settings.audio.enabled = value end)
    check(page, "settings.sound.force", 6, -388,
        function() return settings.audio.force end, function(value) settings.audio.force = value end)
    local volumeLabel = UI.Text(page, text("settings.volumeTitle"), "GameFontHighlightSmall")
    volumeLabel:SetPoint("TOPLEFT", 16, -427)
    local slider = CreateFrame("Frame", nil, page, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("TOPLEFT", 16, -445)
    slider:SetWidth(295)
    slider:Init(settings.audio.volume * 100, 0, 100, 100, {
        [MinimalSliderWithSteppersMixin.Label.Right] = function(value) return string.format("%d%%", value) end,
    })
    slider:RegisterCallback("OnValueChanged", function(_, value)
        settings.audio.volume = value / 100
        FishMaster:SetAudio()
    end, self)
    self.volume = slider

    local tracking = UI.Section(page, text("settings.trackingTitle"), 355)
    tracking:SetPoint("TOPLEFT", 392, 0)
    local trackKeys = { "show", "session", "trash" }
    local trackFields = { "enabled", "session", "hideTrash" }
    for index, key in ipairs(trackKeys) do
        local field = trackFields[index]
        check(page, "settings.tracker." .. key, 398, -43 - (index - 1) * 38,
            function() return settings.tracker[field] end,
            function(value) settings.tracker[field] = value end)
    end
    local note = UI.Text(page, text("settings.saved"), "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", 405, -196)
    note:SetWidth(310)
    note:SetWordWrap(true)
end

function Equipment:CreateLog(page)
    self.logSession = true
    self.logRows = {}
    local title = UI.Text(page, text("log.title"), "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 4, -4)
    self.logTotal = UI.Text(page, "", "GameFontHighlight")
    self.logTotal:SetPoint("TOPRIGHT", -4, -6)
    self.sessionButton = UI.Button(page, text("log.session"), 130, function()
        self.logSession = true; self.logScroll:SetVerticalScroll(0); self:RefreshLog()
    end)
    self.sessionButton:SetPoint("TOPLEFT", 0, -35)
    self.lifetimeButton = UI.Button(page, text("log.lifetime"), 130, function()
        self.logSession = false; self.logScroll:SetVerticalScroll(0); self:RefreshLog()
    end)
    self.lifetimeButton:SetPoint("LEFT", self.sessionButton, "RIGHT", 8, 0)
    self.logScroll = UI.Scroll(page, "FishMasterCatchLogScroll")
    self.logScroll:SetPoint("TOPLEFT", 0, -80)
    self.logScroll:SetPoint("BOTTOMRIGHT", -26, 12)
    self.logScroll.content:SetWidth(714)
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
            row = UI.CatchRow(self.logScroll.content, 714)
            row:SetPoint("TOPLEFT", 0, -(index - 1) * 36)
            self.logRows[index] = row
        end
        UI.SetCatch(row, entry)
    end
    self.logScroll.content:SetHeight(math.max(1, #entries * 36))
end

function Equipment:Refresh()
    local frame = self.frame
    if not frame or not frame:IsShown() then return end
    local name, rank, _, maximum, bonus = API.Profession(API.FishingName())
    frame.skill:SetMinMaxValues(0, math.max(1, maximum or 1))
    frame.skill:SetValue(rank or 0)
    local skill = name and string.format("%s  %d / %d", name, rank, maximum) or text("outfit.unlearned")
    if bonus and bonus > 0 then skill = skill .. string.format("  |cff69ccf0+%d|r", bonus) end
    frame.skill.text:SetText(skill)
    if frame.pages[1]:IsShown() then
        for _, button in pairs(self.slots) do FishMaster.ItemSlot:Refresh(button) end
        self.model:SetUnit("player")
        self.model:Dress()
        for _, slot in ipairs(ns.slots) do
            local item = FishMaster.db.char.outfit[slot.name]
            if item and slot.id ~= 0 then
                local _, link = API.ItemInfo(item)
                if link then self.model:TryOn(link) end
            end
        end
        self.model:SetFacing(self.model.rotation)
        self.model:SetPortraitZoom(self.model.zoom)
        local enabled = FishMaster.db.char.enabled
        self.status:SetText(enabled and text("outfit.active") or text("outfit.ready"))
        self.equip:SetText(enabled and text("outfit.restore") or text("outfit.equip"))
        local pole = FishMaster.db.char.outfit.MainHandSlot
        self.pole:SetText(text("outfit.pole") .. "\n" .. (pole and API.ItemInfo(pole) or text("outfit.noPole")))
        local lure = FishMaster:FindBestLure()
        self.lure:SetText(text("outfit.lure") .. "\n" .. (lure and (API.ItemInfo(lure.item) or tostring(lure.item)) or text("outfit.noLure")))
        local _, count = FishMaster:GetCatches(true)
        self.catches:SetText(text("log.total"):format(count))
    elseif frame.pages[2]:IsShown() then
        for _, entry in ipairs(self.checks) do entry.control:SetChecked(entry.get()) end
    else
        self:RefreshLog()
    end
end

function Equipment:Toggle()
    if not self.frame then self:Create() end
    self.frame:SetShown(not self.frame:IsShown())
end
