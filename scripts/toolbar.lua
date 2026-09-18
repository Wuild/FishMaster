local _, ns = ...
local API, UI = ns.API, ns.UI
local Toolbar = {}
FishMaster.toolbar = Toolbar

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
    local frame = CreateFrame("Frame", "FishMaster_Toolbar", UIParent, "BackdropTemplate")
    self.frame = frame
    frame:Hide()
    frame:SetSize(390, 80)
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    UI.Position(frame, "toolbarPosition", 0, -210)
    UI.Drag(frame, "toolbarPosition")
    frame.title = UI.Text(frame, "FishMaster", "GameFontNormalSmall")
    frame.title:SetPoint("TOPLEFT", 12, -8)
    frame.state = UI.Text(frame, "", "GameFontHighlightSmall")
    frame.state:SetPoint("TOPRIGHT", -12, -8)
    local cast = UI.IconButton(frame, 38, true, "FishMasterCastButton")
    self.cast = cast
    cast:SetPoint("BOTTOMLEFT", 13, 13)
    cast.icon:SetTexture("Interface\\Icons\\INV_Fishingpole_02")
    cast:RegisterForClicks("AnyDown", "AnyUp")
    cast:SetAttribute("useOnKeyDown", false)
    UI.Tooltip(cast, API.FishingName(), FishMaster:translate("toolbar.castHelp"))
    cast:SetScript("PostClick", function()
        self:ClearOverride()
        FishMaster:ScheduleTimer(function() self:Refresh() end, .15)
    end)
    self.lures = {}
    for index, lure in ipairs(ns.lures) do
        local button = UI.IconButton(frame, 30, true, "FishMasterLureButton" .. index)
        button:SetPoint("LEFT", cast, "RIGHT", 15 + (index - 1) * 39, 0)
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
    frame:SetWidth(80 + #ns.lures * 39)
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
        button:SetAlpha(usable and 1 or .4)
        button.icon:SetDesaturated(not usable)
    end
    self.frame.state:SetText(lured and string.format("%s %d:%02d", FishMaster:translate("toolbar.lure"),
        math.floor((remaining or 0) / 60000), math.floor((remaining or 0) / 1000) % 60)
        or FishMaster:translate("toolbar.noLure"))
    if not FishMaster.db.char.easyCast then self:ClearOverride() end
end

function Toolbar:ClearOverride()
    if InCombatLockdown() then ns.clearBindingPending = true; return end
    if self.cast then ClearOverrideBindings(self.cast) end
    self.overrideUntil = nil
    ns.clearBindingPending = false
end

function Toolbar:OnWorldMouseDown(_, button)
    if button ~= "RightButton" or not FishMaster.db.char.easyCast or FishMaster:CheckCombat()
        or not FishMaster:IsPoleEquipped() or (LootFrame and LootFrame:IsShown()) then return end
    local now = GetTime()
    local previous = self.lastClick
    self.lastClick = now
    if not previous or now - previous > .4 or now - previous < .05 then return end
    self.lastClick = nil
    -- The second physical click's release activates the secure button.
    SetOverrideBindingClick(self.cast, true, "BUTTON2", self.cast:GetName(), "LeftButton")
    self.overrideUntil = now + .4
end

function Toolbar:Tick()
    if self.overrideUntil and GetTime() > self.overrideUntil then self:ClearOverride() end
end
