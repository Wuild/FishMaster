local name, _FishMaster = ...;

FishMaster.equipment = {};

_FishMaster.dragging = {
    item = nil,
    bag = nil,
    slot = nil
};

local frameName = "FishMasterFrame"

local function FM_PickupContainerItem(bag, slot)
    local _, _, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(bag, slot);
    _FishMaster.dragging.bag = bag
    _FishMaster.dragging.slot = slot
    _FishMaster.dragging.item = itemID
end

local function FM_PickupInventoryItem(slot)
    _FishMaster.dragging.slot = slot
    _FishMaster.dragging.item = GetInventoryItemID("player", slot)
end

local function SafeHookFunction(func, newfunc)
    if (type(newfunc) == "string") then
        newfunc = _G[newfunc];
    end
    if (_G[func] ~= newfunc) then
        hooksecurefunc(func, newfunc);
        return true;
    end
    return false;
end

function FishMaster:UpdateModel()
    local model;

    local ItemSlots = { _G[frameName .. "Outfit"]:GetChildren() }
    model = _G[frameName .. "OutfitModel"];
    model:Dress();

    for _, slot in pairs(ItemSlots) do
        if slot:GetAttribute("slot") and slot:GetAttribute("itemID") then
            local _, link = GetItemInfo(slot:GetAttribute("itemID"));
            model:TryOn(link, slot:GetAttribute("slot"));
        end
    end
end

function FishMaster.equipment:OnModelLoad(model)
    Model_OnLoad(model);
    local race, fileName = UnitRace("player");
    local texture = DressUpTexturePath(fileName);

    model.BackgroundTopLeft:SetTexture(texture .. 1);
    model.BackgroundTopLeft:SetDesaturated(true);
    model.BackgroundTopRight:SetTexture(texture .. 2);
    model.BackgroundTopRight:SetDesaturated(true);
    model.BackgroundBotLeft:SetTexture(texture .. 3);
    model.BackgroundBotLeft:SetDesaturated(true);
    model.BackgroundBotRight:SetTexture(texture .. 4);
    model.BackgroundBotRight:SetDesaturated(true);

    if (strupper(fileName) == "NIGHTELF") then
        model.BackgroundOverlay:SetAlpha(0.6);
    elseif (strupper(fileName) == "SCOURGE") then
        model.BackgroundOverlay:SetAlpha(0.3);
    elseif (strupper(fileName) == "ORC") then
        model.BackgroundOverlay:SetAlpha(0.6);
    else
        model.BackgroundOverlay:SetAlpha(0.7);
    end

    model:RegisterEvent("DISPLAY_SIZE_CHANGED");
    model:RegisterEvent("UNIT_MODEL_CHANGED");
    model:RegisterEvent("PLAYER_ENTERING_WORLD");
end

function FishMaster.equipment:OnLoad()
    _FishMaster.frame = CreateFrame("FRAME", frameName, UIParent, "FishMasterTopFrame");
    _FishMaster.frame:Hide();
    _FishMaster.frame:SetToplevel(true);
    _FishMaster.frame:EnableMouse(true);
    _FishMaster.frame:SetMovable(true);
    ButtonFrameTemplate_HideButtonBar(_FishMaster.frame);
end

function FishMaster.equipment:OnShow()
    FishMaster.equipment:SetInfo()
end

function FishMaster.equipment:SetInfo()
    local sName, sRank, numTempPoints, sMaxRank, skillModifier, sDescription = FishMaster:GetProfessionInfo(PROFESSIONS_FISHING)
    if sName then
        _G[_FishMaster.frame:GetName()].RankFrame.RankLevel:SetText(sRank .. "/" .. tostring(sMaxRank))
        _G[_FishMaster.frame:GetName()].RankFrame:SetMinMaxValues(0, sMaxRank);
        _G[_FishMaster.frame:GetName()].RankFrame:SetValue(sRank);
    else
        _G[_FishMaster.frame:GetName()].RankFrame.RankLevel:SetText(0 .. "/" .. 300)
        _G[_FishMaster.frame:GetName()].RankFrame:SetMinMaxValues(0, 300);
        _G[_FishMaster.frame:GetName()].RankFrame:SetValue(0);
    end
end

function FishMaster.equipment:OnFrameLoad(self)
    local temp = PickupContainerItem;
    if (SafeHookFunction("PickupContainerItem", FM_PickupContainerItem)) then
        SavedPickupContainerItem = temp;
    end

    temp = PickupInventoryItem;
    if (SafeHookFunction("PickupInventoryItem", FM_PickupInventoryItem)) then
        SavedPickupInventoryItem = temp;
    end
end

function FishMaster.equipment:Open()
    _G[frameName].RankFrame.RankText:SetText(FishMaster:translate("fishing"))
    _G[frameName].RankFrame.RankLevel:SetText(FishMaster:GetProfessionLevel("fishing") .. "/" .. 300)
    _G[frameName].RankFrame:SetValue(FishMaster:GetProfessionLevel("fishing"));
    _G[frameName .. "Outfit"].AutoEquip.Text:SetText(FishMaster:translate("settings.autoLure"));

    FishMaster.equipment:SetInfo();

    SetPortraitTexture(_G[frameName .. "Portrait"], "player")
    _G[frameName .. "TitleText"]:SetText(_FishMaster.name);

    ShowUIPanel(_FishMaster.frame);
end

function FishMaster.equipment:Close()
    HideUIPanel(_FishMaster.frame);
end

function FishMaster.equipment:Toggle()
    if FishMaster.equipment:IsVisible() then
        FishMaster.equipment:Close()
    else
        FishMaster.equipment:Open()
    end
end

function FishMaster.equipment:IsVisible()
    return _FishMaster.frame:IsVisible();
end