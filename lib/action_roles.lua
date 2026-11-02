local descriptions = require('lib.descriptions')
local catalogue = require('data.catalogue')
local roles = require('data.generated.action_roles')
local names = require('lib.names')
local action_roles = {}
local by_name = {}
for id, entry in pairs(catalogue) do
    local key, role = names.normalize(entry.name), roles.moves[id]
    if role then
        if by_name[key] and by_name[key] ~= role then by_name[key] = 'unknown'
        else by_name[key] = role end
    end
end

function action_roles.lookup(event, overrides)
    if event.action == 'casts' or event.action == 'casting' or event.kind == 'spell' then
        return roles.spells[names.trim(event.move):lower()]
    end
    local entry = descriptions.lookup(event, overrides or {})
    -- Mixed damage/buff actions still threaten the player.
    if entry and entry.damage then return 'offensive' end
    if event.category == 11 and roles.moves[event.action_id] then return roles.moves[event.action_id] end
    local role = by_name[names.normalize(event.move)]
    if role and role ~= 'unknown' then return role end
end

return action_roles
