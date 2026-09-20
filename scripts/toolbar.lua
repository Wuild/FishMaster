local _, ns = ...
local API, UI = ns.API, ns.UI
local Toolbar = {}
FishMaster.toolbar = Toolbar

local function stopMouselook()
    if IsMouselooking() then MouselookStop() end
end

local function bindItem(button, itemID, suffix)
    suffix = suffix or ""
    local bag, slot = API.FindItem(itemID)
    button:SetAttribute("type" .. suffix, bag and "item" or nil)
    button:SetAttribute("item" .. suffix, bag and (bag .. " " .. slot) or nil)
    button:SetAttribute("spell" .. suffix, nil)
    button:SetAttribute("target-slot" .. suffix, bag and 16 or nil)
end

function Toolbar:Create()
    if self.frame then return end
    local frame = CreateFrame("Frame", "FishMaster_Toolbar", UIParent)
    self.frame = frame
    frame:Hide()
    frame:SetSize(390, 82)
    frame:SetFrameStrata("MEDIUM")
    UI.Position(frame, "toolbarPosition", 0, -210)
    UI.Drag(frame, "toolbarPosition")
    frame.title = UI.Text(frame, "FishMaster", "GameFontNormalSmall")
    frame.title:SetPoint("TOPLEFT", 12, -8)
    frame.state = UI.Text(frame, "", "GameFontHighlightSmall")
    frame.state:SetPoint("TOPRIGHT", -12, -8)
    local cast = UI.ActionButton(frame, 45, "FishMasterCastButton")
    self.cast = cast
    cast:SetPoint("BOTTOMLEFT", 13, 13)
    cast.icon:SetTexture("Interface\\Icons\\INV_Fishingpole_02")
    cast:RegisterForClicks("AnyDown", "AnyUp")
    cast:SetAttribute("useOnKeyDown", false)
    UI.Tooltip(cast, API.FishingName(), FishMaster:translate("toolbar.castHelp"))
    cast:SetScript("PreClick", function(_, _, down)
        if not self.overrideUntil then return end
        if down then self.overridePressed = true end
        -- The world may have started right-button camera control before the
        -- secure cast receives this input. End it before executing the action.
        stopMouselook()
    end)
    cast:SetScript("PostClick", function(_, _, down)
        if down then self.overridePressed = self.overrideUntil ~= nil; return end
        self.lastCastClick = GetTime()
        self:ClearOverride()
        FishMaster:ScheduleTimer(function() self:Refresh() end, .15)
    end)
    self.lures = {}
    local previous = cast
    for index, lure in ipairs(ns.lures) do
        local button = UI.ActionButton(frame, 30, "FishMasterLureButton" .. index)
        button:SetPoint("LEFT", previous, "RIGHT", 2, 0)
        previous = button
        button.icon:SetTexture(lure.icon)
        button:RegisterForClicks("AnyDown", "AnyUp")
        button:SetAttribute("useOnKeyDown", false)
        button.lure = lure
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetItemByID(lure.item)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.lures[index] = button
    end
    frame:SetWidth(26 + 45 + #ns.lures * 32)
end

function Toolbar:Refresh()
    if not self.frame or FishMaster:CheckCombat() then return end
    local pole = FishMaster:IsPoleEquipped()
    self.frame:SetShown(pole)
    if not pole then self:ClearOverride(); return end
    local lured, remaining = FishMaster:IsLured()
    local lure = FishMaster:FindBestLure()
    local cast = self.cast
    if not lured and lure and FishMaster.db.char.autoLure then
        bindItem(cast, lure.item, "1")
    else
        cast:SetAttribute("type1", "spell")
        cast:SetAttribute("spell1", API.FishingName())
        cast:SetAttribute("item1", nil)
        cast:SetAttribute("target-slot1", nil)
    end
    if lure then bindItem(cast, lure.item, "2")
    else
        cast:SetAttribute("type2", "spell")
        cast:SetAttribute("spell2", API.FishingName())
        cast:SetAttribute("item2", nil)
        cast:SetAttribute("target-slot2", nil)
    end
    local skill = FishMaster:GetProfessionLevel(API.FishingName())
    for _, button in ipairs(self.lures) do
        local count = API.ItemCount(button.lure.item)
        button.count:SetText(count)
        local usable = count > 0 and skill >= button.lure.skill
        if usable then bindItem(button, button.lure.item)
        else
            button:SetAttribute("type", nil)
            button:SetAttribute("item", nil)
            button:SetAttribute("target-slot", nil)
        end
        button.icon:SetAlpha(usable and 1 or .4)
        button.icon:SetDesaturated(not usable)
    end
    self.frame.state:SetText(lured and string.format("%s %d:%02d", FishMaster:translate("toolbar.lure"),
        math.floor((remaining or 0) / 60000), math.floor((remaining or 0) / 1000) % 60)
        or FishMaster:translate("toolbar.noLure"))
    if not FishMaster.db.char.easyCast then self:ClearOverride() end
end

function Toolbar:ClearOverride()
    -- A cast can consume the release normally handled by the world's camera
    -- binding. Also clean up if the gesture is cancelled after its second down.
    if self.overridePressed then stopMouselook() end
    if InCombatLockdown() then ns.clearBindingPending = true; return end
    if self.cast then ClearOverrideBindings(self.cast) end
    self.overrideUntil = nil
    self.overridePressed = nil
    self.worldPress = nil
    ns.clearBindingPending = false
end

function Toolbar:OnWorldMouseDown(_, button)
    self.worldPress = nil
    if button ~= "RightButton" or not FishMaster.db.char.easyCast or FishMaster:CheckCombat()
        or not FishMaster:IsPoleEquipped() or (LootFrame and LootFrame:IsShown())
        or UnitCastingInfo("player") or UnitChannelInfo("player") or CursorHasItem() then return end
    local x, y = GetCursorPosition()
    self.worldPress = { time = GetTime(), x = x, y = y }
end

function Toolbar:OnWorldMouseUp(_, button)
    local press = self.worldPress
    self.worldPress = nil
    if button ~= "RightButton" or not press or FishMaster:CheckCombat() then return end
    local now, x, y = GetTime(), GetCursorPosition()
    if now - press.time > .3 or math.abs(x - press.x) + math.abs(y - press.y) > 10
        or (self.lastCastClick and now - self.lastCastClick < .1) then return end
    -- Install after the FIRST release so the next physical press/release pair
    -- is routed through the secure button. Installing on the second down is late.
    stopMouselook()
    SetOverrideBindingClick(self.cast, true, "BUTTON2", self.cast:GetName(), "LeftButton")
    self.overrideUntil = now + .4
end

function Toolbar:Tick()
    if self.overrideUntil and GetTime() > self.overrideUntil and not self.overridePressed then self:ClearOverride() end
end
