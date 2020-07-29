local name, _FishMaster = ...;
LibStub("AceConfig-3.0"):RegisterOptionsTable(name, {
    type = "group",
    childGroups = "tab",
    args = {
        general = _FishMaster.settings.general
    }
})

LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name, name);
