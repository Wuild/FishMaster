local name, _fish = ...;

local vanilla = {
    6256, -- Fishing Pole
    6365, -- Strong Fishing Pole
    6366, -- Darkwood Fishing Pole
    6367, -- Big Iron Fishing Pole

    19022, -- Nat Pagle’s Extreme Angler FC-5000
    45858, -- Nat's Lucky Fishing Pole
}

local wrath = {
    44050, -- Mastercraft Kalu'ak Fishing Pole
    45992, -- Jeweled Fishing Pole
    45991, -- Bone Fishing Pole
}

for _, v in ipairs(vanilla) do
    table.insert(FishMaster.poles, v)
end

if _fish.isWrath then
    for _, v in ipairs(wrath) do
        table.insert(FishMaster.poles, v)
    end
end