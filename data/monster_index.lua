local names = require('lib.names')
local index = {}
for name, moves in pairs(require('data.generated.monsters')) do index[name] = moves end
local reviewed_moves = require('data.notorious_moves')
for _, addition in ipairs(require('data.notorious_additions')) do
    local moves = reviewed_moves(addition)
    for _, alias in ipairs(addition.aliases) do
        local key, combined, seen = names.normalize(alias), {}, {}
        for _, list in ipairs({ not addition.replace_moves and index[names.normalize(alias)] or {}, moves }) do
            for _, id in ipairs(list) do
                if not seen[id] then combined[#combined + 1], seen[id] = id, true end
            end
        end
        table.sort(combined)
        index[key] = combined
    end
end
return index
