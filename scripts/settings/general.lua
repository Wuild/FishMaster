local name, _FishMaster = ...;


_FishMaster.settings.general = {
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
            order = 1,
            width = "full",
            set = function(info, val)
                FishMaster.db.char.autoLure = val;
            end,
            get = function(info)
                return FishMaster.db.char.autoLure
            end
        },
        Spacer_1 = {
            type = "description",
            order = 2,
            name = " ",
            fontSize = "large",
        }
    }
};