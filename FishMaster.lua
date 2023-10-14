local name, _fish = ...;

_fish.name = name;
_fish.version = GetAddOnMetadata(name, "version");

_fish.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
_fish.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
_fish.isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

_fish.iconPath = "Interface\\AddOns\\" .. _fish.name .. "\\images\\"

FishMaster = LibStub("AceAddon-3.0"):NewAddon("FishMaster", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0", "AceSerializer-3.0")
FishMaster:SetDefaultModuleLibraries("AceEvent-3.0")
FishMaster:SetDefaultModuleState(false)

FishMaster.sessionLoot = {}

FishMaster.poles = {}
FishMaster.lures = {}

FishMaster.IsCasting = false

FishMaster.modules = FishMaster:NewModule("Modules")
FishMaster.modules:SetDefaultModuleLibraries("AceEvent-3.0")
FishMaster.modules:SetDefaultModuleState(false)

FishMaster.IsEnabled = false

_fish.configsDefaults = {

    global = {
        debug = false
    },
    char = {
        firstRun = true,
        enabled = false,
        autoLure = true,
        lowestLure = true,
        autoEquip = true,
        easyCast = true,
        outfit = {},
        storedOutfit = {},
        point = {
            p = "CENTER",
            rf = "UIParent",
            rp = "CENTER",
            x = 0,
            y = 0,
        },
        tracker = {
            enabled = true,
            hideTrash = true,
            session = true
        },
        audio = {
            enabled = false,
            force = false,
            volume = 1,
        },
        loot = {},
        defaultAudio = {
            Sound_EnableAllSound = nil,
            Sound_EnableSFX = nil,
            Sound_MasterVolume = nil,
            Sound_SFXVolume = nil
        }
    },
    profile = {
        minimap = {
            hide = false
        }
    }
}

local minimapIcon = LibStub("LibDataBroker-1.1"):NewDataObject("FishMasterMinimapIcon", {
    type = "data source",
    text = _fish.name,
    icon = _fish.iconPath .. "Fishhook",

    OnClick = function(self, button)
        if button == "LeftButton" then
            FishMaster:Toggle();
        elseif button == "RightButton" then
            FishMaster.equipment:Toggle()
            --InterfaceOptionsFrame_OpenToCategory(name)
            --InterfaceOptionsFrame_OpenToCategory(name) -- run it again to set the correct tab
        end
    end,

    OnTooltipShow = function(tooltip)
        tooltip:SetText(_fish.name .. " |cFF00FF00" .. _fish.version .. "|r");
        tooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.left_click"), 'gray') .. ": " .. FishMaster:translate("minimap.left_click_text"));
        tooltip:AddLine(FishMaster:Colorize(FishMaster:translate("minimap.right_click"), 'gray') .. ": " .. FishMaster:translate("minimap.right_click_text"));
    end,
});

function FishMaster:print(...)
    print(FishMaster:Colorize("<" .. name .. ">", "cyan"), ...)
end

function FishMaster:debug(...)
    --if (FishMaster.db.global.debug.enabled) then
    print(FishMaster:Colorize("<" .. name .. " - Debug>", "blue"), ...)
    --end
end

function FishMaster:Colorize(str, color)
    local c = '';
    if color == 'red' then
        c = '|cffff0000';
    elseif color == 'gray' then
        c = '|cFFCFCFCF';
    elseif color == 'purple' then
        c = '|cFFB900FF';
    elseif color == 'blue' then
        c = '|cB900FFFF';
    elseif color == 'yellow' then
        c = '|cFFFFB900';
    elseif color == 'green' then
        c = "|cFF00FF00";
    elseif color == 'white' then
        c = "|cffffffff"
    elseif color == 'cyan' then
        c = "|cff00FFFF"
    end
    return c .. str .. "|r"
end

function FishMaster:SlashCommand(input)
    input = string.trim(input, " ");

    if input == "reset" then
        FishMaster.db.char.loot = {}
        FishMaster.sessionLoot = {}

        FishMaster:SendMessage("FISHMASTER_RESET")
    end

end

function FishMaster:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("FishMasterSettings", _fish.configsDefaults, true)

    self.minimap = LibStub("LibDBIcon-1.0")
    FishMaster.minimap:Register("FishMasterMinimapIcon", minimapIcon, self.db.profile.minimap)

end

function FishMaster:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "EventHandler")
    self:RegisterEvent("PLAYER_LEAVING_WORLD", "EventHandler")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "EventHandler")
    self:RegisterEvent("VARIABLES_LOADED", "EventHandler")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "EventHandler")
    self:RegisterEvent("UNIT_SPELLCAST_START", "EventHandler")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "EventHandler")
    self:RegisterEvent("UNIT_SPELLCAST_STOP", "EventHandler")
    self:RegisterEvent("LOOT_READY", "EventHandler")
    self:RegisterEvent("LOOT_OPENED", "EventHandler")
    self:RegisterEvent("LOOT_CLOSED", "EventHandler")

    self:RegisterChatCommand("fm", "SlashCommand")
end

local looted = false;

function FishMaster:EventHandler(event, target, ...)

    if FishMaster.IsEnabled then
        if event == "UNIT_SPELL_CAST_CHANNEL_START" then
            FishMaster.IsCasting = true
        end

        if event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            FishMaster.IsCasting = false
        end

        if event == "LOOT_READY" then
            if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
                if IsFishingLoot() and not looted then
                    looted = true
                    FishMaster:AddLoot()
                    FishMaster:SendMessage("FISHMASTER_LOOT_ADDED")
                end
            end
        end

        if event == "LOOT_CLOSED" then
            looted = false
        end
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if self:IsPoleEquipped() then
            self:Enable()
        end
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        if self:IsPoleEquipped() then
            self:Enable()
        else
            if self.IsEnabled then
                self:Disable()
            end
        end
    end
end

function FishMaster:Enable()
    if not FishMaster.IsEnabled then
        FishMaster.IsEnabled = true
        for name, module in self.modules:IterateModules() do
            module:Enable()
        end

        FishMaster:SetAudio(true)
    end
end

function FishMaster:Disable()
    if FishMaster.IsEnabled then
        FishMaster.IsEnabled = false
        for name, module in self.modules:IterateModules() do
            module:Disable()
        end

        FishMaster:UnsetAudio()
    end
end