-- Run from the repository root with Lua 5.1 or later.
FishMaster = {}
LibStub = function()
    return { GetLocale = function() return {} end }
end
local ns = {}
C_Spell = { GetSpellName = function() return "Fishing" end }
assert(loadfile("scripts/api.lua"))("FishMaster", ns)
assert(loadfile("scripts/methods.lua"))("FishMaster", ns)

local function expectInfo(name, rank, temporary, maximum, modifier, description)
    local actualName, actualRank, actualTemporary, actualMaximum, actualModifier, actualDescription =
        FishMaster:GetProfessionInfo(name)
    assert(actualName == name)
    assert(actualRank == rank)
    assert(actualTemporary == temporary)
    assert(actualMaximum == maximum)
    assert(actualModifier == modifier)
    assert(actualDescription == description)
end

-- Modern client: fishing exists even without either primary profession.
PROFESSIONS_FISHING = "Fishing"
GetProfessions = function() return nil, nil, nil, 4, 5 end
GetProfessionInfo = function(index)
    if index == 4 then
        return "Fishing", 123, 125, 150, 1, 0, 356, 25
    end
    return "Cooking", 456, 50, 75, 1, 0, 185, 0
end
expectInfo("Fishing", 125, 0, 150, 25, nil)
assert(FishMaster:GetProfessionLevel("fishing") == 150)
expectInfo("Cooking", 50, 0, 75, 0, nil)

-- Localized names and fishing's stable skill-line ID both work.
PROFESSIONS_FISHING = "Angeln"
assert(FishMaster:GetProfessionLevel("Angeln") == 150)
GetProfessionInfo = function() return "Angeln", 123, 125, 150, 1, 0, 356, 25 end
expectInfo("Angeln", 125, 0, 150, 25, nil)
assert(FishMaster:GetProfessionLevel("fishing") == 150)

-- Unlearned professions and invalid requests are safe.
GetProfessions = function() return nil, nil, nil, nil, nil end
assert(FishMaster:GetProfessionInfo("Angeln") == nil)
assert(FishMaster:GetProfessionLevel("fishing") == 0)
assert(FishMaster:GetProfessionLevel(nil) == 0)

-- Legacy client: retain the existing six-value result and gear bonus.
GetProfessions = nil
GetProfessionInfo = nil
GetNumSkillLines = function() return 2 end
GetSkillLineInfo = function(index)
    if index == 1 then return nil end
    return "Angeln", false, true, 200, 5, 20, 225,
        true, 0, 0, 0, 0, "Fishing skill"
end
expectInfo("Angeln", 200, 5, 225, 20, "Fishing skill")
assert(FishMaster:GetProfessionLevel("fishing") == 220)
assert(FishMaster:GetProfessionLevel("Cooking") == 0)

-- A client with neither API must not call a missing function.
GetNumSkillLines = nil
GetSkillLineInfo = nil
assert(FishMaster:GetProfessionInfo("Angeln") == nil)
assert(FishMaster:GetProfessionLevel("fishing") == 0)
print("Profession compatibility checks passed")
