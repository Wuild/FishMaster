local name, _FishMaster = ...;

FishMaster.tracker = {};

function FishMaster.tracker:CreateLine(key, fish)
    GetItemInfo(fish.item)

    local index = key

    local frame;

    if not FishMaster_Tracker.holder.lines[key] then
        frame = CreateFrame("FRAME", "$parentLine" .. key, FishMaster_Tracker.holder, "FishMaster_TrackerFishLine")
    else
        frame = FishMaster_Tracker.holder.lines[key]
    end

    frame:SetAttribute("item", fish.item)

    frame.text:SetText(fish.item)
    frame.count:SetText(fish.quantity)
    frame.icon.texture:SetTexture(fish.icon)
    if index > 1 then
        frame:SetPoint("TOPLEFT", "$parentLine" .. (index - 1), "BOTTOMLEFT");
    end

    frame:Show()
end

function FishMaster.tracker:UpdateSize()
    local height = FishMaster_Tracker.defaultHeight;

    for key, line in pairs(FishMaster_Tracker.holder.lines) do
        if line:IsVisible() then
            height = height + line:GetHeight();
        end
    end

    FishMaster_Tracker:SetHeight(height);
end

function FishMaster.tracker.Load()
    FishMaster.tracker.Update();
end

function FishMaster.tracker:OnEvent(frame, event, ...)
    FishMaster.tracker.Update()
    FishMaster.tracker.SetInfo();
end

function FishMaster.tracker.Update()
    local zone = GetMinimapZoneText();

    local loot;

    if FishMaster.db.char.tracker.session then
        loot = _FishMaster.session;
    else
        loot = FishMaster.db.char.loot;
    end

    local fishes = table.filter(loot, function(loot)
        if FishMaster.db.char.hideTrash then
            return loot.quality > 0 and loot.zone == zone
        end
        return loot.zone == zone;
    end);

    table.sort(fishes, function(a, b)
        return a.quantity > b.quantity
    end);

    for key, line in pairs(FishMaster_Tracker.holder.lines) do
        line:Hide()
    end

    local i = 1;
    for key, loot in pairs(fishes) do
        FishMaster.tracker:CreateLine(i, loot);
        i = i + 1;
    end

    FishMaster.tracker:UpdateSize()

end

function FishMaster.tracker.TotalFish()
    local count = 0;

    local loot;
    local zone = GetMinimapZoneText();
    if FishMaster.db.char.tracker.session then
        loot = _FishMaster.session;
    else
        loot = FishMaster.db.char.loot;
    end

    local fishes = table.filter(loot, function(loot)
        if FishMaster.db.char.hideTrash then
            return loot.quality > 0 and loot.zone == zone
        end
        return loot.zone == zone;
    end);

    for key, loot in pairs(fishes) do
        count = count + loot.quantity;
    end
    return count;
end

function FishMaster.tracker.SetInfo()
    local sName, sRank, numTempPoints, sMaxRank, skillModifier, sDescription = FishMaster:GetProfessionInfo(PROFESSIONS_FISHING)

    if sName then
        if skillModifier and  skillModifier > 0 then
            FishMaster_Tracker.title.profession:SetText(string.format("%s: %s/%s %s", sName, sRank, sMaxRank, FishMaster:Colorize("+" .. skillModifier, "green")))
        else
            FishMaster_Tracker.title.profession:SetText(string.format("%s: %s/%s", sName, sRank, sMaxRank))
        end
    end

    local zone = GetMinimapZoneText();
    FishMaster_Tracker.title.zone:SetText(zone)

    local mode;

    if FishMaster.db.char.tracker.session then
        mode = FishMaster:translate("mode.session", FishMaster.tracker.TotalFish());
    else
        mode = FishMaster:translate("mode.lifetime", FishMaster.tracker.TotalFish());
    end

    FishMaster_Tracker.title.mode:SetText(mode);

end

function FishMaster.tracker.OnLoad()


end

function FishMaster.tracker:OnUpdate(self)


    --if self:GetHeight() ~= height then
    --    print(height)
    --    self:SetHeight(height)
    --end

end

