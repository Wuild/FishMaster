-- Load each locale independently; fallback must not conceal missing strings.
local current
LibStub = function()
    return { NewLocale = function() return current end }
end
local function loadLocale(locale)
    current = {}
    assert(loadfile("locales/" .. locale .. ".lua"))("FishMaster", { name = "FishMaster" })
    return current
end
local function formats(value)
    local result = {}
    for token in value:gsub("%%%%", ""):gmatch("%%([ds])") do
        table.insert(result, token)
    end
    return table.concat(result)
end
local base = loadLocale("enUS")
for _, locale in ipairs({ "deDE", "frFR", "esES", "itIT", "ruRU", "zhCN" }) do
    local translated = loadLocale(locale)
    for key, value in pairs(base) do
        assert(type(translated[key]) == "string" and #translated[key] > 0, locale .. ": missing " .. key)
        assert(formats(value) == formats(translated[key]), locale .. ": format mismatch " .. key)
    end
    for key in pairs(translated) do assert(base[key], locale .. ": obsolete key " .. key) end
    print("PASS complete locale and format placeholders: " .. locale)
end
