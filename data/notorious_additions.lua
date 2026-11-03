-- Reviewed additions missing from the imported mob_pools table.
-- King Behemoth is explicitly identified as an HNM in this pinned zone script:
-- https://github.com/LandSandBoat/server/blob/858bd9d7cb1d4b8a57db9be132282e7505a5bea4/scripts/zones/Behemoths_Dominion/mobs/King_Behemoth.lua
-- Its base TP list is upstream mob_skill_lists ID 479.
local additions = {
    { name = 'King Behemoth', aliases = { 'King Behemoth' }, skill_list_id = 479, spells = { 218 } },
    -- Explicit HNM identification; move list 329. Scripts can add further SP abilities.
    -- https://github.com/LandSandBoat/server/blob/858bd9d7cb1d4b8a57db9be132282e7505a5bea4/scripts/zones/AlTaieu/mobs/Absolute_Virtue.lua
    { name = 'Absolute Virtue', aliases = { 'Absolute Virtue' }, skill_list_id = 329 },
    -- Proto-Omega's phase lists come from the pinned mob_skill_lists.sql.
    -- Pod Ejection and Discharger are separate scripted abilities in client resources.
    -- Neo-Omega shares this moveset per the local server's requested catalogue mapping.
    { name = 'Proto-Omega', aliases = { 'Proto-Omega' }, skill_list_ids = { 727, 1188, 1189 },
        extra_moves = { 1532, 1537 } },
    { name = 'Neo-Omega', aliases = { 'Neo-Omega' }, skill_list_ids = { 727, 1188, 1189 },
        extra_moves = { 1532, 1537 } },
}
for _, monster in ipairs(require('data.domain_invasion').monsters) do
    additions[#additions + 1] = monster
end
for _, monster in ipairs(require('data.dragonslaying').monsters) do
    additions[#additions + 1] = monster
end
return additions
