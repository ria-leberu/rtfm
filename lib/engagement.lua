local names = require('lib.names')
local engagement = {}

-- Client-side approximation: party/alliance claim, current combat target, or
-- recipients of this result packet. The server's full enmity list is unavailable.
function engagement.matches(event, entities, party)
    local party_ids, party_indexes, claim_ids = {}, {}, {}
    local function add(index, id)
        if index and index > 0 then party_indexes[index] = true end
        if id and id > 0 then
            party_ids[id] = true
            claim_ids[id % 65536] = true
        end
    end
    for i = 0, 17 do
        if i == 0 or party:GetMemberIsActive(i) == 1 then
            local index = party:GetMemberTargetIndex(i)
            add(index, party:GetMemberServerId(i))
            if index and index > 0 then
                local pet = entities:GetPetTargetIndex(index)
                if pet and pet > 0 then add(pet, entities:GetServerId(pet)) end
            end
        end
    end
    for _, id in ipairs(event.target_ids or {}) do
        if party_ids[id] then return true end
    end
    for i = 0, 2303 do
        local matches
        if event.actor_id then matches = entities:GetServerId(i) == event.actor_id
        else matches = names.normalize(entities:GetName(i)) == names.normalize(event.monster) end
        if matches and bit.band(entities:GetSpawnFlags(i), 0x10) ~= 0 then
            local claim = entities:GetClaimStatus(i) % 65536
            if claim ~= 0 and claim_ids[claim] then return true end
            if entities:GetStatus(i) == 1 and party_indexes[entities:GetTargetedIndex(i)] then return true end
            if event.actor_id then return false end
        end
    end
    return false
end

return engagement
