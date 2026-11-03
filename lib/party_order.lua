local names = require('lib.names')
local order = {}

function order.snapshot(party)
    local members = {}
    for slot = 0, 17 do
        if slot == 0 or party:GetMemberIsActive(slot) == 1 then
            local name = party:GetMemberName(slot)
            if type(name) == 'string' and names.trim(name) ~= '' then
                members[name:lower()] = { party = math.floor(slot / 6) + 1, slot = slot % 6 }
            end
        end
    end
    return next(members) and members or nil
end

return order
