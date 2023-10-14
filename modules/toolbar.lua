local name, _fish = ...;

local Toolbar = FishMaster.modules:NewModule("Toolbar")

local CastFrame
local frame
local lures = {}

local function SafeHookScript(frame, handlername, newscript)
    local oldValue = frame:GetScript(handlername);
    frame:SetScript(handlername, newscript);
    return oldValue;
end

function Toolbar:CreateFrame()
    frame = CreateFrame("Frame", "FishMaster_Toolbar", UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetClampedToScreen(true)
    frame:SetPoint("CENTER", 0, 0)
    frame:SetSize(400, 58)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:Hide()

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving();
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
    end)

    --frame.bg = frame:CreateTexture("$parentBg", "BACKGROUND", "ExtraPaperDollFrameBgTemplate", -6)

    frame.title = CreateFrame("Frame", nil, frame, "FMUIText")
    frame.title:SetPoint("TOPLEFT", 0, 0)
    frame.title:SetPoint("TOPRIGHT", 0, 0)
    frame.title.Text:SetFormattedText("%s", _fish.name)
end

function Toolbar:CreateCastButton()
    local cast = CreateFrame("Button", "$parentCast", frame, "FMUIItemTemplate")
    cast:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, 0)
    cast:SetSize(42, 42)
    cast:SetAttribute("type", "spell");
    cast:SetAttribute("spell", "Disenchant");
    cast.icon:SetTexture("Interface/Icons/inv_fishingpole_02")

    frame.cast = cast;
end

function Toolbar:UpdateCastButton()
    local frame = frame.cast
    local lured = FishMaster:IsLured();
    local lure = FishMaster:FindBestLure();
    local text = "";
    if not lured and lure then
        text = text .. "/use " .. GetSpellInfo(lure.spell) .. ";";
    else
        text = text .. "/cast " .. PROFESSIONS_FISHING
    end

    if FishMaster.isCasting then
        frame.icon:SetDesaturated(1);
    else
        frame.icon:SetDesaturated(nil);
    end

    frame:SetAttribute("type", "macro");
    frame:SetAttribute("macrotext", text);
    frame:SetAttribute("target-slot", INVSLOT_MAINHAND);
end

function Toolbar:CreateLureButtons()
    local lastButton = frame.cast

    for i, item in pairs(FishMaster.lures) do

        local lure = CreateFrame("Button", "$parentLure" .. i, frame, "FMUIItemTemplate")
        lure:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", 3, 0)
        lure:SetSize(32, 32)
        lure:SetAttribute("item", item.item)

        lure:SetScript("OnLoad", function()
            local _, link = GetItemInfo(item.item)
            lure.itemLink = link;
        end)

        lure:SetScript("OnEnter", function(self)
            GameTooltip:ClearLines();
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

            if not lure.itemLink then
                local _, link = GetItemInfo(item.item)
                lure.itemLink = link;
            end

            if lure and lure.itemLink then
                GameTooltip:SetHyperlink(lure.itemLink);
                GameTooltip:Show();
            end
        end)

        lure:SetScript("OnLeave", function()
            GameTooltip:ClearLines();
            GameTooltip:Hide();
        end)

        lure.icon:SetTexture(item.icon)

        lastButton = lure;

        table.insert(lures, lure)
    end
end

function Toolbar:UpdateLureButtons()
    for key, frame in pairs(lures) do
        local itemId = frame:GetAttribute("item")
        local lure = FishMaster:FindLure(tonumber(itemId));
        if itemId and lure then
            local count = GetItemCount(itemId);
            frame.count:SetText(count);
            frame.count:Show();
            securecall(function()
                if count > 0 then
                    frame:SetAlpha(1)
                    frame.icon:SetDesaturated(nil)
                    frame:SetAttribute("type", "macro");
                    frame:SetAttribute("macrotext", "/cast " .. GetSpellInfo(lure.spell));
                    frame:SetAttribute("target-slot", INVSLOT_MAINHAND);
                else
                    frame:SetAlpha(.4)
                    frame.icon:SetDesaturated(1)
                    frame:SetAttribute("macrotext", nil);
                end
            end)

        else
            frame:SetAlpha(.4)
            frame.icon:SetDesaturated(1)
            frame:SetAttribute("macrotext", nil);
        end
    end
end

function Toolbar:OnInitialize()
    self:CreateFrame()
    self:CreateCastButton()
    self:CreateLureButtons()
    self:RegisterEvent("VARIABLES_LOADED", "EventHandler");

    CastFrame = CreateFrame("Frame", nil)
    CastFrame:SetScript("OnUpdate", function()
        Toolbar:ResetOverride()
    end)
    CastFrame:Hide()
end

function Toolbar:OnEnable()
    frame:Show()

    self:RegisterEvent("UNIT_AURA", "EventHandler");
    self:RegisterEvent("BAG_UPDATE", "EventHandler");
    self:RegisterEvent("LOOT_OPENED", "EventHandler");
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "EventHandler");

    Toolbar:UpdateLureButtons()
    Toolbar:UpdateCastButton()
end

function Toolbar:OnDisable()
    frame:Hide()

    self:UnregisterEvent("UNIT_AURA");
    self:UnregisterEvent("BAG_UPDATE");
    self:UnregisterEvent("LOOT_OPENED");
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED");
end

function Toolbar:EventHandler(event, target, ...)

    if event == "VARIABLES_LOADED" then
        if (WorldFrame.OnMouseDown) then
            hooksecurefunc(WorldFrame, "OnMouseDown", Toolbar.OnMouseDown)
        else
            SavedWFOnMouseDown = SafeHookScript(WorldFrame, "OnMouseDown", Toolbar.OnMouseDown);
        end
    end

    Toolbar:UpdateLureButtons()
    Toolbar:UpdateCastButton()
end

function Toolbar:CheckForDoubleClick(button)
    if (button and button ~= "RightButton") then
        return false;
    end
    if (not LootFrame:IsShown() and self.lastClickTime) then
        local pressTime = GetTime();
        local doubleTime = pressTime - self.lastClickTime;
        if ((doubleTime < 0.4) and (doubleTime > 0.05)) then
            self.lastClickTime = nil;
            return true;
        end
    end
    self.lastClickTime = GetTime();
    return false;
end

function Toolbar:OnMouseDown(...)
    -- Only steal 'right clicks' (self is arg #1!)
    local button = select(2, ...);
    if (FishMaster.db.char.easyCast and not FishMaster:IsInCombat() and FishMaster:IsPoleEquipped()) then
        if (Toolbar:CheckForDoubleClick(button)) then
            -- We're stealing the mouse-up event, make sure we exit MouseLook
            if (IsMouselooking()) then
                MouselookStop();
            end
            Toolbar:SetOverride()
        end
        if (SavedWFOnMouseDown) then
            SavedWFOnMouseDown(...);
        end
    end
end

function Toolbar:SetOverride()
    local button = frame.cast;
    button:SetScript("PostClick", function()
        CastFrame:Show();
    end);
    SetOverrideBindingClick(button, true, "BUTTON2", button:GetName());
end

function Toolbar:ResetOverride()
    local button = frame.cast;
    button:SetScript("PostClick", nil);
    ClearOverrideBindings(frame.cast);
    CastFrame:Hide();
end