local _, ns = ...
local UI = ns.UI
local Tracker = {}
FishMaster.tracker = Tracker

function Tracker:Create()
    if self.frame then return end
    local frame = CreateFrame("Frame", "FishMaster_Tracker", UIParent)
    self.frame = frame
    frame:Hide()
    frame:SetSize(310, 110)
    frame:SetFrameStrata("MEDIUM")
    UI.Position(frame, "trackerPosition", 330, -140)
    UI.Drag(frame, "trackerPosition")
    frame.title = UI.Text(frame, "", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", 12, -12)
    frame.zone = UI.Text(frame, "", "GameFontDisableSmall")
    frame.zone:SetPoint("TOPLEFT", 12, -33)
    frame.zone:SetWidth(285)
    frame.empty = UI.Text(frame, FishMaster:translate("tracker.empty"), "GameFontDisableSmall")
    frame.empty:SetPoint("TOPLEFT", 12, -61)
    frame.more = CreateFrame("Button", nil, frame)
    frame.more:SetSize(150, 26)
    frame.more.label = UI.Text(frame.more, FishMaster:translate("log.open"), "GameFontNormalSmall")
    frame.more.label:SetPoint("CENTER")
    frame.more:SetScript("OnClick", function()
        FishMaster.equipment.frame:Show()
        FishMaster.equipment:SelectTab(3)
    end)
    frame.more:SetScript("OnEnter", function(self) self.label:SetTextColor(1, 1, 1) end)
    frame.more:SetScript("OnLeave", function(self) self.label:SetTextColor(1, .82, 0) end)
    frame.more:SetPoint("BOTTOM", 0, 8)
    self.rows = {}
end

function Tracker:Refresh()
    if not self.frame then return end
    local settings = FishMaster.db.char.tracker
    local frame = self.frame
    frame:SetShown(settings.enabled and FishMaster:IsPoleEquipped())
    if not frame:IsShown() then return end
    local zone = GetMinimapZoneText()
    local entries, total = FishMaster:GetCatches(settings.session, zone, settings.hideTrash)
    frame.title:SetText(FishMaster:translate(settings.session and "mode.session" or "mode.lifetime", total))
    frame.zone:SetText(zone)
    frame.empty:SetShown(#entries == 0)
    for _, row in ipairs(self.rows) do row:Hide() end
    for index = 1, math.min(6, #entries) do
        local row = self.rows[index]
        if not row then
            row = UI.CatchRow(frame, 288, true)
            row:SetPoint("TOPLEFT", 10, -55 - (index - 1) * 36)
            self.rows[index] = row
        end
        UI.SetCatch(row, entries[index])
    end
    frame:SetHeight(100 + math.max(1, math.min(6, #entries)) * 36)
end
