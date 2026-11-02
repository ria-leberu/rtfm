-- Reviewed additions missing from the imported mob_pools table.
-- King Behemoth is explicitly identified as an HNM in this pinned zone script:
-- https://github.com/LandSandBoat/server/blob/858bd9d7cb1d4b8a57db9be132282e7505a5bea4/scripts/zones/Behemoths_Dominion/mobs/King_Behemoth.lua
-- Its base TP list is upstream mob_skill_lists ID 479.
return {
    { name = 'King Behemoth', aliases = { 'King Behemoth' }, skill_list_id = 479, spells = { 218 } },
    -- Explicit HNM identification; move list 329. Scripts can add further SP abilities.
    -- https://github.com/LandSandBoat/server/blob/858bd9d7cb1d4b8a57db9be132282e7505a5bea4/scripts/zones/AlTaieu/mobs/Absolute_Virtue.lua
    { name = 'Absolute Virtue', aliases = { 'Absolute Virtue' }, skill_list_id = 329 },
}
