local vanilla = {
    {
        item = 6529, -- Shiny Bauble
        spell = 8087,
        skill = 1,
        bonus = 25,
        icon = "Interface\\Icons\\inv_misc_orb_03"
    },
    {
        item = 6530, -- Nightcrawlers
        spell = 8088,
        skill = 50,
        bonus = 50,
        icon = "Interface\\Icons\\inv_misc_monstertail_03"
    },
    {
        item = 6811, -- Aquadynamic Fish Lens
        spell = 8532,
        skill = 50,
        bonus = 50,
        icon = "Interface\\Icons\\inv_misc_spyglass_01"
    },
    {
        item = 6532, -- Bright Baubles
        spell = 8090,
        skill = 100,
        bonus = 75,
        icon = "Interface\\Icons\\inv_misc_gem_variety_02"
    },
    {
        item = 6533, -- Aquadynamic Fish Attractor
        spell = 9271,
        skill = 100,
        bonus = 100,
        icon = "Interface\\Icons\\inv_misc_food_26"
    }
}

for _, v in ipairs(vanilla) do
    table.insert(FishMaster.lures, v)
end
