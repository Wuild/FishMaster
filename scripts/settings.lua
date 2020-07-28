local name = ...;
LibStub("AceConfig-3.0"):RegisterOptionsTable(name, {
    type = "group",
    childGroups = "tab",
    args = {
        general = {
            name = function()
                return FishMaster:translate("settings.general");
            end,
            type = "group",
            order = 1,
            args = {
                autoLure = {
                    name = function()
                        return FishMaster:translate("settings.autoLure");
                    end,
                    type = "toggle",
                    order = 4,
                    width = "full",
                    set = function(info, val)
                        FishMaster.db.char.autoLure = val;
                    end,
                    get = function(info)
                        return FishMaster.db.char.autoLure
                    end
                },
            }
        }
    }
})

LibStub("AceConfigDialog-3.0"):AddToBlizOptions(name, name);
