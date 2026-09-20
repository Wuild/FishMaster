local name, ns = ...
local API = ns.API

function FishMaster:MigrateSettings()
    local settings = self.db.char
    -- AceDB fills missing defaults; only move the old misplaced trash option.
    if settings.hideTrash ~= nil then
        settings.tracker.hideTrash = settings.hideTrash
        settings.hideTrash = nil
    end
    settings.schemaVersion = 2
    if settings.firstRun then
        settings.outfit.MainHandSlot = self:FindBestPole()
        settings.firstRun = false
    end
end

function FishMaster:GatherSlash(input)
    local command = (input or ""):match("^%s*(.-)%s*$"):lower()
    if command == "" or command == "toggle" then self:Toggle()
    elseif command == "config" or command == "configs" or command == "outfit" then self.equipment:Toggle()
    elseif command == "loot" then
        ShowUIPanel(self.equipment.frame)
        self.equipment:SelectTab(3)
    else self:Print(self:translate("commands.help")) end
end

function FishMaster:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("FishMasterSettings", ns.configsDefaults, true)
    ns.slots = API.AvailableSlots()
    self:MigrateSettings()
    self.minimap = LibStub("LibDBIcon-1.0")
    local broker = LibStub("LibDataBroker-1.1"):NewDataObject("FishMasterMinimapIcon", {
        type = "data source", text = "FishMaster", icon = ns.iconPath .. "Fishhook",
        OnClick = function(_, button)
            if button == "RightButton" then self.equipment:Toggle()
            else self:Toggle() end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("FishMaster |cff69ccf0Forever|r")
            tooltip:AddLine(self:translate("minimap.left_click_text"), 1, 1, 1)
            tooltip:AddLine(self:translate("minimap.right_click_text"), 1, 1, 1)
        end,
    })
    self.minimap:Register("FishMasterMinimapIcon", broker, self.db.profile.minimap)
    self.interaction:Create()
    self.equipment:Create()
    self.toolbar:Create()
    self.tracker:Create()
    self:RegisterChatCommand("fmaster", "GatherSlash")
    self:RegisterChatCommand("fishmaster", "GatherSlash")
end

function FishMaster:OnEnable()
    self:RegisterBucketEvent("BAG_UPDATE_DELAYED", .2, "Refresh")
    for _, event in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "SKILL_LINES_CHANGED", "PLAYER_ENTERING_WORLD",
        "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "GET_ITEM_INFO_RECEIVED" }) do
        self:RegisterEvent(event, "Refresh")
    end
    self:RegisterEvent("LOOT_READY", "OnLoot")
    self:RegisterEvent("LOOT_OPENED", "OnLoot")
    self:RegisterEvent("LOOT_SLOT_CHANGED", "OnLoot")
    self:RegisterEvent("LOOT_CLOSED", function()
        ns.lootRecorded, ns.lootPending = nil, false
        self.interaction:Refresh()
    end)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self.toolbar:ClearOverride()
        self:Refresh()
    end)
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() self.toolbar:ClearOverride() end)
    self:RegisterEvent("UNIT_SPELLCAST_START", "OnSpellStart")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "OnSpellStart")
    self:RegisterEvent("UNIT_SPELLCAST_STOP", "OnSpellStop")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "OnSpellStop")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnSpellStop")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnSpellStop")
    self:RegisterEvent("PLAYER_LOGOUT", function() self:UnsetAudio(); self.interaction:Clear() end)
    if not self:IsHooked(WorldFrame, "OnMouseDown") then
        self:SecureHookScript(WorldFrame, "OnMouseDown", function(...) self.toolbar:OnWorldMouseDown(...) end)
    end
    if not self:IsHooked(WorldFrame, "OnMouseUp") then
        self:SecureHookScript(WorldFrame, "OnMouseUp", function(...) self.toolbar:OnWorldMouseUp(...) end)
    end
    self.tick = self:ScheduleRepeatingTimer(function()
        self.toolbar:Tick()
        self:AdvanceOutfitSwap()
        if ns.lootPending then self:OnLoot() end
        self.interaction:Refresh()
    end, .1)
    self.lureTick = self:ScheduleRepeatingTimer(function() self.toolbar:Refresh() end, 1)
    self:SettingsChanged()
end

function FishMaster:OnDisable()
    self:CancelAllTimers()
    self:UnregisterAllEvents()
    self:UnregisterAllBuckets()
    self:UnhookAll()
    self.toolbar:ClearOverride()
    self.gearSwap = nil
    self:UnsetAudio()
    if not InCombatLockdown() then self.toolbar.frame:Hide() end
    self.tracker.frame:Hide()
    HideUIPanel(self.equipment.frame)
    self.interaction:Clear()
end
