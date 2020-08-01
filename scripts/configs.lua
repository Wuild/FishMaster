local name, _FishMaster = ...;
local CallbackHandler = LibStub("CallbackHandler-1.0")

FishMaster = LibStub("AceAddon-3.0"):NewAddon("FishMaster", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0", "AceSerializer-3.0", "FishEvents-1.0")

_FishMaster.name = name;
_FishMaster.version = GetAddOnMetadata(name, "version");

_FishMaster.iconPath = "Interface\\AddOns\\" .. _FishMaster.name .. "\\images\\"

_FishMaster.equipped = false;
_FishMaster.lured = false;
_FishMaster.settings = {};

_FishMaster.poles = {
    19970, -- Arcanite Fishing Pole
    19022, -- Nat Pagle’s Extreme Angler FC-5000
    6367, -- Big Iron Fishing Pole
    6365, -- Strong Fishing Pole
    12225, -- Blump Family Fishing Pole
    6256, -- Fishing Pole
}

_FishMaster.lures = {

    {
        item = 6533, -- Aquadynamic Fish Attractor
        spell = 9271,
        skill = 100,
        bonus = 100,
        icon = "Interface\\Icons\\inv_misc_food_26"
    },

    {
        item = 7307, -- Flesh Eating Worm
        spell = 9092,
        skill = 100,
        bonus = 75,
        icon = "Interface\\Icons\\inv_misc_monstertail_03"
    },

    {
        item = 6532, -- Bright Baubles
        spell = 8090,
        skill = 100,
        bonus = 75,
        icon = "Interface\\Icons\\inv_misc_gem_variety_02"
    },

    {
        item = 6811, -- Aquadynamic Fish Lens
        spell = 8532,
        skill = 50,
        bonus = 50,
        icon = "Interface\\Icons\\inv_misc_spyglass_01"
    },

    {
        item = 6530, -- Nightcrawlers
        spell = 8088,
        skill = 50,
        bonus = 50,
        icon = "Interface\\Icons\\inv_misc_monstertail_03"
    },

    {
        item = 6529, -- Shiny Bauble
        spell = 8087,
        skill = 1,
        bonus = 25,
        icon = "Interface\\Icons\\inv_misc_orb_03"
    },
}

_FishMaster.configsDefaults = {
    global = {},
    char = {
        firstRun = true,
        enabled = false,
        autoLure = true,
        lowestLure = true,
        autoEquip = true,
        easyCast = false,
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

    }
}