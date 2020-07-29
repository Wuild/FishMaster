local name, _FishMaster = ...;

_FishMaster.settings.audio = {
    name = function()
        return "Sound";
    end,
    type = "group",
    order = 1,
    args = {
        override = {
            name = "Override audio",
            type = "toggle",
            order = 1,

            set = function(info, val)
                FishMaster.db.char.audio.enabled = val;
            end,
            get = function(info)
                return FishMaster.db.char.audio.enabled
            end,
            width = "full",
        },

        effects = {
            name = "Sound effects",
            type = "toggle",
            order = 2,

            set = function(info, val)
                FishMaster.db.char.audio.effects = val;
            end,
            get = function(info)
                return FishMaster.db.char.audio.effects
            end,
            width = "normal",
        },

        music = {
            name = "Music",
            type = "toggle",
            order = 3,

            set = function(info, val)
                FishMaster.db.char.audio.music = val;
            end,
            get = function(info)
                return FishMaster.db.char.audio.music
            end,
            width = "normal",
        },

        ambient = {
            name = "Ambient Sounds",
            type = "toggle",
            order = 4,

            set = function(info, val)
                FishMaster.db.char.audio.ambient = val;
            end,
            get = function(info)
                return FishMaster.db.char.audio.ambient
            end,
            width = "normal",
        },

        dialog = {
            name = "Dialog",
            type = "toggle",
            order = 5,

            set = function(info, val)
                FishMaster.db.char.audio.ambient = val;
            end,
            get = function(info)
                return FishMaster.db.char.audio.ambient
            end,
            width = "normal",
        },

        volumes = {
            type = "group",
            name = "Audio",
            inline = true,
            order = 6,
            width = "half",
            args = {
                masterVolume = {
                    name = function()
                        return "Master volume";
                    end,
                    type = "range",
                    min = 0,
                    max = 1,
                    step = .01,
                    order = 1,
                    width = "normal",
                    isPercent = true,
                    set = function(info, val)
                        FishMaster.db.char.audio.masterVolume = val;
                    end,
                    get = function(info)
                        return FishMaster.db.char.audio.masterVolume
                    end
                },

                sound = {
                    name = function()
                        return "Sound";
                    end,
                    type = "range",
                    min = 0,
                    max = 1,
                    step = .01,
                    order = 2,
                    isPercent = true,
                    set = function(info, val)
                        FishMaster.db.char.audio.sound = val;
                    end,
                    get = function(info)
                        return FishMaster.db.char.audio.sound
                    end
                },

                music = {
                    name = function()
                        return "Music";
                    end,
                    type = "range",
                    min = 0,
                    max = 1,
                    step = .01,
                    order = 3,
                    isPercent = true,
                    set = function(info, val)
                        FishMaster.db.char.audio.music = val;
                    end,
                    get = function(info)
                        return FishMaster.db.char.audio.music
                    end
                },

                ambience = {
                    name = function()
                        return "Ambience";
                    end,
                    type = "range",
                    min = 0,
                    max = 1,
                    step = .01,
                    order = 4,
                    isPercent = true,
                    set = function(info, val)
                        FishMaster.db.char.audio.ambience = val;
                    end,
                    get = function(info)
                        return FishMaster.db.char.audio.ambience
                    end
                },

                Dialog = {
                    name = function()
                        return "Dialog";
                    end,
                    type = "range",
                    min = 0,
                    max = 1,
                    step = .01,
                    order = 5,
                    isPercent = true,
                    set = function(info, val)
                        FishMaster.db.char.audio.dialog = val;
                    end,
                    get = function(info)
                        return FishMaster.db.char.audio.dialog
                    end
                },
            }
        }
    }
}