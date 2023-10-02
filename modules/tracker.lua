local name, _fish = ...;

local Tracker = FishMaster.modules:NewModule("Tracker")

local currentZone = GetMinimapZoneText()

local frame;

local lootFramePool;

function Tracker:CreateFrame()
    frame = CreateFrame("Frame", "FishMaster_Tracker", UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetClampedToScreen(true)
    frame:SetPoint("CENTER", 0, 0)
    frame:SetSize(400, 258)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:Hide()

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(32)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText("Tracker")

    local zone = header:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    zone:SetPoint("TOPRIGHT", 0, 0)
    zone:SetText("Tracker")

    local profession = header:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    profession:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    profession:SetText("Fishing: 159")

    local mode = header:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    mode:SetPoint("TOPRIGHT", zone, "BOTTOMRIGHT", 0, 0)
    mode:SetText("Session")

    frame.header = header;
    frame.header.title = title
    frame.header.zone = zone
    frame.header.profession = profession
    frame.header.mode = mode

    Tracker.frame = frame;

end

function Tracker:CreateLootList()
    local frame = CreateFrame("ScrollFrame", nil, Tracker.frame)
    frame:SetPoint("TOPLEFT", Tracker.frame.header, "BOTTOMLEFT", 0, 0)
    frame:SetPoint("BOTTOMRIGHT", 0, 0)

    lootFramePool = CreateFramePool("FRAME", frame, "FMLootItemTemplate")
end

function Tracker:UpdateFrame()
    Tracker:SetInfo()

    lootFramePool:ReleaseAll();

    local lastAnchor;
    local statFrame = lootFramePool:Acquire();

    local zone = GetMinimapZoneText();
    local db = FishMaster.db.char.loot;

    if FishMaster.db.char.tracker.session then
        db = FishMaster.sessionLoot;
    end

    local fishes = FishMaster:TableFilter(db, function(loot)
        if FishMaster.db.char.hideTrash then
            return loot.quality > 0 and loot.zone == zone
        end
        return loot.zone == zone;
    end);

    table.sort(fishes, function(a, b)
        return a.quantity > b.quantity
    end);

    for i, fish in pairs(fishes) do

        if not lastAnchor then
            statFrame:SetPoint("TOPLEFT", 0, 0);
        else
            statFrame:SetPoint("TOP", lastAnchor, "BOTTOM", 0, 0)
        end

        statFrame.text:SetText(fish.item)
        statFrame.count:SetText(fish.quantity)
        statFrame.icon.texture:SetTexture(fish.icon)

        statFrame:Show()
        lastAnchor = statFrame;
        statFrame = lootFramePool:Acquire();
    end

end

function Tracker:SetInfo()
    local sName, sRank, numTempPoints, sMaxRank, skillModifier, sDescription = FishMaster:GetProfessionInfo(PROFESSIONS_FISHING)

    if sName then
        if skillModifier and skillModifier > 0 then
            frame.header.profession:SetText(string.format("%s: %s/%s %s", sName, sRank, sMaxRank, FishMaster:Colorize("+" .. skillModifier, "green")))
        else
            frame.header.profession:SetText(string.format("%s: %s/%s", sName, sRank, sMaxRank))
        end
    end

    local zone = GetMinimapZoneText();
    frame.header.zone:SetText(zone)
end

function Tracker:OnInitialize()
    Tracker:CreateFrame()
    Tracker:CreateLootList()
end

function Tracker:OnEnable()
    currentZone = GetMinimapZoneText()

    self:RegisterEvent("ZONE_CHANGED", "EventHandler")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "EventHandler")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "EventHandler")
    self:RegisterEvent("UNIT_AURA", "EventHandler");

    self:RegisterMessage("FISHMASTER_LOOT_ADDED", "MessageHandler")

    Tracker:UpdateFrame()

    frame:Show()
end

function Tracker:OnDisable()
    self:UnregisterEvent("ZONE_CHANGED")
    self:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("UNIT_AURA")

    frame:Hide()
end

function Tracker:EventHandler(event, target, ...)
    Tracker:UpdateFrame()
    currentZone = GetMinimapZoneText();

end

function Tracker:MessageHandler(message)
    if message == "FISHMASTER_LOOT_ADDED" then
        Tracker:UpdateFrame()
    end
end