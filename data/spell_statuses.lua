local statuses = require('data.generated.spell_statuses')
-- Enemy-only variants omitted from the client resource's status field.
local variants = {
    diaga = 134, blindga = 5, poisonga = 3, paralyga = 4,
    slowga = 13, silencega = 6, bindga = 11, gravitga = 12,
}
for name, id in pairs(variants) do
    for _, suffix in ipairs({ '', ' ii', ' iii', ' iv', ' v' }) do
        statuses[name .. suffix] = statuses[name .. suffix] or { id }
    end
end
return statuses
