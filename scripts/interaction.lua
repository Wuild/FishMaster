local _, ns = ...
local Interaction = {}
FishMaster.interaction = Interaction

function Interaction:Create()
    self.owner = CreateFrame("Button", "FishMasterInteractBinding", UIParent, "SecureActionButtonTemplate")
    self.owner:RegisterForClicks("AnyDown", "AnyUp")
    -- Cast on key down: returning from Interact to Cast must not recast on the
    -- release of the same key press that just collected the bobber.
    self.owner:SetAttribute("useOnKeyDown", true)
    self.owner:SetScript("PostClick", function(_, _, down)
        if not down then return end
        FishMaster:ScheduleTimer(function()
            FishMaster.toolbar:Refresh()
            self:Refresh()
        end, .15)
    end)
end

function Interaction:RestoreAccessibility()
    local saved = FishMaster.db.char.interactPrevious
    if saved ~= nil then
        -- Preserve a setting the player changed themselves while fishing.
        if C_CVar.GetCVar("softTargetInteract") == "3" then
            C_CVar.SetCVar("softTargetInteract", saved)
        end
        FishMaster.db.char.interactPrevious = nil
    end
end

function Interaction:Refresh()
    if InCombatLockdown() then return end
    local key = FishMaster.db.char.bobberKey
    local cast = FishMaster.toolbar.cast
    if not FishMaster:IsPoleEquipped() or key == "" or self.suspended or not cast then key = nil end
    local action
    if key then
        local fishing = ns.API.FishingName()
        local interacting = UnitChannelInfo("player") == fishing or UnitCastingInfo("player") == fishing
            or (LootFrame and LootFrame:IsShown())
        action = interacting and "interact" or "cast"
        if action == "cast" then
            -- Share the toolbar's current spell/lure selection, but keep a
            -- separate secure button and binding owner from double-right-click.
            for _, attribute in ipairs({ "type", "spell", "item", "target-slot" }) do
                self.owner:SetAttribute(attribute, cast:GetAttribute(attribute .. "1"))
            end
        end
    end
    if self.activeKey ~= key or self.activeAction ~= action then
        ClearOverrideBindings(self.owner)
        if action == "interact" then
            SetOverrideBinding(self.owner, true, key, "INTERACTTARGET")
        elseif action == "cast" then
            SetOverrideBindingClick(self.owner, true, key, self.owner:GetName(), "LeftButton")
        end
        self.activeKey, self.activeAction = key, action
    end
    if key then
        if FishMaster.db.char.interactPrevious == nil then
            FishMaster.db.char.interactPrevious = C_CVar.GetCVar("softTargetInteract")
            C_CVar.SetCVar("softTargetInteract", "3")
        end
    else
        self:RestoreAccessibility()
    end
end

function Interaction:Clear()
    if not InCombatLockdown() then
        ClearOverrideBindings(self.owner)
        self.activeKey = nil
        self.activeAction = nil
    end
    self:RestoreAccessibility()
end

function Interaction:SetKey(key)
    if FishMaster:CheckCombat() then return end
    FishMaster.db.char.bobberKey = key or ""
    self:Refresh()
end

function Interaction:KeyLabel()
    local key = FishMaster.db.char.bobberKey
    return key ~= "" and GetBindingText(key, "KEY_") or FishMaster:translate("settings.bindKey")
end
