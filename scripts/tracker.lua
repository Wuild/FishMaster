local name, _FishMaster = ...;

FishMaster.tracker = {};
FishMaster.lootTab = {};

function FishMaster.lootTab:GetFrame()
    if _FishMaster.frame and _FishMaster.frame.Loot then
        return _FishMaster.frame.Loot
    end
    return _G["FishMasterFrameLoot"]
end

function FishMaster.lootTab:OnLoad(frame)
    if not frame then
        return
    end
    if frame.scroll and frame.scroll.content then
        frame.scroll:SetScrollChild(frame.scroll.content)
    end
end

function FishMaster.lootTab:Update()
    if InCombatLockdown() then
        return
    end
    local frame = FishMaster.lootTab:GetFrame()
    if not frame or not frame.scroll or not frame.scroll.content then
        return
    end

    frame.lines = frame.lines or {}
    local content = frame.scroll.content

    local totals = {}
    for _, loot in pairs(FishMaster.db.char.loot or {}) do
        if not FishMaster.db.char.hideTrash or (loot.quality and loot.quality > 0) then
            local key = loot.item or ""
            if key ~= "" then
                local entry = totals[key]
                if not entry then
                    totals[key] = {
                        item = loot.item,
                        icon = loot.icon,
                        quantity = loot.quantity or 0
                    }
                else
                    entry.quantity = (entry.quantity or 0) + (loot.quantity or 0)
                end
            end
        end
    end

    local lootList = {}
    for _, entry in pairs(totals) do
        table.insert(lootList, entry)
    end

    table.sort(lootList, function(a, b)
        return (a.quantity or 0) > (b.quantity or 0)
    end)

    for _, line in pairs(frame.lines) do
        line:Hide()
    end

    local height = 6
    local y = -4
    for i, loot in ipairs(lootList) do
        local line = frame.lines[i]
        if not line then
            line = CreateFrame("FRAME", nil, content, "FMLootLineTemplate")
            frame.lines[i] = line
        end

        line.icon:SetTexture(loot.icon)
        line.item:SetText(loot.item or "")
        line.count:SetText(tostring(loot.quantity or 0))
        line:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
        line:Show()

        y = y - line:GetHeight()
        height = height + line:GetHeight()
    end

    content:SetHeight(height)
end

function FishMaster.tracker:CreateLine(key, fish)
    if InCombatLockdown() then
        return
    end

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

    if InCombatLockdown() then
        return
    end

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
    if InCombatLockdown() then
        return
    end

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
        if skillModifier and skillModifier > 0 then
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
